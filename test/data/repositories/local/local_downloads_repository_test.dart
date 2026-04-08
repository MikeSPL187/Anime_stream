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
  group('LocalDownloadsRepository offline integrity normalization', () {
    test(
      'demotes completed entry when local asset is missing and persists change',
      () async {
        final sandbox = await Directory.systemTemp.createTemp(
          'anime_stream_downloads_missing_asset_',
        );
        addTearDown(() async {
          if (await sandbox.exists()) {
            await sandbox.delete(recursive: true);
          }
        });

        final store = JsonDownloadsStore(
          directoryProvider: () async => sandbox,
        );
        final repository = LocalDownloadsRepository(
          downloadsStore: store,
          remoteDataSource: _FakeAnilibriaRemoteDataSource(),
          dio: Dio(),
          downloadsRootDirectoryProvider: () async => sandbox,
        );

        final missingAssetUri = Uri.file(
          '${sandbox.path}/downloads/series-1/ep-1/1080p/index.m3u8',
        ).toString();

        final entry = DownloadEntry(
          id: 'series-1::ep-1::1080p',
          seriesId: 'series-1',
          episodeId: 'ep-1',
          selectedQuality: '1080p',
          status: DownloadStatus.completed,
          localAssetUri: missingAssetUri,
          storageDirectoryPath: '${sandbox.path}/downloads/series-1/ep-1/1080p',
          createdAt: DateTime(2026, 1, 1),
          completedAt: DateTime(2026, 1, 2),
        );

        await store.writeAll({entry.id: entry.toJson()});

        final entries = await repository.getDownloads();
        final normalized = entries.single;

        expect(normalized.status, DownloadStatus.failed);
        expect(normalized.localAssetUri, isNull);
        expect(normalized.completedAt, isNull);
        expect(normalized.lastError, 'Offline asset is missing on device.');

        final persisted = await store.readAll();
        final persistedEntry = DownloadEntry.fromJson(
          Map<String, dynamic>.from(persisted[entry.id] as Map),
        );

        expect(persistedEntry.status, DownloadStatus.failed);
        expect(persistedEntry.localAssetUri, isNull);
        expect(persistedEntry.completedAt, isNull);
        expect(persistedEntry.lastError, 'Offline asset is missing on device.');
      },
    );

    test(
      'demotes completed HLS entry when package directory is missing on device',
      () async {
        final sandbox = await Directory.systemTemp.createTemp(
          'anime_stream_downloads_missing_dir_',
        );
        addTearDown(() async {
          if (await sandbox.exists()) {
            await sandbox.delete(recursive: true);
          }
        });

        final store = JsonDownloadsStore(
          directoryProvider: () async => sandbox,
        );
        final repository = LocalDownloadsRepository(
          downloadsStore: store,
          remoteDataSource: _FakeAnilibriaRemoteDataSource(),
          dio: Dio(),
          downloadsRootDirectoryProvider: () async => sandbox,
        );

        final assetFile = File('${sandbox.path}/index.m3u8');
        await assetFile.writeAsString('#EXTM3U\n');

        final entry = DownloadEntry(
          id: 'series-2::ep-3::720p',
          seriesId: 'series-2',
          episodeId: 'ep-3',
          selectedQuality: '720p',
          status: DownloadStatus.completed,
          localAssetUri: assetFile.uri.toString(),
          storageDirectoryPath: '${sandbox.path}/downloads/series-2/ep-3/720p',
          createdAt: DateTime(2026, 2, 1),
          completedAt: DateTime(2026, 2, 2),
        );

        await store.writeAll({entry.id: entry.toJson()});

        final entries = await repository.getDownloads();
        final normalized = entries.single;

        expect(normalized.status, DownloadStatus.failed);
        expect(normalized.localAssetUri, isNull);
        expect(normalized.completedAt, isNull);
        expect(
          normalized.lastError,
          'Offline package directory is missing on device.',
        );
      },
    );

    test(
      'keeps completed entry playable when local asset and package directory are valid',
      () async {
        final sandbox = await Directory.systemTemp.createTemp(
          'anime_stream_downloads_valid_asset_',
        );
        addTearDown(() async {
          if (await sandbox.exists()) {
            await sandbox.delete(recursive: true);
          }
        });

        final store = JsonDownloadsStore(
          directoryProvider: () async => sandbox,
        );
        final repository = LocalDownloadsRepository(
          downloadsStore: store,
          remoteDataSource: _FakeAnilibriaRemoteDataSource(),
          dio: Dio(),
          downloadsRootDirectoryProvider: () async => sandbox,
        );

        final packageDir = Directory(
          '${sandbox.path}/downloads/series-3/ep-7/1080p',
        );
        await packageDir.create(recursive: true);

        final assetFile = File('${packageDir.path}/index.m3u8');
        await assetFile.writeAsString('#EXTM3U\n#EXT-X-ENDLIST\n');

        final entry = DownloadEntry(
          id: 'series-3::ep-7::1080p',
          seriesId: 'series-3',
          episodeId: 'ep-7',
          selectedQuality: '1080p',
          status: DownloadStatus.completed,
          localAssetUri: assetFile.uri.toString(),
          storageDirectoryPath: packageDir.path,
          createdAt: DateTime(2026, 3, 1),
          completedAt: DateTime(2026, 3, 2),
        );

        await store.writeAll({entry.id: entry.toJson()});

        final entries = await repository.getDownloads();
        final normalized = entries.single;

        expect(normalized.status, DownloadStatus.completed);
        expect(normalized.localAssetUri, assetFile.uri.toString());
        expect(normalized.isPlayableOffline, isTrue);

        final playable = await repository.getPlayableDownload(
          seriesId: 'series-3',
          episodeId: 'ep-7',
        );

        expect(playable, isNotNull);
        expect(playable!.id, entry.id);
      },
    );

    test(
      'demotes completed local-file entry with empty file payload',
      () async {
        final sandbox = await Directory.systemTemp.createTemp(
          'anime_stream_downloads_empty_file_',
        );
        addTearDown(() async {
          if (await sandbox.exists()) {
            await sandbox.delete(recursive: true);
          }
        });

        final store = JsonDownloadsStore(
          directoryProvider: () async => sandbox,
        );
        final repository = LocalDownloadsRepository(
          downloadsStore: store,
          remoteDataSource: _FakeAnilibriaRemoteDataSource(),
          dio: Dio(),
          downloadsRootDirectoryProvider: () async => sandbox,
        );

        final assetFile = File('${sandbox.path}/empty.mp4');
        await assetFile.writeAsBytes(const []);

        final entry = DownloadEntry(
          id: 'series-4::ep-2::local',
          seriesId: 'series-4',
          episodeId: 'ep-2',
          selectedQuality: '480p',
          status: DownloadStatus.completed,
          localAssetUri: assetFile.uri.toString(),
          sourceKind: DownloadSourceKind.localFile,
          createdAt: DateTime(2026, 4, 1),
          completedAt: DateTime(2026, 4, 2),
        );

        await store.writeAll({entry.id: entry.toJson()});

        final entries = await repository.getDownloads();
        final normalized = entries.single;

        expect(normalized.status, DownloadStatus.failed);
        expect(normalized.localAssetUri, isNull);
        expect(normalized.lastError, 'Offline asset is empty.');
      },
    );
  });
}

class _FakeAnilibriaRemoteDataSource implements AnilibriaRemoteDataSource {
  @override
  Future<List<AnilibriaReleaseDto>> fetchFeaturedReleases({int limit = 20}) {
    throw UnimplementedError();
  }

  @override
  Future<List<AnilibriaReleaseDto>> fetchTrendingReleases({int limit = 20}) {
    throw UnimplementedError();
  }

  @override
  Future<List<AnilibriaReleaseDto>> fetchPopularReleases({int limit = 20}) {
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
  Future<AnilibriaReleaseDto> fetchReleaseDetails(String releaseId) {
    throw UnimplementedError();
  }

  @override
  Future<List<AnilibriaEpisodeDto>> fetchReleaseEpisodes(String releaseId) {
    throw UnimplementedError();
  }

  @override
  Future<List<AnilibriaReleaseDto>> searchReleases(
    String query, {
    int limit = 20,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<AnilibriaReleaseDto>> fetchSimulcastReleases({int limit = 20}) {
    throw UnimplementedError();
  }
}
