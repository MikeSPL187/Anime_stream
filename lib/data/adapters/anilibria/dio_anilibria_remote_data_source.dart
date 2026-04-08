import 'package:dio/dio.dart';

import '../../dto/anilibria/anilibria_episode_dto.dart';
import '../../dto/anilibria/anilibria_release_page_dto.dart';
import '../../dto/anilibria/anilibria_release_dto.dart';
import 'anilibria_remote_data_source.dart';

class DioAnilibriaRemoteDataSource implements AnilibriaRemoteDataSource {
  DioAnilibriaRemoteDataSource({required Dio dio}) : _dio = dio;

  static const apiBaseUrl = 'https://anilibria.top/api/v1/';
  static final Uri _mediaBaseUri = Uri.parse('https://anilibria.top/');

  final Dio _dio;

  @override
  Future<List<AnilibriaReleaseDto>> fetchLatestReleases({
    int limit = 20,
  }) async {
    final payload = await _getJson(
      'anime/releases/latest',
      queryParameters: {'limit': limit},
    );

    return _parseReleaseList(payload);
  }

  @override
  Future<List<AnilibriaReleaseDto>> fetchTrendingReleases({
    int limit = 20,
  }) async {
    final payload = await _getJson(
      'anime/catalog/releases',
      queryParameters: {
        'limit': limit,
        'f[publish_statuses]': 'IS_ONGOING',
        'f[sorting]': 'FRESH_AT_DESC',
      },
    );

    return _parseReleaseList(payload);
  }

  @override
  Future<List<AnilibriaReleaseDto>> fetchPopularReleases({
    int limit = 20,
  }) async {
    final payload = await _getJson(
      'anime/catalog/releases',
      queryParameters: {'limit': limit, 'f[sorting]': 'RATING_DESC'},
    );

    return _parseReleaseList(payload);
  }

  @override
  Future<AnilibriaReleasePageDto> fetchCatalogPage({
    int page = 1,
    int limit = 20,
  }) async {
    final payload = await _getJson(
      'anime/catalog/releases',
      queryParameters: {'page': page, 'limit': limit},
    );

    return _parseReleasePage(payload);
  }

  @override
  Future<AnilibriaReleaseDto> fetchReleaseDetails(String releaseId) async {
    final payload = await _getJson(
      'anime/releases/${Uri.encodeComponent(releaseId)}',
    );

    return _parseRelease(_extractObject(payload));
  }

  @override
  Future<List<AnilibriaEpisodeDto>> fetchReleaseEpisodes(
    String releaseId,
  ) async {
    final payload = await _getJson(
      'anime/releases/${Uri.encodeComponent(releaseId)}',
    );

    return _parseRelease(_extractObject(payload)).episodes;
  }

  @override
  Future<List<AnilibriaReleaseDto>> searchReleases(
    String query, {
    int limit = 20,
  }) async {
    final payload = await _getJson(
      'app/search/releases',
      queryParameters: {'query': query},
    );

    return _parseReleaseList(payload).take(limit).toList(growable: false);
  }

  @override
  Future<List<AnilibriaReleaseDto>> fetchSimulcastReleases({
    int limit = 20,
  }) async {
    final payload = await _getJson(
      'anime/catalog/releases',
      queryParameters: {
        'limit': limit,
        'f[publish_statuses]': 'IS_ONGOING',
        'f[sorting]': 'FRESH_AT_DESC',
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

  List<AnilibriaReleaseDto> _parseReleaseList(dynamic payload) {
    final rawList = _extractList(payload);
    return rawList.map(_parseRelease).toList(growable: false);
  }

  AnilibriaReleasePageDto _parseReleasePage(dynamic payload) {
    final root = _extractObject(payload);
    final paginationJson = _readMap(_readMap(root['meta'])?['pagination']);
    if (paginationJson == null) {
      throw const FormatException(
        'AniLibria catalog payload is missing pagination metadata.',
      );
    }

    final currentPage = _readInt(paginationJson['current_page']);
    final perPage = _readInt(paginationJson['per_page']);
    final totalItems = _readInt(paginationJson['total']);
    final totalPages = _readInt(paginationJson['total_pages']);
    if (currentPage == null ||
        perPage == null ||
        totalItems == null ||
        totalPages == null) {
      throw const FormatException(
        'AniLibria catalog pagination metadata is incomplete.',
      );
    }

    return AnilibriaReleasePageDto(
      releases: _parseReleaseList(root),
      currentPage: currentPage,
      perPage: perPage,
      totalItems: totalItems,
      totalPages: totalPages,
    );
  }

  AnilibriaReleaseDto _parseRelease(Map<String, dynamic> json) {
    final releaseId = _readString(json['id']);
    final nameJson = _readMap(json['name']);

    if (releaseId == null || releaseId.isEmpty) {
      throw const FormatException('AniLibria release is missing an id.');
    }

    return AnilibriaReleaseDto(
      id: releaseId,
      code: _readString(json['alias']),
      names: AnilibriaNamesDto(
        main: _readString(nameJson?['main']),
        english: _readString(nameJson?['english']),
        alternative: _readAlternativeNames(nameJson?['alternative']),
      ),
      description: _readString(json['description']),
      genres: _readGenres(json['genres']),
      images: AnilibriaImageSetDto(
        posterUrl: _extractPosterUrl(json),
        bannerUrl: _extractBannerUrl(json),
      ),
      releaseYear: _readInt(json['year']),
      updatedAt:
          _readDateTime(json['updated_at']) ??
          _readDateTime(json['fresh_at']) ??
          _readDateTime(json['created_at']),
      episodes: _parseEpisodes(json, releaseId: releaseId),
      raw: Map<String, Object?>.from(json),
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

    final latestEpisodeJson = _readMap(releaseJson['latest_episode']);
    if (latestEpisodeJson != null) {
      final episode = _parseEpisode(latestEpisodeJson, releaseId: releaseId);
      return episode == null ? const [] : [episode];
    }

    return const [];
  }

  AnilibriaEpisodeDto? _parseEpisode(
    dynamic payload, {
    required String releaseId,
  }) {
    final json = _readMap(payload);
    if (json == null) {
      return null;
    }

    final parsedOrdinal = _readOrdinal(json['ordinal']);
    if (parsedOrdinal == null) {
      return null;
    }

    return AnilibriaEpisodeDto(
      id: _readString(json['id']) ?? '$releaseId-${parsedOrdinal.numberLabel}',
      releaseId: _readString(json['release_id']) ?? releaseId,
      ordinal: parsedOrdinal.sortOrder,
      numberLabel: parsedOrdinal.numberLabel,
      title:
          _readString(json['name']) ??
          _readString(json['name_english']) ??
          'Episode ${parsedOrdinal.numberLabel}',
      durationSeconds: _readInt(json['duration']),
      thumbnailUrl: _extractEpisodePreviewUrl(json),
      hls480Url: _readString(json['hls_480']),
      hls720Url: _readString(json['hls_720']),
      hls1080Url: _readString(json['hls_1080']),
      airedAt: null,
      raw: Map<String, Object?>.from(json),
    );
  }

  List<String> _readAlternativeNames(dynamic value) {
    if (value == null) {
      return const [];
    }

    if (value is List) {
      return value
          .map(_readString)
          .whereType<String>()
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false);
    }

    final singleValue = _readString(value);
    return singleValue == null || singleValue.isEmpty
        ? const []
        : [singleValue];
  }

  List<String> _readGenres(dynamic value) {
    if (value is List) {
      return value
          .map((entry) {
            final genreJson = _readMap(entry);
            return _readString(genreJson?['name']) ?? _readString(entry);
          })
          .whereType<String>()
          .where((entry) => entry.isNotEmpty)
          .toList(growable: false);
    }

    return const [];
  }

  String? _extractPosterUrl(Map<String, dynamic> json) {
    final posterJson = _readMap(json['poster']);
    final posterOptimizedJson = _readMap(posterJson?['optimized']);
    final postersJson = _readMap(json['posters']);
    final postersSmallJson = _readMap(postersJson?['small']);
    final postersMediumJson = _readMap(postersJson?['medium']);
    final postersOriginalJson = _readMap(postersJson?['original']);

    return _normalizeMediaUrl(
      _firstReadableString([
        posterOptimizedJson?['preview'],
        posterOptimizedJson?['src'],
        posterJson?['preview'],
        posterJson?['src'],
        posterJson?['thumbnail'],
        postersMediumJson?['full_url'],
        postersMediumJson?['url'],
        postersSmallJson?['full_url'],
        postersSmallJson?['url'],
        postersOriginalJson?['full_url'],
        postersOriginalJson?['url'],
      ]),
    );
  }

  String? _extractBannerUrl(Map<String, dynamic> json) {
    final backgroundJson = _readMap(json['background']);
    final backgroundOptimizedJson = _readMap(backgroundJson?['optimized']);
    final bannerJson = _readMap(json['banner']);
    final bannerOptimizedJson = _readMap(bannerJson?['optimized']);
    final coverJson = _readMap(json['cover']);
    final coverOptimizedJson = _readMap(coverJson?['optimized']);
    final posterJson = _readMap(json['poster']);
    final posterOptimizedJson = _readMap(posterJson?['optimized']);
    final postersJson = _readMap(json['posters']);
    final postersOriginalJson = _readMap(postersJson?['original']);

    return _normalizeMediaUrl(
      _firstReadableString([
        backgroundOptimizedJson?['src'],
        backgroundOptimizedJson?['preview'],
        backgroundJson?['src'],
        backgroundJson?['preview'],
        bannerOptimizedJson?['src'],
        bannerOptimizedJson?['preview'],
        bannerJson?['src'],
        bannerJson?['preview'],
        coverOptimizedJson?['src'],
        coverOptimizedJson?['preview'],
        coverJson?['src'],
        coverJson?['preview'],
        postersOriginalJson?['full_url'],
        postersOriginalJson?['url'],
        posterOptimizedJson?['src'],
        posterJson?['src'],
      ]),
    );
  }

  String? _extractEpisodePreviewUrl(Map<String, dynamic> json) {
    final previewJson = _readMap(json['preview']);
    final optimizedJson = _readMap(previewJson?['optimized']);

    return _normalizeMediaUrl(
      _firstReadableString([
        optimizedJson?['thumbnail'],
        optimizedJson?['preview'],
        optimizedJson?['src'],
        previewJson?['thumbnail'],
        previewJson?['preview'],
        previewJson?['src'],
      ]),
    );
  }

  String? _firstReadableString(List<dynamic> values) {
    for (final value in values) {
      final parsed = _readString(value)?.trim();
      if (parsed != null && parsed.isNotEmpty) {
        return parsed;
      }
    }

    return null;
  }

  String? _normalizeMediaUrl(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    if (trimmed.startsWith('//')) {
      return 'https:$trimmed';
    }

    final parsed = Uri.tryParse(trimmed);
    if (parsed != null && parsed.hasScheme) {
      return trimmed;
    }

    return _mediaBaseUri.resolve(trimmed).toString();
  }

  _ParsedOrdinal? _readOrdinal(dynamic value) {
    return switch (value) {
      int value => _ParsedOrdinal(
        sortOrder: value,
        numberLabel: value.toString(),
      ),
      num value => _ParsedOrdinal(
        sortOrder: value == value.toInt()
            ? value.toInt()
            : (value.toDouble() * 1000).round(),
        numberLabel: _formatOrdinalLabel(value),
      ),
      String value => _readOrdinal(num.tryParse(value)),
      _ => null,
    };
  }

  String _formatOrdinalLabel(num value) {
    return value == value.toInt() ? value.toInt().toString() : value.toString();
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
      final data = payload['data'];
      if (data is List) {
        return data
            .whereType<Map>()
            .map((entry) => Map<String, dynamic>.from(entry))
            .toList(growable: false);
      }

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

  String? _readString(dynamic value) {
    if (value == null) {
      return null;
    }

    return switch (value) {
      String value => value,
      int value => value.toString(),
      double value => value.toString(),
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

  DateTime? _readDateTime(dynamic value) {
    return switch (value) {
      DateTime value => value,
      String value => DateTime.tryParse(value),
      _ => null,
    };
  }
}

class _ParsedOrdinal {
  const _ParsedOrdinal({required this.sortOrder, required this.numberLabel});

  final int sortOrder;
  final String numberLabel;
}
