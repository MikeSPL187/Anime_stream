import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anime_stream_app/data/adapters/anilibria/anilibria_remote_data_source.dart';
import 'package:anime_stream_app/data/dto/anilibria/anilibria_episode_dto.dart';
import 'package:anime_stream_app/data/dto/anilibria/anilibria_release_dto.dart';
import 'package:anime_stream_app/data/dto/anilibria/anilibria_release_page_dto.dart';
import 'package:anime_stream_app/data/local/json_downloads_store.dart';
import 'package:anime_stream_app/data/repositories/local/local_downloads_repository.dart';
import 'package:anime_stream_app/domain/models/download_entry.dart';

void main() {
  group('LocalDownloadsRepository', () {
    test('queues a new episode download as metadata only foundation state', () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'downloads-repository-test',
      );
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });

      final downloadsStore = JsonDownloadsStore(
        directoryProvider: () async => tempDirectory,
        relativeFilePath: 'downloads/download_entries.json',
      );
      final repository = LocalDownloadsRepository(
        downloadsStore: downloadsStore,
        remoteDataSource: _FakeRemoteDataSource(),
        dio: Dio(),
        downloadsRootDirectoryProvider: () async => tempDirectory,
      );

      await repository.queueEpisodeDownload(
        seriesId: 'series-1',
        episodeId: 'episode-7',
        selectedQuality: '720p',
      );

      final entries = await repository.getDownloads();

      expect(entries, hasLength(1));
      expect(entries.first.seriesId, 'series-1');
      expect(entries.first.episodeId, 'episode-7');
      expect(entries.first.selectedQuality, '720p');
      expect(entries.first.status, DownloadStatus.queued);
      expect(entries.first.isPlayableOffline, isFalse);
    });

    test('downloads HLS VOD assets into a local playable package', () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'downloads-repository-execution-test',
      );
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });

      final downloadsStore = JsonDownloadsStore(
        directoryProvider: () async => tempDirectory,
        relativeFilePath: 'downloads/download_entries.json',
      );

      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            final url = options.uri.toString();
            if (url == 'https://cdn.example.com/episode/index.m3u8') {
              handler.resolve(
                Response<String>(
                  requestOptions: options,
                  statusCode: 200,
                  data: '#EXTM3U\n#EXT-X-VERSION:7\n#EXT-X-MAP:URI="init.mp4"\n#EXTINF:5.0,\nseg-1.ts\n#EXTINF:5.0,\nseg-2.ts\n#EXT-X-ENDLIST',
                ),
              );
              return;
            }

            if (url == 'https://cdn.example.com/episode/init.mp4') {
              handler.resolve(
                Response<List<int>>(
                  requestOptions: options,
                  statusCode: 200,
                  data: const [0, 1, 2, 3],
                ),
              );
              return;
            }

            if (url == 'https://cdn.example.com/episode/seg-1.ts') {
              handler.resolve(
                Response<List<int>>(
                  requestOptions: options,
                  statusCode: 200,
                  data: const [4, 5, 6],
                ),
              );
              return;
            }

            if (url == 'https://cdn.example.com/episode/seg-2.ts') {
              handler.resolve(
                Response<List<int>>(
                  requestOptions: options,
                  statusCode: 200,
                  data: const [7, 8, 9, 10],
                ),
              );
              return;
            }

            handler.reject(
              DioException(
                requestOptions: options,
                message: 'Unexpected request in test: $url',
              ),
            );
          },
        ),
      );

      final repository = LocalDownloadsRepository(
        downloadsStore: downloadsStore,
        remoteDataSource: _FakeRemoteDataSource(
          release: const AnilibriaReleaseDto(
            id: 'series-9',
            episodes: [
              AnilibriaEpisodeDto(
                id: 'episode-2',
                releaseId: 'series-9',
                ordinal: 2,
                numberLabel: '2',
                title: 'Offline Probe',
                hls720Url: 'https://cdn.example.com/episode/index.m3u8',
              ),
            ],
          ),
        ),
        dio: dio,
        downloadsRootDirectoryProvider: () async => tempDirectory,
      );

      final completedEntry = await repository.startEpisodeDownload(
        seriesId: 'series-9',
        episodeId: 'episode-2',
        selectedQuality: '720p',
      );

      expect(completedEntry.status, DownloadStatus.completed);
      expect(completedEntry.isPlayableOffline, isTrue);
      expect(completedEntry.localAssetUri, startsWith('file://'));
      expect(completedEntry.bytesDownloaded, 11);

      final localManifestFile = File(
        Uri.parse(completedEntry.localAssetUri!).toFilePath(),
      );
      expect(await localManifestFile.exists(), isTrue);

      final localManifest = await localManifestFile.readAsString();
      expect(localManifest, contains('asset_0000.mp4'));
      expect(localManifest, contains('asset_0001.ts'));
      expect(localManifest, contains('asset_0002.ts'));
      expect(localManifest, isNot(contains('https://cdn.example.com')));

      final playableEntry = await repository.getPlayableDownload(
        seriesId: 'series-9',
        episodeId: 'episode-2',
      );
      expect(playableEntry, isNotNull);
      expect(playableEntry!.localAssetUri, completedEntry.localAssetUri);
    });

    test('returns completed local asset for offline playback and removes bytes on deletion', () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'downloads-repository-offline-test',
      );
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });

      final episodeDirectory = Directory(
        '${tempDirectory.path}/downloads/series-9/episode-2/1080p',
      );
      await episodeDirectory.create(recursive: true);
      await File('${episodeDirectory.path}/index.m3u8').writeAsString('#EXTM3U');

      final downloadsStore = JsonDownloadsStore(
        directoryProvider: () async => tempDirectory,
        relativeFilePath: 'downloads/download_entries.json',
      );
      await downloadsStore.writeAll({
        'series-9::episode-2::1080p': const DownloadEntry(
          id: 'series-9::episode-2::1080p',
          seriesId: 'series-9',
          episodeId: 'episode-2',
          selectedQuality: '1080p',
          status: DownloadStatus.completed,
          localAssetUri: 'file:///tmp/index.m3u8',
          storageDirectoryPath: '/tmp/storage',
          createdAt: null,
          completedAt: null,
        ).copyWith(
          localAssetUri: 'file://${episodeDirectory.path}/index.m3u8',
          storageDirectoryPath: episodeDirectory.path,
        ).toJson(),
      });

      final repository = LocalDownloadsRepository(
        downloadsStore: downloadsStore,
        remoteDataSource: _FakeRemoteDataSource(),
        dio: Dio(),
        downloadsRootDirectoryProvider: () async => tempDirectory,
      );

      final playableEntry = await repository.getPlayableDownload(
        seriesId: 'series-9',
        episodeId: 'episode-2',
      );

      expect(playableEntry, isNotNull);
      expect(playableEntry!.isPlayableOffline, isTrue);

      await repository.removeDownload(playableEntry.id);

      final remainingEntries = await repository.getDownloads();
      expect(remainingEntries, isEmpty);
      expect(await episodeDirectory.exists(), isFalse);
    });
  });
}

class _FakeRemoteDataSource implements AnilibriaRemoteDataSource {
  const _FakeRemoteDataSource({this.release});

  final AnilibriaReleaseDto? release;

  @override
  Future<List<AnilibriaReleaseDto>> fetchFeaturedReleases({int limit = 20}) {
    throw UnimplementedError();
  }

  @override
  Future<AnilibriaReleasePageDto> fetchCatalogPage({
    int page = 1,
    int limit = 20,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<AnilibriaReleaseDto>> fetchPopularReleases({int limit = 20}) {
    throw UnimplementedError();
  }

  @override
  Future<AnilibriaReleaseDto> fetchReleaseDetails(String releaseId) async {
    if (release == null) {
      throw StateError('No release configured for test');
    }
    return release!;
  }

  @override
  Future<List<AnilibriaEpisodeDto>> fetchReleaseEpisodes(String releaseId) {
    throw UnimplementedError();
  }

  @override
  Future<List<AnilibriaReleaseDto>> fetchSimulcastReleases({int limit = 20}) {
    throw UnimplementedError();
  }

  @override
  Future<List<AnilibriaReleaseDto>> fetchTrendingReleases({int limit = 20}) {
    throw UnimplementedError();
  }

  @override
  Future<List<AnilibriaReleaseDto>> searchReleases(
    String query, {
    int limit = 20,
  }) {
    throw UnimplementedError();
  }
}
