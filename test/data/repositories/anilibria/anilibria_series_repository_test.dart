import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anime_stream_app/data/adapters/anilibria/dio_anilibria_remote_data_source.dart';
import 'package:anime_stream_app/data/dto/anilibria/anilibria_episode_dto.dart';
import 'package:anime_stream_app/data/dto/anilibria/anilibria_release_dto.dart';
import 'package:anime_stream_app/data/mappers/anilibria/anilibria_episode_mapper.dart';
import 'package:anime_stream_app/data/mappers/anilibria/anilibria_series_mapper.dart';
import 'package:anime_stream_app/data/repositories/anilibria/anilibria_series_repository.dart';
import 'package:anime_stream_app/domain/models/availability_state.dart';
import 'package:anime_stream_app/domain/models/episode.dart';
import 'package:anime_stream_app/domain/models/series.dart';

void main() {
  group('AniLibriaSeriesRepository', () {
    test('maps featured series from a wrapped list response', () async {
      final repository = _buildRepository((options) async {
        expect(options.path, 'title/updates');
        expect(options.queryParameters['limit'], 1);

        return {
          'list': [
            _releasePayload(
              id: '9000',
              code: 'kizumonogatari-iii',
              ruName: 'Истории ран',
              enName: 'Kizumonogatari III',
              genres: ['Вампиры', 'Экшен'],
              updated: 1624984055,
              seasonYear: 2017,
            ),
          ],
        };
      });

      final seriesList = await repository.getFeaturedSeries(limit: 1);

      expect(seriesList, hasLength(1));

      final series = seriesList.single;
      expect(series, isA<Series>());
      expect(series, isNot(isA<AnilibriaReleaseDto>()));
      expect(series.id, '9000');
      expect(series.slug, 'kizumonogatari-iii');
      expect(series.title, 'Истории ран');
      expect(series.originalTitle, 'Kizumonogatari III');
      expect(series.genres, ['Вампиры', 'Экшен']);
      expect(
        series.posterImageUrl,
        '/storage/releases/posters/9000/poster-medium.jpg',
      );
      expect(series.releaseYear, 2017);
      expect(series.status, SeriesStatus.unknown);
      expect(series.availability.status, AvailabilityStatus.available);
      expect(
        series.lastUpdatedAt,
        DateTime.fromMillisecondsSinceEpoch(1624984055 * 1000, isUtc: true),
      );
    });

    test('maps search results from a raw list response', () async {
      final repository = _buildRepository((options) async {
        expect(options.path, 'title/search');
        expect(options.queryParameters['search'], 'fate');
        expect(options.queryParameters['limit'], 2);

        return [
          _releasePayload(
            id: '42',
            code: 'fate-apocrypha',
            ruName: 'Судьба/Апокриф',
            enName: 'Fate/Apocrypha',
            releaseYear: 2017,
            updated: 1700000000,
          ),
        ];
      });

      final results = await repository.searchSeries('fate', limit: 2);

      expect(results, hasLength(1));
      expect(results.single, isA<Series>());
      expect(results.single, isNot(isA<AnilibriaReleaseDto>()));
      expect(results.single.id, '42');
      expect(results.single.slug, 'fate-apocrypha');
      expect(results.single.title, 'Судьба/Апокриф');
      expect(results.single.originalTitle, 'Fate/Apocrypha');
      expect(results.single.releaseYear, 2017);
    });

    test('maps series details from a title payload', () async {
      final repository = _buildRepository((options) async {
        expect(options.path, 'title');
        expect(options.queryParameters['id'], '77');

        return _releasePayload(
          id: '77',
          code: 'frieren',
          ruName: 'Провожающая в последний путь Фрирен',
          enName: 'Frieren: Beyond Journey\'s End',
          releaseYear: 2023,
          description: 'Journey after the adventure.',
          updated: 1710000000,
          playerList: {
            '1': {'uuid': 'ep-1', 'episode': 1, 'name': 'Departure'},
          },
        );
      });

      final series = await repository.getSeriesById('77');

      expect(series, isA<Series>());
      expect(series.id, '77');
      expect(series.slug, 'frieren');
      expect(series.title, 'Провожающая в последний путь Фрирен');
      expect(series.synopsis, 'Journey after the adventure.');
      expect(series.releaseYear, 2023);
      expect(series.posterImageUrl, isNotNull);
    });

    test('maps episodes from player.list object payloads', () async {
      final repository = _buildRepository((options) async {
        expect(options.path, 'title');
        expect(options.queryParameters['id'], '101');

        return _releasePayload(
          id: '101',
          code: 'monster',
          ruName: 'Монстр',
          enName: 'Monster',
          playerList: {
            '1': {
              'uuid': 'episode-1',
              'name': 'Herr Dr. Tenma',
              'created_timestamp': 1712000000,
              'preview': '/episodes/101/1.jpg',
            },
            '2': {
              'uuid': 'episode-2',
              'description': 'A difficult choice.',
              'duration': 1440,
              'preview': '/episodes/101/2.jpg',
              'is_filler': 1,
            },
          },
        );
      });

      final episodes = await repository.getEpisodes('101');

      expect(episodes, hasLength(2));
      expect(episodes.first, isA<Episode>());
      expect(episodes.first, isNot(isA<AnilibriaEpisodeDto>()));
      expect(episodes.first.id, 'episode-1');
      expect(episodes.first.seriesId, '101');
      expect(episodes.first.sortOrder, 1);
      expect(episodes.first.numberLabel, '1');
      expect(episodes.first.title, 'Herr Dr. Tenma');
      expect(episodes.first.thumbnailImageUrl, '/episodes/101/1.jpg');
      expect(
        episodes.first.airDate,
        DateTime.fromMillisecondsSinceEpoch(1712000000 * 1000, isUtc: true),
      );
      expect(episodes.last.sortOrder, 2);
      expect(episodes.last.title, 'Episode 2');
      expect(episodes.last.synopsis, 'A difficult choice.');
      expect(episodes.last.duration, const Duration(seconds: 1440));
      expect(episodes.last.isFiller, isTrue);
      expect(episodes.last.availability.status, AvailabilityStatus.available);
    });

    test('maps episodes from player.list array payloads', () async {
      final repository = _buildRepository((options) async {
        expect(options.path, 'title');
        expect(options.queryParameters['id'], '202');

        return _releasePayload(
          id: '202',
          code: 'haikyuu',
          ruName: 'Волейбол!!',
          enName: 'Haikyuu!!',
          playerList: [
            {
              'uuid': 'haikyuu-1',
              'episode': 1,
              'name': 'The End & The Beginning',
              'created_timestamp': 1713000000,
            },
            {
              'id': 'haikyuu-2',
              'ordinal': 2,
              'title': 'Karasuno High School Volleyball Club',
              'duration_seconds': 1450,
              'aired_at': '2024-04-15T00:00:00Z',
              'isRecap': true,
            },
          ],
        );
      });

      final episodes = await repository.getEpisodes('202');

      expect(episodes, hasLength(2));
      expect(episodes.first.id, 'haikyuu-1');
      expect(episodes.first.title, 'The End & The Beginning');
      expect(episodes[1].id, 'haikyuu-2');
      expect(episodes[1].sortOrder, 2);
      expect(episodes[1].title, 'Karasuno High School Volleyball Club');
      expect(episodes[1].duration, const Duration(seconds: 1450));
      expect(episodes[1].airDate, DateTime.parse('2024-04-15T00:00:00Z'));
      expect(episodes[1].isRecap, isTrue);
    });
  });
}

AniLibriaSeriesRepository _buildRepository(_PayloadResponder responder) {
  final dio = Dio(BaseOptions(baseUrl: DioAnilibriaRemoteDataSource.apiBaseUrl))
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final payload = await responder(options);
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              data: payload,
              statusCode: 200,
            ),
          );
        },
      ),
    );

  final remoteDataSource = DioAnilibriaRemoteDataSource(dio: dio);

  return AniLibriaSeriesRepository(
    remoteDataSource: remoteDataSource,
    seriesMapper: const AnilibriaSeriesMapper(),
    episodeMapper: const AnilibriaEpisodeMapper(),
  );
}

typedef _PayloadResponder = Future<dynamic> Function(RequestOptions options);

Map<String, Object?> _releasePayload({
  required String id,
  required String code,
  required String ruName,
  required String enName,
  List<String> genres = const ['Драма'],
  String description = 'Provider description',
  int? releaseYear,
  int? seasonYear,
  int updated = 1711111111,
  Object? playerList,
}) {
  return {
    'id': id,
    'code': code,
    'names': {
      'ru': ruName,
      'en': enName,
      'alternative': ['Alt title'],
    },
    'description': description,
    'genres': genres,
    'posters': {
      'small': {'url': '/storage/releases/posters/$id/poster-small.jpg'},
      'medium': {'url': '/storage/releases/posters/$id/poster-medium.jpg'},
      'original': {'url': '/storage/releases/posters/$id/poster-original.jpg'},
    },
    ...?releaseYear == null ? null : {'releaseYear': releaseYear},
    ...?seasonYear == null
        ? null
        : {
            'season': {'year': seasonYear},
          },
    'updated': updated,
    'status': {'code': 1, 'string': 'ongoing'},
    ...?playerList == null
        ? null
        : {
            'player': {'list': playerList},
          },
  };
}
