import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anime_stream_app/data/adapters/anilibria/dio_anilibria_remote_data_source.dart';

void main() {
  group('DioAnilibriaRemoteDataSource', () {
    test('parses paged catalog payloads with pagination metadata', () async {
      final dataSource = _buildDataSource((options) async {
        expect(options.path, 'anime/catalog/releases');
        expect(options.queryParameters['page'], 2);
        expect(options.queryParameters['limit'], 3);

        return {
          'data': [
            _releasePayload(
              id: 701,
              alias: 'dandadan',
              mainName: 'Дандадан',
              englishName: 'Dandadan',
            ),
          ],
          'meta': {
            'pagination': {
              'total': 31,
              'count': 1,
              'per_page': 3,
              'current_page': 2,
              'total_pages': 11,
            },
          },
        };
      });

      final page = await dataSource.fetchCatalogPage(page: 2, limit: 3);

      expect(page.releases, hasLength(1));
      expect(page.releases.single.id, '701');
      expect(page.currentPage, 2);
      expect(page.perPage, 3);
      expect(page.totalItems, 31);
      expect(page.totalPages, 11);
    });

    test('throws when catalog pagination metadata is missing', () async {
      final dataSource = _buildDataSource((options) async {
        expect(options.path, 'anime/catalog/releases');

        return {
          'data': [
            _releasePayload(
              id: 702,
              alias: 'pluto',
              mainName: 'Плутон',
              englishName: 'Pluto',
            ),
          ],
        };
      });

      expect(
        () => dataSource.fetchCatalogPage(page: 1, limit: 20),
        throwsA(isA<FormatException>()),
      );
    });

    test(
      'normalizes media urls and parses episode stream urls from release details payloads',
      () async {
        final dataSource = _buildDataSource((options) async {
          expect(options.path, 'anime/releases/501');
          expect(options.queryParameters, isEmpty);

          return _releasePayload(
            id: 501,
            alias: 'pluto',
            mainName: 'Плутон',
            englishName: 'Pluto',
            backgroundPath: '/storage/releases/backgrounds/501/background.webp',
            episodes: [
              _episodePayload(
                id: 'episode-1',
                ordinal: 1,
                previewPath: '/episodes/501/episode-1-thumb.webp',
                hls480Url: 'https://cdn.example.com/pluto/episode-1-480.m3u8',
                hls720Url: 'https://cdn.example.com/pluto/episode-1-720.m3u8',
                hls1080Url: 'https://cdn.example.com/pluto/episode-1-1080.m3u8',
              ),
            ],
          );
        });

        final release = await dataSource.fetchReleaseDetails('501');

        expect(
          release.images?.posterUrl,
          'https://anilibria.top/storage/releases/posters/501/poster-preview.webp',
        );
        expect(
          release.images?.bannerUrl,
          'https://anilibria.top/storage/releases/backgrounds/501/background.webp',
        );
        expect(release.episodes, hasLength(1));
        final episode = release.episodes.single;
        expect(episode.id, 'episode-1');
        expect(
          episode.thumbnailUrl,
          'https://anilibria.top/episodes/501/episode-1-thumb.webp',
        );
        expect(
          episode.hls480Url,
          'https://cdn.example.com/pluto/episode-1-480.m3u8',
        );
        expect(
          episode.hls720Url,
          'https://cdn.example.com/pluto/episode-1-720.m3u8',
        );
        expect(
          episode.hls1080Url,
          'https://cdn.example.com/pluto/episode-1-1080.m3u8',
        );
      },
    );
  });
}

DioAnilibriaRemoteDataSource _buildDataSource(_PayloadResponder responder) {
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

  return DioAnilibriaRemoteDataSource(dio: dio);
}

typedef _PayloadResponder = Future<dynamic> Function(RequestOptions options);

Map<String, Object?> _releasePayload({
  required int id,
  required String alias,
  required String mainName,
  required String englishName,
  String? backgroundPath,
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
    'description': 'Provider description',
    'genres': const [
      {'id': 1, 'name': 'Драма'},
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
    'updated_at': '2024-03-22T10:58:31Z',
    'is_ongoing': true,
    'episodes': episodes,
  };
}

Map<String, Object?> _episodePayload({
  required String id,
  required num ordinal,
  String? previewPath,
  String? hls480Url,
  String? hls720Url,
  String? hls1080Url,
}) {
  return {
    'id': id,
    'ordinal': ordinal,
    'name': 'Episode $ordinal',
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
    ...?hls480Url == null ? null : {'hls_480': hls480Url},
    ...?hls720Url == null ? null : {'hls_720': hls720Url},
    ...?hls1080Url == null ? null : {'hls_1080': hls1080Url},
  };
}
