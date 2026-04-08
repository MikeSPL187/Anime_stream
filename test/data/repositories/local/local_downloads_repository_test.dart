import 'dart:async';
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
        expect(normalized.failureKind, DownloadFailureKind.offlineAssetMissing);

        final persisted = await store.readAll();
        final persistedEntry = DownloadEntry.fromJson(
          Map<String, dynamic>.from(persisted[entry.id] as Map),
        );

        expect(persistedEntry.status, DownloadStatus.failed);
        expect(persistedEntry.localAssetUri, isNull);
        expect(persistedEntry.completedAt, isNull);
        expect(persistedEntry.lastError, 'Offline asset is missing on device.');
        expect(
          persistedEntry.failureKind,
          DownloadFailureKind.offlineAssetMissing,
        );
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
        expect(
          normalized.failureKind,
          DownloadFailureKind.offlinePackageMissing,
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
        final segmentFile = File('${packageDir.path}/asset_0001.ts');
        await segmentFile.writeAsBytes(const [1, 2, 3, 4]);
        await assetFile.writeAsString(
          '#EXTM3U\n#EXTINF:4.0,\nasset_0001.ts\n#EXT-X-ENDLIST\n',
        );

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
        expect(normalized.failureKind, isNull);

        final playable = await repository.getPlayableDownload(
          seriesId: 'series-3',
          episodeId: 'ep-7',
        );

        expect(playable, isNotNull);
        expect(playable!.id, entry.id);
      },
    );

    test(
      'packages nested HLS playlists recursively for offline playback',
      () async {
        final sandbox = await Directory.systemTemp.createTemp(
          'anime_stream_downloads_nested_manifest_',
        );
        addTearDown(() async {
          if (await sandbox.exists()) {
            await sandbox.delete(recursive: true);
          }
        });

        const masterPlaylistUrl =
            'https://cdn.example.com/series-12/master.m3u8';
        const variantPlaylistUrl =
            'https://cdn.example.com/series-12/variant_1080.m3u8';
        final release = AnilibriaReleaseDto(
          id: 'series-12',
          episodes: [
            const AnilibriaEpisodeDto(
              id: 'ep-9',
              releaseId: 'series-12',
              ordinal: 9,
              numberLabel: '9',
              title: 'Episode 9',
              hls1080Url: masterPlaylistUrl,
            ),
          ],
        );
        final dio = Dio()
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) {
                final uri = options.uri.toString();
                if (uri == masterPlaylistUrl) {
                  handler.resolve(
                    Response<String>(
                      requestOptions: options,
                      data:
                          '#EXTM3U\n#EXT-X-STREAM-INF:BANDWIDTH=2800000,RESOLUTION=1920x1080\nvariant_1080.m3u8\n',
                      statusCode: 200,
                    ),
                  );
                  return;
                }
                if (uri == variantPlaylistUrl) {
                  handler.resolve(
                    Response<String>(
                      requestOptions: options,
                      data:
                          '#EXTM3U\n#EXTINF:4.0,\nsegment_0001.ts\n#EXTINF:4.0,\nsegment_0002.ts\n#EXT-X-ENDLIST\n',
                      statusCode: 200,
                    ),
                  );
                  return;
                }
                if (uri ==
                    'https://cdn.example.com/series-12/segment_0001.ts') {
                  handler.resolve(
                    Response<List<int>>(
                      requestOptions: options,
                      data: const [1, 2, 3, 4],
                      statusCode: 200,
                    ),
                  );
                  return;
                }
                if (uri ==
                    'https://cdn.example.com/series-12/segment_0002.ts') {
                  handler.resolve(
                    Response<List<int>>(
                      requestOptions: options,
                      data: const [5, 6, 7, 8],
                      statusCode: 200,
                    ),
                  );
                  return;
                }

                handler.reject(
                  DioException(
                    requestOptions: options,
                    error: 'Unexpected request: $uri',
                  ),
                );
              },
            ),
          );

        final store = JsonDownloadsStore(
          directoryProvider: () async => sandbox,
        );
        final repository = LocalDownloadsRepository(
          downloadsStore: store,
          remoteDataSource: _FakeAnilibriaRemoteDataSource(
            releaseDetails: release,
          ),
          dio: dio,
          downloadsRootDirectoryProvider: () async => sandbox,
        );

        final completedEntry = await repository.startEpisodeDownload(
          seriesId: 'series-12',
          episodeId: 'ep-9',
          selectedQuality: '1080p',
        );

        expect(completedEntry.status, DownloadStatus.completed);

        final packageDir = Directory(
          '${sandbox.path}/downloads/series-12/ep-9/1080p',
        );
        final localMasterManifest = File('${packageDir.path}/index.m3u8');
        final localVariantManifest = File('${packageDir.path}/asset_0000.m3u8');
        final localSegmentOne = File('${packageDir.path}/asset_0001.ts');
        final localSegmentTwo = File('${packageDir.path}/asset_0002.ts');

        expect(await localMasterManifest.exists(), isTrue);
        expect(await localVariantManifest.exists(), isTrue);
        expect(await localSegmentOne.exists(), isTrue);
        expect(await localSegmentTwo.exists(), isTrue);

        final masterManifestBody = await localMasterManifest.readAsString();
        final variantManifestBody = await localVariantManifest.readAsString();
        expect(masterManifestBody, contains('asset_0000.m3u8'));
        expect(variantManifestBody, contains('asset_0001.ts'));
        expect(variantManifestBody, contains('asset_0002.ts'));

        final playable = await repository.getPlayableDownload(
          seriesId: 'series-12',
          episodeId: 'ep-9',
        );

        expect(playable, isNotNull);
        expect(playable!.status, DownloadStatus.completed);
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
        expect(
          normalized.failureKind,
          DownloadFailureKind.offlineAssetCorrupted,
        );
      },
    );

    test(
      'demotes completed HLS entry when packaged media asset is missing',
      () async {
        final sandbox = await Directory.systemTemp.createTemp(
          'anime_stream_downloads_missing_packaged_asset_',
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
          '${sandbox.path}/downloads/series-8/ep-4/1080p',
        );
        await packageDir.create(recursive: true);

        final manifestFile = File('${packageDir.path}/index.m3u8');
        await manifestFile.writeAsString(
          '#EXTM3U\n#EXTINF:4.0,\nasset_0001.ts\n#EXT-X-ENDLIST\n',
        );

        final entry = DownloadEntry(
          id: 'series-8::ep-4::1080p',
          seriesId: 'series-8',
          episodeId: 'ep-4',
          selectedQuality: '1080p',
          status: DownloadStatus.completed,
          localAssetUri: manifestFile.uri.toString(),
          storageDirectoryPath: packageDir.path,
          createdAt: DateTime(2026, 4, 3),
          completedAt: DateTime(2026, 4, 4),
        );

        await store.writeAll({entry.id: entry.toJson()});

        final entries = await repository.getDownloads();
        final normalized = entries.single;

        expect(normalized.status, DownloadStatus.failed);
        expect(normalized.localAssetUri, isNull);
        expect(
          normalized.lastError,
          'Offline package asset is missing on device.',
        );
        expect(
          normalized.failureKind,
          DownloadFailureKind.offlinePackageMissing,
        );
      },
    );

    test(
      'demotes completed HLS entry when nested manifest media asset is missing',
      () async {
        final sandbox = await Directory.systemTemp.createTemp(
          'anime_stream_downloads_nested_missing_asset_',
        );
        addTearDown(() async {
          if (await sandbox.exists()) {
            await sandbox.delete(recursive: true);
          }
        });

        final packageDir = Directory(
          '${sandbox.path}/downloads/series-13/ep-2/1080p',
        );
        await packageDir.create(recursive: true);

        final rootManifest = File('${packageDir.path}/index.m3u8');
        final variantManifest = File('${packageDir.path}/asset_0000.m3u8');
        await rootManifest.writeAsString(
          '#EXTM3U\n#EXT-X-STREAM-INF:BANDWIDTH=2800000\nasset_0000.m3u8\n',
        );
        await variantManifest.writeAsString(
          '#EXTM3U\n#EXTINF:4.0,\nasset_0001.ts\n#EXT-X-ENDLIST\n',
        );

        final store = JsonDownloadsStore(
          directoryProvider: () async => sandbox,
        );
        final repository = LocalDownloadsRepository(
          downloadsStore: store,
          remoteDataSource: _FakeAnilibriaRemoteDataSource(),
          dio: Dio(),
          downloadsRootDirectoryProvider: () async => sandbox,
        );

        const entryId = 'series-13::ep-2::1080p';
        await store.writeAll({
          entryId: DownloadEntry(
            id: entryId,
            seriesId: 'series-13',
            episodeId: 'ep-2',
            selectedQuality: '1080p',
            status: DownloadStatus.completed,
            localAssetUri: rootManifest.uri.toString(),
            storageDirectoryPath: packageDir.path,
            createdAt: DateTime(2026, 4, 6),
            completedAt: DateTime(2026, 4, 7),
          ).toJson(),
        });

        final entries = await repository.getDownloads();
        final normalized = entries.single;

        expect(normalized.status, DownloadStatus.failed);
        expect(normalized.localAssetUri, isNull);
        expect(
          normalized.lastError,
          'Offline package asset is missing on device.',
        );
        expect(
          normalized.failureKind,
          DownloadFailureKind.offlinePackageMissing,
        );
      },
    );

    test('demotes legacy queued entry into a restart-required failure', () async {
      final sandbox = await Directory.systemTemp.createTemp(
        'anime_stream_downloads_legacy_queue_',
      );
      addTearDown(() async {
        if (await sandbox.exists()) {
          await sandbox.delete(recursive: true);
        }
      });

      final store = JsonDownloadsStore(directoryProvider: () async => sandbox);
      final repository = LocalDownloadsRepository(
        downloadsStore: store,
        remoteDataSource: _FakeAnilibriaRemoteDataSource(),
        dio: Dio(),
        downloadsRootDirectoryProvider: () async => sandbox,
      );

      const entryId = 'series-queue::ep-2::1080p';
      await store.writeAll({
        entryId: const DownloadEntry(
          id: entryId,
          seriesId: 'series-queue',
          episodeId: 'ep-2',
          selectedQuality: '1080p',
          status: DownloadStatus.queued,
        ).toJson(),
      });

      final entries = await repository.getDownloads();
      final normalized = entries.single;

      expect(normalized.status, DownloadStatus.failed);
      expect(normalized.failureKind, DownloadFailureKind.transferInterrupted);
      expect(
        normalized.lastError,
        'Download was interrupted before completion. Start it again to save this episode offline.',
      );
    });

    test('demotes legacy paused entry into a restart-required failure', () async {
      final sandbox = await Directory.systemTemp.createTemp(
        'anime_stream_downloads_legacy_paused_',
      );
      addTearDown(() async {
        if (await sandbox.exists()) {
          await sandbox.delete(recursive: true);
        }
      });

      final store = JsonDownloadsStore(directoryProvider: () async => sandbox);
      final repository = LocalDownloadsRepository(
        downloadsStore: store,
        remoteDataSource: _FakeAnilibriaRemoteDataSource(),
        dio: Dio(),
        downloadsRootDirectoryProvider: () async => sandbox,
      );

      const entryId = 'series-paused::ep-5::720p';
      await store.writeAll({
        entryId: const DownloadEntry(
          id: entryId,
          seriesId: 'series-paused',
          episodeId: 'ep-5',
          selectedQuality: '720p',
          status: DownloadStatus.paused,
        ).toJson(),
      });

      final entries = await repository.getDownloads();
      final normalized = entries.single;

      expect(normalized.status, DownloadStatus.failed);
      expect(normalized.failureKind, DownloadFailureKind.transferInterrupted);
      expect(
        normalized.lastError,
        'Download was interrupted before completion. Start it again to save this episode offline.',
      );
    });

    test(
      'demotes stale downloading entry into a restart-required failure',
      () async {
        final sandbox = await Directory.systemTemp.createTemp(
          'anime_stream_downloads_stale_downloading_',
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

        const entryId = 'series-stale::ep-7::1080p';
        await store.writeAll({
          entryId: const DownloadEntry(
            id: entryId,
            seriesId: 'series-stale',
            episodeId: 'ep-7',
            selectedQuality: '1080p',
            status: DownloadStatus.downloading,
          ).toJson(),
        });

        final entries = await repository.getDownloads();
        final normalized = entries.single;

        expect(normalized.status, DownloadStatus.failed);
        expect(normalized.failureKind, DownloadFailureKind.transferInterrupted);
        expect(
          normalized.lastError,
          'Download was interrupted before completion. Start it again to save this episode offline.',
        );
      },
    );

    test(
      'keeps a foreground download active while the transfer is still running',
      () async {
        final sandbox = await Directory.systemTemp.createTemp(
          'anime_stream_downloads_active_transfer_',
        );
        addTearDown(() async {
          if (await sandbox.exists()) {
            await sandbox.delete(recursive: true);
          }
        });

        const playlistUrl = 'https://cdn.example.com/series-11/ep-3.m3u8';
        final remoteDataSource = _CompletingAnilibriaRemoteDataSource();
        final dio = Dio()
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) {
                final uri = options.uri.toString();
                if (uri == playlistUrl) {
                  handler.resolve(
                    Response<String>(
                      requestOptions: options,
                      data:
                          '#EXTM3U\n#EXTINF:4.0,\nsegment_0001.ts\n#EXT-X-ENDLIST\n',
                      statusCode: 200,
                    ),
                  );
                  return;
                }
                if (uri ==
                    'https://cdn.example.com/series-11/segment_0001.ts') {
                  handler.resolve(
                    Response<List<int>>(
                      requestOptions: options,
                      data: const [1, 2, 3, 4],
                      statusCode: 200,
                    ),
                  );
                  return;
                }

                handler.reject(
                  DioException(
                    requestOptions: options,
                    error: 'Unexpected request: $uri',
                  ),
                );
              },
            ),
          );

        final store = JsonDownloadsStore(
          directoryProvider: () async => sandbox,
        );
        final repository = LocalDownloadsRepository(
          downloadsStore: store,
          remoteDataSource: remoteDataSource,
          dio: dio,
          downloadsRootDirectoryProvider: () async => sandbox,
        );

        final downloadFuture = repository.startEpisodeDownload(
          seriesId: 'series-11',
          episodeId: 'ep-3',
          selectedQuality: '1080p',
        );

        await remoteDataSource.requestStarted.future;

        final activeEntries = await repository.getDownloads();
        expect(activeEntries.single.status, DownloadStatus.downloading);
        expect(activeEntries.single.hasActiveTransfer, isTrue);

        remoteDataSource.complete(
          const AnilibriaReleaseDto(
            id: 'series-11',
            episodes: [
              AnilibriaEpisodeDto(
                id: 'ep-3',
                releaseId: 'series-11',
                ordinal: 3,
                numberLabel: '3',
                title: 'Episode 3',
                hls1080Url: playlistUrl,
              ),
            ],
          ),
        );

        final completedEntry = await downloadFuture;
        expect(completedEntry.status, DownloadStatus.completed);
      },
    );

    test(
      'keeps unmanaged directory on disk when removing stored entry',
      () async {
        final sandbox = await Directory.systemTemp.createTemp(
          'anime_stream_downloads_remove_guard_',
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

        final unmanagedDirectory = Directory('${sandbox.path}/outside/unsafe');
        await unmanagedDirectory.create(recursive: true);
        await File(
          '${unmanagedDirectory.path}/payload.txt',
        ).writeAsString('keep me');

        const entryId = 'series-9::ep-1::1080p';
        await store.writeAll({
          entryId: DownloadEntry(
            id: entryId,
            seriesId: 'series-9',
            episodeId: 'ep-1',
            selectedQuality: '1080p',
            status: DownloadStatus.completed,
            localAssetUri: Uri.file(
              '${unmanagedDirectory.path}/payload.txt',
            ).toString(),
            storageDirectoryPath: unmanagedDirectory.path,
            completedAt: DateTime(2026, 4, 5),
          ).toJson(),
        });

        await repository.removeDownload(entryId);

        expect(await unmanagedDirectory.exists(), isTrue);
        expect((await store.readAll()).containsKey(entryId), isFalse);
      },
    );

    test(
      'cleans partial package directory when episode download fails mid-transfer',
      () async {
        final sandbox = await Directory.systemTemp.createTemp(
          'anime_stream_downloads_partial_cleanup_',
        );
        addTearDown(() async {
          if (await sandbox.exists()) {
            await sandbox.delete(recursive: true);
          }
        });

        final playlistUrl = 'https://cdn.example.com/series-10/ep-6.m3u8';
        final release = AnilibriaReleaseDto(
          id: 'series-10',
          episodes: [
            AnilibriaEpisodeDto(
              id: 'ep-6',
              releaseId: 'series-10',
              ordinal: 6,
              numberLabel: '6',
              title: 'Episode 6',
              hls1080Url: playlistUrl,
            ),
          ],
        );
        final dio = Dio()
          ..interceptors.add(
            InterceptorsWrapper(
              onRequest: (options, handler) {
                final uri = options.uri.toString();
                if (uri == playlistUrl) {
                  handler.resolve(
                    Response<String>(
                      requestOptions: options,
                      data:
                          '#EXTM3U\n#EXTINF:4.0,\nsegment_0001.ts\n#EXTINF:4.0,\nsegment_0002.ts\n#EXT-X-ENDLIST\n',
                      statusCode: 200,
                    ),
                  );
                  return;
                }
                if (uri ==
                    'https://cdn.example.com/series-10/segment_0001.ts') {
                  handler.resolve(
                    Response<List<int>>(
                      requestOptions: options,
                      data: const [1, 2, 3, 4],
                      statusCode: 200,
                    ),
                  );
                  return;
                }
                if (uri ==
                    'https://cdn.example.com/series-10/segment_0002.ts') {
                  handler.reject(
                    DioException(
                      requestOptions: options,
                      error: 'segment fetch failed',
                    ),
                  );
                  return;
                }

                handler.reject(
                  DioException(
                    requestOptions: options,
                    error: 'Unexpected request: $uri',
                  ),
                );
              },
            ),
          );

        final store = JsonDownloadsStore(
          directoryProvider: () async => sandbox,
        );
        final repository = LocalDownloadsRepository(
          downloadsStore: store,
          remoteDataSource: _FakeAnilibriaRemoteDataSource(
            releaseDetails: release,
          ),
          dio: dio,
          downloadsRootDirectoryProvider: () async => sandbox,
        );

        await expectLater(
          repository.startEpisodeDownload(
            seriesId: 'series-10',
            episodeId: 'ep-6',
            selectedQuality: '1080p',
          ),
          throwsA(isA<DioException>()),
        );

        final packageDir = Directory(
          '${sandbox.path}/downloads/series-10/ep-6/1080p',
        );
        expect(await packageDir.exists(), isFalse);

        final persisted = await store.readAll();
        final persistedEntry = DownloadEntry.fromJson(
          Map<String, dynamic>.from(
            persisted['series-10::ep-6::1080p'] as Map<String, dynamic>,
          ),
        );
        expect(persistedEntry.status, DownloadStatus.failed);
        expect(persistedEntry.failureKind, DownloadFailureKind.transferFailed);
      },
    );
  });
}

class _FakeAnilibriaRemoteDataSource implements AnilibriaRemoteDataSource {
  const _FakeAnilibriaRemoteDataSource({this.releaseDetails});

  final AnilibriaReleaseDto? releaseDetails;

  @override
  Future<List<AnilibriaReleaseDto>> fetchLatestReleases({int limit = 20}) {
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
  Future<AnilibriaReleaseDto> fetchReleaseDetails(String releaseId) async {
    if (releaseDetails == null) {
      throw UnimplementedError();
    }
    return releaseDetails!;
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

class _CompletingAnilibriaRemoteDataSource
    implements AnilibriaRemoteDataSource {
  final Completer<void> requestStarted = Completer<void>();
  final Completer<AnilibriaReleaseDto> _releaseCompleter =
      Completer<AnilibriaReleaseDto>();

  void complete(AnilibriaReleaseDto release) {
    if (!_releaseCompleter.isCompleted) {
      _releaseCompleter.complete(release);
    }
  }

  @override
  Future<List<AnilibriaReleaseDto>> fetchLatestReleases({int limit = 20}) {
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
  Future<AnilibriaReleaseDto> fetchReleaseDetails(String releaseId) async {
    if (!requestStarted.isCompleted) {
      requestStarted.complete();
    }
    return _releaseCompleter.future;
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
