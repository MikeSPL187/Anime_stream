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
    test('maps latest series from latest releases payloads', () async {
      final repository = _buildRepository((options) async {
        expect(options.path, 'anime/releases/latest');
        expect(options.queryParameters['limit'], 1);

        return [
          _releasePayload(
            id: 9000,
            alias: 'kizumonogatari-iii',
            mainName: 'Истории ран',
            englishName: 'Kizumonogatari III',
            genres: const ['Вампиры', 'Экшен'],
            updatedAt: '2021-06-29T12:27:35Z',
            year: 2017,
            backgroundPath:
                '/storage/releases/backgrounds/9000/background.webp',
          ),
        ];
      });

      final seriesList = await repository.getLatestSeries(limit: 1);

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
        'https://anilibria.top/storage/releases/posters/9000/poster-preview.webp',
      );
      expect(
        series.bannerImageUrl,
        'https://anilibria.top/storage/releases/backgrounds/9000/background.webp',
      );
      expect(series.releaseYear, 2017);
      expect(series.status, SeriesStatus.unknown);
      expect(series.availability.status, AvailabilityStatus.available);
      expect(series.lastUpdatedAt, DateTime.parse('2021-06-29T12:27:35Z'));
    });

    test('maps search results from app search payloads', () async {
      final repository = _buildRepository((options) async {
        expect(options.path, 'app/search/releases');
        expect(options.queryParameters['query'], 'fate');

        return [
          _releasePayload(
            id: 42,
            alias: 'fate-apocrypha',
            mainName: 'Судьба/Апокриф',
            englishName: 'Fate/Apocrypha',
            year: 2017,
            updatedAt: '2023-11-14T22:13:20Z',
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

    test('maps series details from release payloads', () async {
      final repository = _buildRepository((options) async {
        expect(options.path, 'anime/releases/77');
        expect(options.queryParameters, isEmpty);

        return _releasePayload(
          id: 77,
          alias: 'frieren',
          mainName: 'Провожающая в последний путь Фрирен',
          englishName: 'Frieren: Beyond Journey\'s End',
          year: 2023,
          description: 'Journey after the adventure.',
          updatedAt: '2024-03-09T16:00:00Z',
          episodes: [
            _episodePayload(id: 'ep-1', ordinal: 1, name: 'Departure'),
          ],
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

    test(
      'maps a missing release lookup into a confirmed missing-series error',
      () async {
        final dio =
            Dio(BaseOptions(baseUrl: DioAnilibriaRemoteDataSource.apiBaseUrl))
              ..interceptors.add(
                InterceptorsWrapper(
                  onRequest: (options, handler) async {
                    handler.reject(
                      DioException(
                        requestOptions: options,
                        response: Response<dynamic>(
                          requestOptions: options,
                          statusCode: 404,
                        ),
                        type: DioExceptionType.badResponse,
                      ),
                    );
                  },
                ),
              );

        final repository = AniLibriaSeriesRepository(
          remoteDataSource: DioAnilibriaRemoteDataSource(dio: dio),
          seriesMapper: const AnilibriaSeriesMapper(),
          episodeMapper: const AnilibriaEpisodeMapper(),
        );

        await expectLater(
          () => repository.getSeriesById('404'),
          throwsA(isA<StateError>()),
        );
      },
    );

    test('maps episodes from release details payloads', () async {
      final repository = _buildRepository((options) async {
        expect(options.path, 'anime/releases/101');
        expect(options.queryParameters, isEmpty);

        return _releasePayload(
          id: 101,
          alias: 'monster',
          mainName: 'Монстр',
          englishName: 'Monster',
          episodes: [
            _episodePayload(
              id: 'episode-1',
              ordinal: 1,
              name: 'Herr Dr. Tenma',
              previewPath: '/episodes/101/1-thumb.webp',
              duration: 1440,
            ),
            _episodePayload(
              id: 'episode-2',
              ordinal: 2.5,
              previewPath: '/episodes/101/2-thumb.webp',
            ),
          ],
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
      expect(
        episodes.first.thumbnailImageUrl,
        'https://anilibria.top/episodes/101/1-thumb.webp',
      );
      expect(episodes.first.airDate, isNull);
      expect(episodes.first.duration, const Duration(seconds: 1440));
      expect(episodes.first.isFiller, isFalse);
      expect(episodes.first.isRecap, isFalse);
      expect(episodes.last.sortOrder, 2500);
      expect(episodes.last.numberLabel, '2.5');
      expect(episodes.last.title, 'Episode 2.5');
      expect(
        episodes.last.thumbnailImageUrl,
        'https://anilibria.top/episodes/101/2-thumb.webp',
      );
      expect(episodes.last.availability.status, AvailabilityStatus.available);
    });

    test(
      'reuses one release request for concurrent series and episode reads',
      () async {
        var requestCount = 0;
        final repository = _buildRepository((options) async {
          requestCount += 1;
          expect(options.path, 'anime/releases/777');
          expect(options.queryParameters, isEmpty);

          await Future<void>.delayed(const Duration(milliseconds: 10));
          return _releasePayload(
            id: 777,
            alias: 'kaiju-no-8',
            mainName: 'Кайдзю № 8',
            englishName: 'Kaiju No. 8',
            episodes: [
              _episodePayload(
                id: 'episode-1',
                ordinal: 1,
                name: 'The Man Who Became a Monster',
              ),
            ],
          );
        });

        final results = await Future.wait<Object>([
          repository.getSeriesById('777'),
          repository.getEpisodes('777'),
        ]);

        expect(requestCount, 1);
        expect((results[0] as Series).id, '777');
        expect((results[1] as List<Episode>), hasLength(1));
        expect((results[1] as List<Episode>).single.id, 'episode-1');
      },
    );

    test('maps catalog wrapped payloads for popular series', () async {
      final repository = _buildRepository((options) async {
        expect(options.path, 'anime/catalog/releases');
        expect(options.queryParameters['limit'], 1);
        expect(options.queryParameters['f[sorting]'], 'RATING_DESC');

        return {
          'data': [
            _releasePayload(
              id: 202,
              alias: 'haikyuu',
              mainName: 'Волейбол!!',
              englishName: 'Haikyuu!!',
              genres: const ['Спорт', 'Комедия'],
              year: 2014,
            ),
          ],
          'meta': {
            'pagination': {
              'total': 1,
              'count': 1,
              'per_page': 1,
              'current_page': 1,
              'total_pages': 1,
            },
          },
        };
      });

      final results = await repository.getPopularSeries(limit: 1);

      expect(results, hasLength(1));
      expect(results.single.id, '202');
      expect(results.single.slug, 'haikyuu');
      expect(results.single.genres, ['Спорт', 'Комедия']);
    });

    test('maps paged catalog listing from catalog payloads', () async {
      final repository = _buildRepository((options) async {
        expect(options.path, 'anime/catalog/releases');
        expect(options.queryParameters['page'], 3);
        expect(options.queryParameters['limit'], 2);

        return {
          'data': [
            _releasePayload(
              id: 301,
              alias: 'mob-psycho-100',
              mainName: 'Моб Психо 100',
              englishName: 'Mob Psycho 100',
              year: 2016,
            ),
            _releasePayload(
              id: 302,
              alias: 'vinland-saga',
              mainName: 'Сага о Винланде',
              englishName: 'Vinland Saga',
              year: 2019,
            ),
          ],
          'meta': {
            'pagination': {
              'total': 42,
              'count': 2,
              'per_page': 2,
              'current_page': 3,
              'total_pages': 21,
            },
          },
        };
      });

      final page = await repository.getCatalogPage(page: 3, pageSize: 2);

      expect(page.items.map((series) => series.id), ['301', '302']);
      expect(page.page, 3);
      expect(page.pageSize, 2);
      expect(page.totalItems, 42);
      expect(page.totalPages, 21);
      expect(page.hasPreviousPage, isTrue);
      expect(page.hasNextPage, isTrue);
    });

    test('rejects invalid paged catalog arguments', () async {
      final repository = _buildRepository((options) async {
        fail('Repository should reject invalid catalog arguments before I/O.');
      });

      expect(
        () => repository.getCatalogPage(page: 0, pageSize: 20),
        throwsArgumentError,
      );
      expect(
        () => repository.getCatalogPage(page: 1, pageSize: 0),
        throwsArgumentError,
      );
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
  required int id,
  required String alias,
  required String mainName,
  required String englishName,
  List<String> genres = const ['Драма'],
  String description = 'Provider description',
  String? backgroundPath,
  int? year,
  String updatedAt = '2024-03-22T10:58:31Z',
  List<Map<String, Object?>> episodes = const [],
}) {
  return {
    'id': id,
    'alias': alias,
    'name': {
      'main': mainName,
      'english': englishName,
      'alternative': 'Alt title',
    },
    'description': description,
    'genres': [
      for (final genre in genres) {'id': genre.hashCode.abs(), 'name': genre},
    ],
    'poster': {
      'src': '/storage/releases/posters/$id/poster-src.jpg',
      'preview': '/storage/releases/posters/$id/poster-preview.jpg',
      'thumbnail': '/storage/releases/posters/$id/poster-thumb.jpg',
      'optimized': {
        'src': '/storage/releases/posters/$id/poster-src.webp',
        'preview': '/storage/releases/posters/$id/poster-preview.webp',
        'thumbnail': '/storage/releases/posters/$id/poster-thumb.webp',
      },
    },
    ...?backgroundPath == null
        ? null
        : {
            'background': {
              'src': backgroundPath,
              'preview': backgroundPath,
              'optimized': {'src': backgroundPath, 'preview': backgroundPath},
            },
          },
    ...?year == null ? null : {'year': year},
    'updated_at': updatedAt,
    'is_ongoing': true,
    if (episodes.isNotEmpty) 'episodes': episodes,
  };
}

Map<String, Object?> _episodePayload({
  required String id,
  required num ordinal,
  String? name,
  String? previewPath,
  int? duration,
}) {
  return {
    'id': id,
    'ordinal': ordinal,
    ...?name == null ? null : {'name': name},
    ...?previewPath == null
        ? null
        : {
            'preview': {
              'src': previewPath,
              'preview': previewPath,
              'thumbnail': previewPath,
              'optimized': {
                'src': previewPath,
                'preview': previewPath,
                'thumbnail': previewPath,
              },
            },
          },
    ...?duration == null ? null : {'duration': duration},
  };
}
