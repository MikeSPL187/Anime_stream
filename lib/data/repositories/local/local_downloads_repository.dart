import 'dart:io';

import 'package:dio/dio.dart';

import '../../../data/adapters/anilibria/anilibria_remote_data_source.dart';
import '../../local/json_downloads_store.dart';
import '../../../data/dto/anilibria/anilibria_episode_dto.dart';
import '../../../domain/models/download_entry.dart';
import '../../../domain/repositories/downloads_repository.dart';

class LocalDownloadsRepository implements DownloadsRepository {
  LocalDownloadsRepository({
    required JsonDownloadsStore downloadsStore,
    required AnilibriaRemoteDataSource remoteDataSource,
    required Dio dio,
    required Future<Directory> Function() downloadsRootDirectoryProvider,
  }) : _downloadsStore = downloadsStore,
       _remoteDataSource = remoteDataSource,
       _dio = dio,
       _downloadsRootDirectoryProvider = downloadsRootDirectoryProvider;

  final JsonDownloadsStore _downloadsStore;
  final AnilibriaRemoteDataSource _remoteDataSource;
  final Dio _dio;
  final Future<Directory> Function() _downloadsRootDirectoryProvider;

  @override
  Future<List<DownloadEntry>> getDownloads() async {
    return _readEntries();
  }

  @override
  Future<DownloadEntry?> getPlayableDownload({
    required String seriesId,
    required String episodeId,
  }) async {
    final matchingEntries = (await _readEntries())
        .where(
          (entry) =>
              entry.seriesId == seriesId &&
              entry.episodeId == episodeId &&
              entry.isPlayableOffline,
        )
        .toList(growable: false);

    if (matchingEntries.isEmpty) {
      return null;
    }

    matchingEntries.sort((left, right) {
      final leftCompletedAt = left.completedAt ??
          left.createdAt ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final rightCompletedAt = right.completedAt ??
          right.createdAt ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return rightCompletedAt.compareTo(leftCompletedAt);
    });

    return matchingEntries.first;
  }

  @override
  Future<void> queueEpisodeDownload({
    required String seriesId,
    required String episodeId,
    String selectedQuality = '1080p',
  }) async {
    final storedEntries = Map<String, dynamic>.from(
      await _downloadsStore.readAll(),
    );
    final key = _buildKey(
      seriesId: seriesId,
      episodeId: episodeId,
      selectedQuality: selectedQuality,
    );

    final existingPayload = storedEntries[key];
    final existingEntry = existingPayload is Map
        ? DownloadEntry.fromJson(Map<String, dynamic>.from(existingPayload))
        : null;

    if (existingEntry?.isPlayableOffline == true) {
      return;
    }

    final queuedEntry = DownloadEntry(
      id: key,
      seriesId: seriesId,
      episodeId: episodeId,
      selectedQuality: selectedQuality,
      status: DownloadStatus.queued,
      createdAt: existingEntry?.createdAt ?? DateTime.now(),
      sourceKind: DownloadSourceKind.localHlsManifest,
    );

    storedEntries[key] = queuedEntry.toJson();
    await _downloadsStore.writeAll(storedEntries);
  }

  @override
  Future<DownloadEntry> startEpisodeDownload({
    required String seriesId,
    required String episodeId,
    String selectedQuality = '1080p',
  }) async {
    final baseEntry = DownloadEntry(
      id: _buildKey(
        seriesId: seriesId,
        episodeId: episodeId,
        selectedQuality: selectedQuality,
      ),
      seriesId: seriesId,
      episodeId: episodeId,
      selectedQuality: selectedQuality,
      status: DownloadStatus.downloading,
      createdAt: DateTime.now(),
      sourceKind: DownloadSourceKind.localHlsManifest,
    );
    await _writeEntry(baseEntry);

    try {
      final release = await _remoteDataSource.fetchReleaseDetails(seriesId);
      final episode = _findEpisode(release.episodes, episodeId: episodeId);
      if (episode == null) {
        throw const EpisodeDownloadExecutionException(
          'The requested episode could not be resolved for download.',
        );
      }

      final resolvedStream = _pickPreferredStream(
        episode,
        requestedQuality: selectedQuality,
      );
      if (resolvedStream == null) {
        throw EpisodeDownloadExecutionException(
          'No supported HLS stream is available for quality $selectedQuality.',
        );
      }

      final assetDirectory = await _resolveAssetDirectory(
        seriesId: seriesId,
        episodeId: episodeId,
        qualityLabel: resolvedStream.qualityLabel,
      );
      await assetDirectory.create(recursive: true);

      final packagedAsset = await _downloadAndPackageHlsVod(
        playlistUrl: resolvedStream.streamUri,
        assetDirectory: assetDirectory,
      );

      final completedEntry = baseEntry.copyWith(
        id: _buildKey(
          seriesId: seriesId,
          episodeId: episodeId,
          selectedQuality: resolvedStream.qualityLabel,
        ),
        selectedQuality: resolvedStream.qualityLabel,
        status: DownloadStatus.completed,
        bytesDownloaded: packagedAsset.bytesDownloaded,
        totalBytes: packagedAsset.bytesDownloaded,
        localAssetUri: packagedAsset.localManifestUri.toString(),
        storageDirectoryPath: assetDirectory.path,
        completedAt: DateTime.now(),
        lastError: null,
        sourceKind: DownloadSourceKind.localHlsManifest,
      );

      await _writeEntry(completedEntry, removeKey: baseEntry.id);
      return completedEntry;
    } catch (error) {
      final failedEntry = baseEntry.copyWith(
        status: DownloadStatus.failed,
        lastError: error.toString(),
      );
      await _writeEntry(failedEntry);
      rethrow;
    }
  }

  @override
  Future<void> pauseDownload(String downloadId) async {
    final storedEntries = Map<String, dynamic>.from(
      await _downloadsStore.readAll(),
    );
    final payload = storedEntries[downloadId];
    if (payload is! Map) {
      return;
    }

    final entry = DownloadEntry.fromJson(Map<String, dynamic>.from(payload));
    if (entry.status != DownloadStatus.downloading &&
        entry.status != DownloadStatus.queued) {
      return;
    }

    storedEntries[downloadId] = entry
        .copyWith(status: DownloadStatus.paused)
        .toJson();
    await _downloadsStore.writeAll(storedEntries);
  }

  @override
  Future<void> removeDownload(String downloadId) async {
    final storedEntries = Map<String, dynamic>.from(
      await _downloadsStore.readAll(),
    );
    final payload = storedEntries.remove(downloadId);
    if (payload is Map) {
      final entry = DownloadEntry.fromJson(Map<String, dynamic>.from(payload));
      final storageDirectoryPath = entry.storageDirectoryPath?.trim();
      if (storageDirectoryPath != null && storageDirectoryPath.isNotEmpty) {
        final directory = Directory(storageDirectoryPath);
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      }
    }

    await _downloadsStore.writeAll(storedEntries);
  }

  Future<void> _writeEntry(
    DownloadEntry entry, {
    String? removeKey,
  }) async {
    final storedEntries = Map<String, dynamic>.from(
      await _downloadsStore.readAll(),
    );
    if (removeKey != null && removeKey != entry.id) {
      storedEntries.remove(removeKey);
    }
    storedEntries[entry.id] = entry.toJson();
    await _downloadsStore.writeAll(storedEntries);
  }

  Future<_PackagedHlsAsset> _downloadAndPackageHlsVod({
    required String playlistUrl,
    required Directory assetDirectory,
  }) async {
    final playlistUri = Uri.parse(playlistUrl);
    final playlistResponse = await _dio.get<String>(
      playlistUrl,
      options: Options(responseType: ResponseType.plain),
    );
    final playlistBody = playlistResponse.data;
    if (playlistBody == null || playlistBody.trim().isEmpty) {
      throw const EpisodeDownloadExecutionException(
        'The HLS playlist could not be downloaded.',
      );
    }

    var bytesDownloaded = 0;
    var assetIndex = 0;
    final rewrittenLines = <String>[];

    for (final rawLine in playlistBody.split('\n')) {
      final trimmedLine = rawLine.trim();
      if (trimmedLine.isEmpty) {
        rewrittenLines.add(rawLine);
        continue;
      }

      if (!trimmedLine.startsWith('#')) {
        final packagedAsset = await _downloadAssetReference(
          reference: trimmedLine,
          baseUri: playlistUri,
          assetDirectory: assetDirectory,
          assetIndex: assetIndex,
        );
        assetIndex += 1;
        bytesDownloaded += packagedAsset.bytesDownloaded;
        rewrittenLines.add(packagedAsset.rewrittenLine);
        continue;
      }

      final rewrittenTag = await _rewriteTaggedUriLine(
        rawLine: rawLine,
        baseUri: playlistUri,
        assetDirectory: assetDirectory,
        assetIndex: assetIndex,
      );
      if (rewrittenTag == null) {
        rewrittenLines.add(rawLine);
        continue;
      }

      assetIndex += 1;
      bytesDownloaded += rewrittenTag.bytesDownloaded;
      rewrittenLines.add(rewrittenTag.rewrittenLine);
    }

    final localManifestFile = File('${assetDirectory.path}/index.m3u8');
    await localManifestFile.writeAsString(rewrittenLines.join('\n'));

    return _PackagedHlsAsset(
      localManifestUri: Uri.file(localManifestFile.path),
      bytesDownloaded: bytesDownloaded,
    );
  }

  Future<_PackagedAssetReference?> _rewriteTaggedUriLine({
    required String rawLine,
    required Uri baseUri,
    required Directory assetDirectory,
    required int assetIndex,
  }) async {
    final uriMatch = RegExp(r'URI="([^"]+)"').firstMatch(rawLine);
    if (uriMatch == null) {
      return null;
    }

    final reference = uriMatch.group(1);
    if (reference == null || reference.trim().isEmpty) {
      return null;
    }

    final packagedAsset = await _downloadAssetReference(
      reference: reference,
      baseUri: baseUri,
      assetDirectory: assetDirectory,
      assetIndex: assetIndex,
    );

    final rewrittenLine = rawLine.replaceFirst(
      'URI="$reference"',
      'URI="${packagedAsset.rewrittenLine}"',
    );

    return _PackagedAssetReference(
      rewrittenLine: rewrittenLine,
      bytesDownloaded: packagedAsset.bytesDownloaded,
    );
  }

  Future<_PackagedAssetReference> _downloadAssetReference({
    required String reference,
    required Uri baseUri,
    required Directory assetDirectory,
    required int assetIndex,
  }) async {
    final assetUri = baseUri.resolve(reference);
    final assetResponse = await _dio.get<List<int>>(
      assetUri.toString(),
      options: Options(responseType: ResponseType.bytes),
    );
    final assetBytes = assetResponse.data;
    if (assetBytes == null) {
      throw EpisodeDownloadExecutionException(
        'Failed to download media asset $reference.',
      );
    }

    final extension = _resolveFileExtension(assetUri.path);
    final localFileName = 'asset_${assetIndex.toString().padLeft(4, '0')}$extension';
    final localFile = File('${assetDirectory.path}/$localFileName');
    await localFile.writeAsBytes(assetBytes);

    return _PackagedAssetReference(
      rewrittenLine: localFileName,
      bytesDownloaded: assetBytes.length,
    );
  }

  String _resolveFileExtension(String path) {
    final lastDotIndex = path.lastIndexOf('.');
    if (lastDotIndex == -1) {
      return '.bin';
    }

    final extension = path.substring(lastDotIndex);
    if (extension.contains('/')) {
      return '.bin';
    }

    return extension;
  }

  _ResolvedStreamCandidate? _pickPreferredStream(
    AnilibriaEpisodeDto episode, {
    required String requestedQuality,
  }) {
    final normalizedQuality = requestedQuality.trim().toLowerCase();
    final orderedCandidates = switch (normalizedQuality) {
      '1080p' => const [
          ('1080p', 'hls1080Url'),
          ('720p', 'hls720Url'),
          ('480p', 'hls480Url'),
        ],
      '720p' => const [
          ('720p', 'hls720Url'),
          ('480p', 'hls480Url'),
        ],
      '480p' => const [
          ('480p', 'hls480Url'),
        ],
      _ => const [
          ('1080p', 'hls1080Url'),
          ('720p', 'hls720Url'),
          ('480p', 'hls480Url'),
        ],
    };

    for (final (qualityLabel, key) in orderedCandidates) {
      final streamUri = switch (key) {
        'hls1080Url' => episode.hls1080Url,
        'hls720Url' => episode.hls720Url,
        'hls480Url' => episode.hls480Url,
        _ => null,
      };
      if (streamUri != null && streamUri.trim().isNotEmpty) {
        return _ResolvedStreamCandidate(
          qualityLabel: qualityLabel,
          streamUri: streamUri,
        );
      }
    }

    return null;
  }

  AnilibriaEpisodeDto? _findEpisode(
    List<AnilibriaEpisodeDto> episodes, {
    required String episodeId,
  }) {
    for (final episode in episodes) {
      if (episode.id == episodeId) {
        return episode;
      }
    }

    return null;
  }

  Future<Directory> _resolveAssetDirectory({
    required String seriesId,
    required String episodeId,
    required String qualityLabel,
  }) async {
    final rootDirectory = await _downloadsRootDirectoryProvider();
    return Directory(
      '${rootDirectory.path}/downloads/$seriesId/$episodeId/$qualityLabel',
    );
  }

  String _buildKey({
    required String seriesId,
    required String episodeId,
    required String selectedQuality,
  }) {
    return '$seriesId::$episodeId::$selectedQuality';
  }

  Future<List<DownloadEntry>> _readEntries() async {
    final storedEntries = await _downloadsStore.readAll();
    final entries = <DownloadEntry>[];

    for (final payload in storedEntries.values) {
      if (payload is! Map) {
        continue;
      }

      entries.add(DownloadEntry.fromJson(Map<String, dynamic>.from(payload)));
    }

    entries.sort((left, right) {
      final leftCreatedAt =
          left.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final rightCreatedAt =
          right.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return rightCreatedAt.compareTo(leftCreatedAt);
    });

    return List.unmodifiable(entries);
  }
}

class EpisodeDownloadExecutionException implements Exception {
  const EpisodeDownloadExecutionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class _ResolvedStreamCandidate {
  const _ResolvedStreamCandidate({
    required this.qualityLabel,
    required this.streamUri,
  });

  final String qualityLabel;
  final String streamUri;
}

class _PackagedHlsAsset {
  const _PackagedHlsAsset({
    required this.localManifestUri,
    required this.bytesDownloaded,
  });

  final Uri localManifestUri;
  final int bytesDownloaded;
}

class _PackagedAssetReference {
  const _PackagedAssetReference({
    required this.rewrittenLine,
    required this.bytesDownloaded,
  });

  final String rewrittenLine;
  final int bytesDownloaded;
}
