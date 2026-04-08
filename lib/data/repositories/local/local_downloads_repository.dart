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
  final Set<String> _activeDownloadIds = <String>{};

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
      final leftCompletedAt =
          left.completedAt ??
          left.createdAt ??
          DateTime.fromMillisecondsSinceEpoch(0);
      final rightCompletedAt =
          right.completedAt ??
          right.createdAt ??
          DateTime.fromMillisecondsSinceEpoch(0);
      return rightCompletedAt.compareTo(leftCompletedAt);
    });

    return matchingEntries.first;
  }

  @override
  Future<DownloadEntry> startEpisodeDownload({
    required String seriesId,
    required String episodeId,
    String selectedQuality = '1080p',
    String? seriesTitle,
    String? episodeNumberLabel,
    String? episodeTitle,
  }) async {
    Directory? assetDirectory;
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
      seriesTitle: seriesTitle,
      episodeNumberLabel: episodeNumberLabel,
      episodeTitle: episodeTitle,
      createdAt: DateTime.now(),
      sourceKind: DownloadSourceKind.localHlsManifest,
    );
    _activeDownloadIds.add(baseEntry.id);
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

      assetDirectory = await _resolveAssetDirectory(
        seriesId: seriesId,
        episodeId: episodeId,
        qualityLabel: resolvedStream.qualityLabel,
      );
      await assetDirectory.create(recursive: true);

      final packagedAsset = await _downloadAndPackageHlsVod(
        playlistUrl: resolvedStream.streamUri,
        assetDirectory: assetDirectory,
      );

      final completedEntry = DownloadEntry(
        id: _buildKey(
          seriesId: seriesId,
          episodeId: episodeId,
          selectedQuality: resolvedStream.qualityLabel,
        ),
        seriesId: seriesId,
        episodeId: episodeId,
        selectedQuality: resolvedStream.qualityLabel,
        status: DownloadStatus.completed,
        seriesTitle: seriesTitle,
        episodeNumberLabel: episodeNumberLabel,
        episodeTitle: episodeTitle,
        bytesDownloaded: packagedAsset.bytesDownloaded,
        totalBytes: packagedAsset.bytesDownloaded,
        localAssetUri: packagedAsset.localManifestUri.toString(),
        storageDirectoryPath: assetDirectory.path,
        createdAt: baseEntry.createdAt,
        completedAt: DateTime.now(),
        lastError: null,
        sourceKind: DownloadSourceKind.localHlsManifest,
      );

      await _writeEntry(completedEntry, removeKey: baseEntry.id);
      return completedEntry;
    } catch (error) {
      await _deleteManagedDirectoryIfPresent(assetDirectory);
      final failedEntry = baseEntry.copyWith(
        status: DownloadStatus.failed,
        lastError: error.toString(),
        failureKind: DownloadFailureKind.transferFailed,
      );
      await _writeEntry(failedEntry);
      rethrow;
    } finally {
      _activeDownloadIds.remove(baseEntry.id);
    }
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
        await _deleteManagedDirectoryIfPresent(Directory(storageDirectoryPath));
      }
    }

    await _downloadsStore.writeAll(storedEntries);
  }

  Future<void> _writeEntry(DownloadEntry entry, {String? removeKey}) async {
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
    return _packageHlsManifest(
      manifestUri: Uri.parse(playlistUrl),
      assetDirectory: assetDirectory,
      localFileName: 'index.m3u8',
      packagingState: _OfflineManifestPackagingState(),
      activeManifestUris: <String>{},
    );
  }

  Future<_PackagedHlsAsset> _packageHlsManifest({
    required Uri manifestUri,
    required Directory assetDirectory,
    required String localFileName,
    required _OfflineManifestPackagingState packagingState,
    required Set<String> activeManifestUris,
  }) async {
    final manifestKey = manifestUri.toString();
    if (!activeManifestUris.add(manifestKey)) {
      throw const EpisodeDownloadExecutionException(
        'The HLS playlist contains a manifest loop.',
      );
    }

    try {
      final playlistResponse = await _dio.get<String>(
        manifestUri.toString(),
        options: Options(responseType: ResponseType.plain),
      );
      final playlistBody = playlistResponse.data;
      if (playlistBody == null || playlistBody.trim().isEmpty) {
        throw const EpisodeDownloadExecutionException(
          'The HLS playlist could not be downloaded.',
        );
      }

      var bytesDownloaded = 0;
      final rewrittenLines = <String>[];

      for (final rawLine in playlistBody.split('\n')) {
        final trimmedLine = rawLine.trim();
        if (trimmedLine.isEmpty) {
          rewrittenLines.add(rawLine);
          continue;
        }

        if (!trimmedLine.startsWith('#')) {
          final packagedAsset = await _packageResolvedReference(
            reference: trimmedLine,
            baseUri: manifestUri,
            assetDirectory: assetDirectory,
            packagingState: packagingState,
            activeManifestUris: activeManifestUris,
          );
          bytesDownloaded += packagedAsset.bytesDownloaded;
          rewrittenLines.add(packagedAsset.rewrittenLine);
          continue;
        }

        final rewrittenTag = await _rewriteTaggedUriLine(
          rawLine: rawLine,
          baseUri: manifestUri,
          assetDirectory: assetDirectory,
          packagingState: packagingState,
          activeManifestUris: activeManifestUris,
        );
        if (rewrittenTag == null) {
          rewrittenLines.add(rawLine);
          continue;
        }

        bytesDownloaded += rewrittenTag.bytesDownloaded;
        rewrittenLines.add(rewrittenTag.rewrittenLine);
      }

      final localManifestFile = File('${assetDirectory.path}/$localFileName');
      await localManifestFile.writeAsString(rewrittenLines.join('\n'));

      return _PackagedHlsAsset(
        localManifestUri: Uri.file(localManifestFile.path),
        bytesDownloaded: bytesDownloaded,
      );
    } finally {
      activeManifestUris.remove(manifestKey);
    }
  }

  Future<_PackagedAssetReference?> _rewriteTaggedUriLine({
    required String rawLine,
    required Uri baseUri,
    required Directory assetDirectory,
    required _OfflineManifestPackagingState packagingState,
    required Set<String> activeManifestUris,
  }) async {
    final uriMatch = RegExp(r'URI="([^"]+)"').firstMatch(rawLine);
    if (uriMatch == null) {
      return null;
    }

    final reference = uriMatch.group(1);
    if (reference == null || reference.trim().isEmpty) {
      return null;
    }

    final packagedAsset = await _packageResolvedReference(
      reference: reference,
      baseUri: baseUri,
      assetDirectory: assetDirectory,
      packagingState: packagingState,
      activeManifestUris: activeManifestUris,
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

  Future<_PackagedAssetReference> _packageResolvedReference({
    required String reference,
    required Uri baseUri,
    required Directory assetDirectory,
    required _OfflineManifestPackagingState packagingState,
    required Set<String> activeManifestUris,
  }) async {
    final assetUri = baseUri.resolve(reference);
    if (_isHlsManifestUri(assetUri)) {
      final localFileName = packagingState.nextLocalFileName('.m3u8');
      final packagedManifest = await _packageHlsManifest(
        manifestUri: assetUri,
        assetDirectory: assetDirectory,
        localFileName: localFileName,
        packagingState: packagingState,
        activeManifestUris: activeManifestUris,
      );
      return _PackagedAssetReference(
        rewrittenLine: localFileName,
        bytesDownloaded: packagedManifest.bytesDownloaded,
      );
    }

    return _downloadResolvedAssetReference(
      reference: reference,
      assetUri: assetUri,
      assetDirectory: assetDirectory,
      localFileName: packagingState.nextLocalFileName(
        _resolveFileExtension(assetUri.path),
      ),
    );
  }

  Future<_PackagedAssetReference> _downloadResolvedAssetReference({
    required String reference,
    required Uri assetUri,
    required Directory assetDirectory,
    required String localFileName,
  }) async {
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

    final localFile = File('${assetDirectory.path}/$localFileName');
    await localFile.writeAsBytes(assetBytes);

    return _PackagedAssetReference(
      rewrittenLine: localFileName,
      bytesDownloaded: assetBytes.length,
    );
  }

  bool _isHlsManifestUri(Uri uri) {
    return uri.path.toLowerCase().endsWith('.m3u8');
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
      '720p' => const [('720p', 'hls720Url'), ('480p', 'hls480Url')],
      '480p' => const [('480p', 'hls480Url')],
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
    final storedEntries = Map<String, dynamic>.from(
      await _downloadsStore.readAll(),
    );
    final entries = <DownloadEntry>[];
    var didMutateStore = false;

    for (final record in storedEntries.entries.toList(growable: false)) {
      final payload = record.value;
      if (payload is! Map) {
        continue;
      }

      final entry = DownloadEntry.fromJson(Map<String, dynamic>.from(payload));
      final normalizedEntry = await _normalizeStoredEntry(entry);
      if (normalizedEntry.changed) {
        storedEntries[record.key] = normalizedEntry.entry.toJson();
        didMutateStore = true;
      }

      entries.add(normalizedEntry.entry);
    }

    if (didMutateStore) {
      await _downloadsStore.writeAll(storedEntries);
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

  Future<_NormalizedDownloadEntry> _normalizeStoredEntry(
    DownloadEntry entry,
  ) async {
    if (entry.status == DownloadStatus.queued ||
        entry.status == DownloadStatus.paused) {
      return _NormalizedDownloadEntry(
        entry: _buildStaleFailureEntry(
          entry,
          'Download was interrupted before completion. Start it again to save this episode offline.',
          DownloadFailureKind.transferInterrupted,
        ),
        changed: true,
      );
    }

    if (entry.status == DownloadStatus.downloading &&
        !_activeDownloadIds.contains(entry.id)) {
      return _NormalizedDownloadEntry(
        entry: _buildStaleFailureEntry(
          entry,
          'Download was interrupted before completion. Start it again to save this episode offline.',
          DownloadFailureKind.transferInterrupted,
        ),
        changed: true,
      );
    }

    if (!entry.isPlayableOffline) {
      return _NormalizedDownloadEntry(entry: entry, changed: false);
    }

    final assetUriValue = entry.localAssetUri?.trim();
    if (assetUriValue == null || assetUriValue.isEmpty) {
      return _NormalizedDownloadEntry(
        entry: _buildStaleFailureEntry(
          entry,
          'Offline asset reference is missing.',
          DownloadFailureKind.offlineAssetInvalid,
        ),
        changed: true,
      );
    }

    final assetUri = Uri.tryParse(assetUriValue);
    if (assetUri == null || assetUri.scheme != 'file') {
      return _NormalizedDownloadEntry(
        entry: _buildStaleFailureEntry(
          entry,
          'Offline asset reference is invalid.',
          DownloadFailureKind.offlineAssetInvalid,
        ),
        changed: true,
      );
    }

    final assetFile = File.fromUri(assetUri);
    if (!await assetFile.exists()) {
      return _NormalizedDownloadEntry(
        entry: _buildStaleFailureEntry(
          entry,
          'Offline asset is missing on device.',
          DownloadFailureKind.offlineAssetMissing,
        ),
        changed: true,
      );
    }

    try {
      final fileLength = await assetFile.length();
      if (fileLength <= 0) {
        return _NormalizedDownloadEntry(
          entry: _buildStaleFailureEntry(
            entry,
            'Offline asset is empty.',
            DownloadFailureKind.offlineAssetCorrupted,
          ),
          changed: true,
        );
      }
    } on FileSystemException {
      return _NormalizedDownloadEntry(
        entry: _buildStaleFailureEntry(
          entry,
          'Offline asset could not be inspected.',
          DownloadFailureKind.offlineAssetCorrupted,
        ),
        changed: true,
      );
    }

    if (entry.sourceKind == DownloadSourceKind.localHlsManifest) {
      final storageDirectoryPath = entry.storageDirectoryPath?.trim();
      if (storageDirectoryPath == null || storageDirectoryPath.isEmpty) {
        return _NormalizedDownloadEntry(
          entry: _buildStaleFailureEntry(
            entry,
            'Offline package directory is missing.',
            DownloadFailureKind.offlinePackageMissing,
          ),
          changed: true,
        );
      }

      final assetDirectory = Directory(storageDirectoryPath);
      if (!await assetDirectory.exists()) {
        return _NormalizedDownloadEntry(
          entry: _buildStaleFailureEntry(
            entry,
            'Offline package directory is missing on device.',
            DownloadFailureKind.offlinePackageMissing,
          ),
          changed: true,
        );
      }

      if (!_isPathWithinDirectory(
        candidatePath: assetFile.path,
        directory: assetDirectory,
      )) {
        return _NormalizedDownloadEntry(
          entry: _buildStaleFailureEntry(
            entry,
            'Offline package manifest is outside the download directory.',
            DownloadFailureKind.offlinePackageCorrupted,
          ),
          changed: true,
        );
      }

      final packageValidationFailure = await _validatePackagedHlsManifest(
        manifestFile: assetFile,
        assetDirectory: assetDirectory,
      );
      if (packageValidationFailure != null) {
        return _NormalizedDownloadEntry(
          entry: _buildStaleFailureEntry(
            entry,
            packageValidationFailure.reason,
            packageValidationFailure.failureKind,
          ),
          changed: true,
        );
      }
    }

    return _NormalizedDownloadEntry(entry: entry, changed: false);
  }

  Future<_OfflinePackageValidationFailure?> _validatePackagedHlsManifest({
    required File manifestFile,
    required Directory assetDirectory,
    Set<String>? validatedManifestPaths,
  }) async {
    final manifestKey = _normalizePath(manifestFile.path);
    final visitedManifests = validatedManifestPaths ?? <String>{};
    if (!visitedManifests.add(manifestKey)) {
      return null;
    }

    final manifestBody = await _readOfflineManifest(manifestFile);
    if (manifestBody == null) {
      return const _OfflinePackageValidationFailure(
        reason: 'Offline package manifest could not be read.',
        failureKind: DownloadFailureKind.offlinePackageCorrupted,
      );
    }

    final references = <String>[];
    for (final rawLine in manifestBody.split('\n')) {
      final trimmedLine = rawLine.trim();
      if (trimmedLine.isEmpty) {
        continue;
      }

      if (!trimmedLine.startsWith('#')) {
        references.add(trimmedLine);
        continue;
      }

      final taggedReference = _extractTaggedReference(rawLine);
      if (taggedReference != null) {
        references.add(taggedReference);
      }
    }

    if (references.isEmpty) {
      return const _OfflinePackageValidationFailure(
        reason: 'Offline package has no media assets.',
        failureKind: DownloadFailureKind.offlinePackageCorrupted,
      );
    }

    for (final reference in references) {
      final validationFailure = await _validatePackagedAssetReference(
        reference: reference,
        assetDirectory: assetDirectory,
      );
      if (validationFailure != null) {
        return validationFailure;
      }

      if (_isOfflineManifestReference(reference)) {
        final nestedManifest = File.fromUri(
          assetDirectory.uri.resolve(reference.trim()),
        );
        final nestedValidationFailure = await _validatePackagedHlsManifest(
          manifestFile: nestedManifest,
          assetDirectory: assetDirectory,
          validatedManifestPaths: visitedManifests,
        );
        if (nestedValidationFailure != null) {
          return nestedValidationFailure;
        }
      }
    }

    return null;
  }

  Future<String?> _readOfflineManifest(File manifestFile) async {
    try {
      return await manifestFile.readAsString();
    } on FileSystemException {
      return null;
    }
  }

  String? _extractTaggedReference(String rawLine) {
    final uriMatch = RegExp(r'URI="([^"]+)"').firstMatch(rawLine);
    final reference = uriMatch?.group(1)?.trim();
    if (reference == null || reference.isEmpty) {
      return null;
    }
    return reference;
  }

  bool _isOfflineManifestReference(String reference) {
    return reference.trim().toLowerCase().endsWith('.m3u8');
  }

  Future<_OfflinePackageValidationFailure?> _validatePackagedAssetReference({
    required String reference,
    required Directory assetDirectory,
  }) async {
    final trimmedReference = reference.trim();
    final referenceUri = Uri.tryParse(trimmedReference);
    final hasInvalidStructure =
        trimmedReference.isEmpty ||
        trimmedReference.startsWith('/') ||
        trimmedReference.startsWith('\\') ||
        trimmedReference.startsWith('//') ||
        referenceUri == null ||
        referenceUri.hasScheme ||
        referenceUri.hasQuery ||
        referenceUri.fragment.isNotEmpty;
    if (hasInvalidStructure) {
      return const _OfflinePackageValidationFailure(
        reason: 'Offline package contains an invalid local reference.',
        failureKind: DownloadFailureKind.offlinePackageCorrupted,
      );
    }

    final assetFile = File.fromUri(
      assetDirectory.uri.resolve(trimmedReference),
    );
    if (!_isPathWithinDirectory(
      candidatePath: assetFile.path,
      directory: assetDirectory,
    )) {
      return const _OfflinePackageValidationFailure(
        reason: 'Offline package contains an invalid local reference.',
        failureKind: DownloadFailureKind.offlinePackageCorrupted,
      );
    }

    if (!await assetFile.exists()) {
      return const _OfflinePackageValidationFailure(
        reason: 'Offline package asset is missing on device.',
        failureKind: DownloadFailureKind.offlinePackageMissing,
      );
    }

    try {
      final assetLength = await assetFile.length();
      if (assetLength <= 0) {
        return const _OfflinePackageValidationFailure(
          reason: 'Offline package asset is empty.',
          failureKind: DownloadFailureKind.offlinePackageCorrupted,
        );
      }
    } on FileSystemException {
      return const _OfflinePackageValidationFailure(
        reason: 'Offline package asset could not be inspected.',
        failureKind: DownloadFailureKind.offlinePackageCorrupted,
      );
    }

    return null;
  }

  Future<void> _deleteManagedDirectoryIfPresent(Directory? directory) async {
    if (directory == null || !await directory.exists()) {
      return;
    }

    if (!await _isManagedDownloadDirectory(directory)) {
      return;
    }

    await directory.delete(recursive: true);
  }

  Future<bool> _isManagedDownloadDirectory(Directory directory) async {
    final managedRoot = await _managedDownloadsRootDirectory();
    final normalizedRootPath = _normalizePath(managedRoot.path);
    final normalizedCandidatePath = _normalizePath(directory.path);
    return normalizedCandidatePath.startsWith(
      '$normalizedRootPath${Platform.pathSeparator}',
    );
  }

  Future<Directory> _managedDownloadsRootDirectory() async {
    final rootDirectory = await _downloadsRootDirectoryProvider();
    return Directory('${rootDirectory.path}/downloads');
  }

  bool _isPathWithinDirectory({
    required String candidatePath,
    required Directory directory,
  }) {
    final normalizedDirectoryPath = _normalizePath(directory.path);
    final normalizedCandidatePath = _normalizePath(candidatePath);
    return normalizedCandidatePath.startsWith(
      '$normalizedDirectoryPath${Platform.pathSeparator}',
    );
  }

  String _normalizePath(String path) {
    var normalizedPath = File(path).absolute.uri.normalizePath().toFilePath();
    while (normalizedPath.length > 1 &&
        normalizedPath.endsWith(Platform.pathSeparator)) {
      normalizedPath = normalizedPath.substring(
        0,
        normalizedPath.length - Platform.pathSeparator.length,
      );
    }
    return normalizedPath;
  }

  DownloadEntry _buildStaleFailureEntry(
    DownloadEntry entry,
    String reason,
    DownloadFailureKind failureKind,
  ) {
    return DownloadEntry(
      id: entry.id,
      seriesId: entry.seriesId,
      episodeId: entry.episodeId,
      selectedQuality: entry.selectedQuality,
      status: DownloadStatus.failed,
      bytesDownloaded: entry.bytesDownloaded,
      totalBytes: entry.totalBytes,
      localAssetUri: null,
      storageDirectoryPath: entry.storageDirectoryPath,
      createdAt: entry.createdAt,
      completedAt: null,
      lastError: reason,
      failureKind: failureKind,
      sourceKind: entry.sourceKind,
    );
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

class _OfflineManifestPackagingState {
  int _assetIndex = 0;

  String nextLocalFileName(String extension) {
    final localFileName =
        'asset_${_assetIndex.toString().padLeft(4, '0')}$extension';
    _assetIndex += 1;
    return localFileName;
  }
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

class _NormalizedDownloadEntry {
  const _NormalizedDownloadEntry({required this.entry, required this.changed});

  final DownloadEntry entry;
  final bool changed;
}

class _OfflinePackageValidationFailure {
  const _OfflinePackageValidationFailure({
    required this.reason,
    required this.failureKind,
  });

  final String reason;
  final DownloadFailureKind failureKind;
}
