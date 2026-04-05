import 'package:dio/dio.dart';

import '../../dto/anilibria/anilibria_episode_dto.dart';
import '../../dto/anilibria/anilibria_release_dto.dart';
import 'anilibria_remote_data_source.dart';

class DioAnilibriaRemoteDataSource implements AnilibriaRemoteDataSource {
  DioAnilibriaRemoteDataSource({required Dio dio}) : _dio = dio;

  static const apiBaseUrl = 'https://api.anilibria.tv/v3/';
  static const _seriesFilter =
      'id,code,names,description,genres,posters,updated,season,status';
  static const _episodesFilter = 'id,player.list';

  final Dio _dio;

  @override
  Future<List<AnilibriaReleaseDto>> fetchFeaturedReleases({
    int limit = 20,
  }) async {
    final payload = await _getJson(
      'title/updates',
      queryParameters: {..._defaultQueryParameters(limit: limit)},
    );

    return _parseReleaseList(payload);
  }

  @override
  Future<List<AnilibriaReleaseDto>> fetchTrendingReleases({
    int limit = 20,
  }) async {
    final payload = await _getJson(
      'title/changes',
      queryParameters: {..._defaultQueryParameters(limit: limit)},
    );

    return _parseReleaseList(payload);
  }

  @override
  Future<List<AnilibriaReleaseDto>> fetchPopularReleases({
    int limit = 20,
  }) async {
    final payload = await _getJson(
      'title/search/advanced',
      queryParameters: {
        ..._defaultQueryParameters(limit: limit),
        'simple_query': 'status.code==1',
        'order_by': 'in_favorites',
        'sort_direction': 1,
      },
    );

    return _parseReleaseList(payload);
  }

  @override
  Future<AnilibriaReleaseDto> fetchReleaseDetails(String releaseId) async {
    final payload = await _getJson(
      'title',
      queryParameters: {
        'id': releaseId,
        'filter': '$_seriesFilter,player.list',
        'playlist_type': 'array',
      },
    );

    return _parseRelease(_extractObject(payload));
  }

  @override
  Future<List<AnilibriaEpisodeDto>> fetchReleaseEpisodes(
    String releaseId,
  ) async {
    final payload = await _getJson(
      'title',
      queryParameters: {
        'id': releaseId,
        'filter': _episodesFilter,
        'playlist_type': 'array',
      },
    );

    return _parseRelease(_extractObject(payload)).episodes;
  }

  @override
  Future<List<AnilibriaReleaseDto>> searchReleases(
    String query, {
    int limit = 20,
  }) async {
    final payload = await _getJson(
      'title/search',
      queryParameters: {
        ..._defaultQueryParameters(limit: limit),
        'search': query,
      },
    );

    return _parseReleaseList(payload);
  }

  @override
  Future<List<AnilibriaReleaseDto>> fetchSimulcastReleases({
    int limit = 20,
  }) async {
    final payload = await _getJson(
      'title/search/advanced',
      queryParameters: {
        ..._defaultQueryParameters(limit: limit),
        'simple_query': 'status.code==1',
        'order_by': 'updated',
        'sort_direction': 1,
      },
    );

    return _parseReleaseList(payload);
  }

  Future<dynamic> _getJson(
    String path, {
    Map<String, Object?>? queryParameters,
  }) async {
    final response = await _dio.get<dynamic>(
      path,
      queryParameters: queryParameters,
      options: Options(responseType: ResponseType.json),
    );

    return response.data;
  }

  Map<String, Object?> _defaultQueryParameters({required int limit}) {
    return {'filter': _seriesFilter, 'limit': limit};
  }

  List<AnilibriaReleaseDto> _parseReleaseList(dynamic payload) {
    final rawList = _extractList(payload);
    return rawList.map(_parseRelease).toList(growable: false);
  }

  AnilibriaReleaseDto _parseRelease(Map<String, dynamic> json) {
    final releaseId = _readString(json['id']);
    final namesJson = _readMap(json['names']);
    final seasonJson = _readMap(json['season']);
    final statusJson = _readMap(json['status']);

    if (releaseId == null || releaseId.isEmpty) {
      throw const FormatException('AniLibria release is missing an id.');
    }

    return AnilibriaReleaseDto(
      id: releaseId,
      code: _readString(json['code']),
      names: AnilibriaNamesDto(
        main: _readString(namesJson?['ru']) ?? _readString(namesJson?['main']),
        english:
            _readString(namesJson?['en']) ?? _readString(namesJson?['english']),
        alternative: _readStringList(namesJson?['alternative']),
      ),
      description: _readString(json['description']),
      genres: _readStringList(json['genres']),
      images: AnilibriaImageSetDto(
        posterUrl: _extractPosterUrl(json),
        bannerUrl: _extractBannerUrl(json),
      ),
      releaseYear:
          _readInt(json['releaseYear']) ??
          _readInt(json['release_year']) ??
          _readInt(seasonJson?['year']),
      updatedAt:
          _readDateTime(json['updatedAt']) ??
          _readDateTime(json['updated']) ??
          _readDateTime(json['last_change']),
      episodes: _parseEpisodes(json, releaseId: releaseId),
      raw: {
        ...Map<String, Object?>.from(json),
        ...?statusJson == null ? null : {'status': statusJson},
      },
    );
  }

  List<AnilibriaEpisodeDto> _parseEpisodes(
    Map<String, dynamic> releaseJson, {
    required String releaseId,
  }) {
    final episodesJson = releaseJson['episodes'];
    if (episodesJson is List) {
      return episodesJson
          .map((entry) => _parseEpisode(entry, releaseId: releaseId))
          .whereType<AnilibriaEpisodeDto>()
          .toList(growable: false);
    }

    final playerJson = _readMap(releaseJson['player']);
    final playerList = playerJson?['list'];

    if (playerList is List) {
      return playerList
          .map((entry) => _parseEpisode(entry, releaseId: releaseId))
          .whereType<AnilibriaEpisodeDto>()
          .toList(growable: false);
    }

    if (playerList is Map) {
      return playerList.entries
          .map(
            (entry) => _parseEpisode(
              entry.value,
              releaseId: releaseId,
              fallbackOrdinal: _readInt(entry.key),
            ),
          )
          .whereType<AnilibriaEpisodeDto>()
          .toList(growable: false);
    }

    return const [];
  }

  AnilibriaEpisodeDto? _parseEpisode(
    dynamic payload, {
    required String releaseId,
    int? fallbackOrdinal,
  }) {
    final json = _readMap(payload);
    if (json == null) {
      return null;
    }

    final ordinal =
        _readInt(json['episode']) ??
        _readInt(json['ordinal']) ??
        fallbackOrdinal;
    if (ordinal == null) {
      return null;
    }

    return AnilibriaEpisodeDto(
      id:
          _readString(json['uuid']) ??
          _readString(json['id']) ??
          '$releaseId-$ordinal',
      releaseId: _readString(json['releaseId']) ?? releaseId,
      ordinal: ordinal,
      title: _readString(json['name']) ?? _readString(json['title']),
      description: _readString(json['description']),
      durationSeconds:
          _readInt(json['duration']) ?? _readInt(json['duration_seconds']),
      thumbnailUrl:
          _readString(json['preview']) ?? _readString(json['thumbnail']),
      airedAt:
          _readDateTime(json['airedAt']) ??
          _readDateTime(json['aired_at']) ??
          _readDateTime(json['created_timestamp']),
      isFiller:
          _readBool(json['is_filler']) ?? _readBool(json['isFiller']) ?? false,
      isRecap:
          _readBool(json['is_recap']) ?? _readBool(json['isRecap']) ?? false,
      raw: Map<String, Object?>.from(json),
    );
  }

  String? _extractPosterUrl(Map<String, dynamic> json) {
    final imagesJson = _readMap(json['images']);
    if (imagesJson != null) {
      return _readString(imagesJson['posterUrl']) ??
          _readString(imagesJson['poster_url']);
    }

    final postersJson = _readMap(json['posters']);
    if (postersJson == null) {
      return null;
    }

    return _readString(_readMap(postersJson['medium'])?['url']) ??
        _readString(_readMap(postersJson['small'])?['url']) ??
        _readString(_readMap(postersJson['original'])?['url']);
  }

  String? _extractBannerUrl(Map<String, dynamic> json) {
    final imagesJson = _readMap(json['images']);
    if (imagesJson == null) {
      return null;
    }

    return _readString(imagesJson['bannerUrl']) ??
        _readString(imagesJson['banner_url']);
  }

  Map<String, dynamic> _extractObject(dynamic payload) {
    if (payload is Map) {
      return Map<String, dynamic>.from(payload);
    }

    throw FormatException(
      'Expected AniLibria object payload, got ${payload.runtimeType}.',
    );
  }

  List<Map<String, dynamic>> _extractList(dynamic payload) {
    if (payload is List) {
      return payload
          .whereType<Map>()
          .map((entry) => Map<String, dynamic>.from(entry))
          .toList(growable: false);
    }

    if (payload is Map) {
      final list = payload['list'];
      if (list is List) {
        return list
            .whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList(growable: false);
      }

      return [Map<String, dynamic>.from(payload)];
    }

    throw FormatException(
      'Expected AniLibria list payload, got ${payload.runtimeType}.',
    );
  }

  Map<String, dynamic>? _readMap(dynamic value) {
    if (value is Map) {
      return Map<String, dynamic>.from(value);
    }

    return null;
  }

  List<String> _readStringList(dynamic value) {
    if (value is List) {
      return value
          .map(_readString)
          .whereType<String>()
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false);
    }

    return const [];
  }

  String? _readString(dynamic value) {
    if (value == null) {
      return null;
    }

    return switch (value) {
      String value => value,
      int value => value.toString(),
      _ => null,
    };
  }

  int? _readInt(dynamic value) {
    return switch (value) {
      int value => value,
      num value => value.toInt(),
      String value => int.tryParse(value),
      _ => null,
    };
  }

  bool? _readBool(dynamic value) {
    return switch (value) {
      bool value => value,
      int value => value != 0,
      String value => value == 'true' || value == '1',
      _ => null,
    };
  }

  DateTime? _readDateTime(dynamic value) {
    return switch (value) {
      DateTime value => value,
      int value => DateTime.fromMillisecondsSinceEpoch(
        value * 1000,
        isUtc: true,
      ),
      String value => DateTime.tryParse(value),
      _ => null,
    };
  }
}
