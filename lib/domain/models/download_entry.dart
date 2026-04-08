enum DownloadStatus { queued, downloading, paused, completed, failed }

enum DownloadSourceKind { localHlsManifest, localFile }

enum DownloadFailureKind {
  transferFailed,
  transferInterrupted,
  offlineAssetMissing,
  offlineAssetInvalid,
  offlineAssetCorrupted,
  offlinePackageMissing,
  offlinePackageCorrupted,
}

class DownloadEntry {
  const DownloadEntry({
    required this.id,
    required this.seriesId,
    required this.episodeId,
    required this.selectedQuality,
    required this.status,
    this.seriesTitle,
    this.episodeNumberLabel,
    this.episodeTitle,
    this.bytesDownloaded = 0,
    this.totalBytes,
    this.localAssetUri,
    this.storageDirectoryPath,
    this.createdAt,
    this.completedAt,
    this.lastError,
    this.failureKind,
    this.sourceKind = DownloadSourceKind.localHlsManifest,
  });

  final String id;
  final String seriesId;
  final String episodeId;
  final String selectedQuality;
  final DownloadStatus status;
  final String? seriesTitle;
  final String? episodeNumberLabel;
  final String? episodeTitle;
  final int bytesDownloaded;
  final int? totalBytes;
  final String? localAssetUri;
  final String? storageDirectoryPath;
  final DateTime? createdAt;
  final DateTime? completedAt;
  final String? lastError;
  final DownloadFailureKind? failureKind;
  final DownloadSourceKind sourceKind;

  bool get isPlayableOffline {
    final assetUri = localAssetUri?.trim();
    return status == DownloadStatus.completed &&
        assetUri != null &&
        assetUri.isNotEmpty;
  }

  bool get hasActiveTransfer {
    return switch (status) {
      DownloadStatus.downloading => true,
      _ => false,
    };
  }

  bool get requiresOfflineRestore {
    if (status != DownloadStatus.failed) {
      return false;
    }

    return switch (failureKind) {
      DownloadFailureKind.offlineAssetMissing ||
      DownloadFailureKind.offlineAssetInvalid ||
      DownloadFailureKind.offlineAssetCorrupted ||
      DownloadFailureKind.offlinePackageMissing ||
      DownloadFailureKind.offlinePackageCorrupted => true,
      _ => false,
    };
  }

  String get displaySeriesTitle {
    final title = seriesTitle?.trim();
    if (title != null && title.isNotEmpty) {
      return title;
    }

    return seriesId;
  }

  String get displayEpisodeNumberLabel {
    final numberLabel = episodeNumberLabel?.trim();
    if (numberLabel != null && numberLabel.isNotEmpty) {
      return numberLabel;
    }

    return episodeId;
  }

  String get displayEpisodeLabel => 'Episode $displayEpisodeNumberLabel';

  String get displayEpisodeTitle {
    final title = episodeTitle?.trim();
    if (title != null && title.isNotEmpty) {
      return title;
    }

    return displayEpisodeLabel;
  }

  DownloadEntry copyWith({
    String? id,
    String? seriesId,
    String? episodeId,
    String? selectedQuality,
    DownloadStatus? status,
    String? seriesTitle,
    String? episodeNumberLabel,
    String? episodeTitle,
    int? bytesDownloaded,
    int? totalBytes,
    String? localAssetUri,
    String? storageDirectoryPath,
    DateTime? createdAt,
    DateTime? completedAt,
    String? lastError,
    DownloadFailureKind? failureKind,
    DownloadSourceKind? sourceKind,
  }) {
    return DownloadEntry(
      id: id ?? this.id,
      seriesId: seriesId ?? this.seriesId,
      episodeId: episodeId ?? this.episodeId,
      selectedQuality: selectedQuality ?? this.selectedQuality,
      status: status ?? this.status,
      seriesTitle: seriesTitle ?? this.seriesTitle,
      episodeNumberLabel: episodeNumberLabel ?? this.episodeNumberLabel,
      episodeTitle: episodeTitle ?? this.episodeTitle,
      bytesDownloaded: bytesDownloaded ?? this.bytesDownloaded,
      totalBytes: totalBytes ?? this.totalBytes,
      localAssetUri: localAssetUri ?? this.localAssetUri,
      storageDirectoryPath: storageDirectoryPath ?? this.storageDirectoryPath,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      lastError: lastError ?? this.lastError,
      failureKind: failureKind ?? this.failureKind,
      sourceKind: sourceKind ?? this.sourceKind,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'seriesId': seriesId,
      'episodeId': episodeId,
      'selectedQuality': selectedQuality,
      'status': status.name,
      'seriesTitle': seriesTitle,
      'episodeNumberLabel': episodeNumberLabel,
      'episodeTitle': episodeTitle,
      'bytesDownloaded': bytesDownloaded,
      'totalBytes': totalBytes,
      'localAssetUri': localAssetUri,
      'storageDirectoryPath': storageDirectoryPath,
      'createdAt': createdAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'lastError': lastError,
      'failureKind': failureKind?.name,
      'sourceKind': sourceKind.name,
    };
  }

  factory DownloadEntry.fromJson(Map<String, dynamic> json) {
    final status = _parseDownloadStatus(json['status']);
    final lastError = json['lastError'] as String?;
    return DownloadEntry(
      id: json['id'] as String? ?? '',
      seriesId: json['seriesId'] as String? ?? '',
      episodeId: json['episodeId'] as String? ?? '',
      selectedQuality: json['selectedQuality'] as String? ?? '1080p',
      status: status,
      seriesTitle: json['seriesTitle'] as String?,
      episodeNumberLabel: json['episodeNumberLabel'] as String?,
      episodeTitle: json['episodeTitle'] as String?,
      bytesDownloaded: (json['bytesDownloaded'] as num?)?.toInt() ?? 0,
      totalBytes: (json['totalBytes'] as num?)?.toInt(),
      localAssetUri: json['localAssetUri'] as String?,
      storageDirectoryPath: json['storageDirectoryPath'] as String?,
      createdAt: _parseDateTime(json['createdAt']),
      completedAt: _parseDateTime(json['completedAt']),
      lastError: lastError,
      failureKind: _parseDownloadFailureKind(
        json['failureKind'],
        status: status,
        lastError: lastError,
      ),
      sourceKind: _parseDownloadSourceKind(json['sourceKind']),
    );
  }

  static DownloadStatus _parseDownloadStatus(Object? value) {
    return switch (value) {
      'queued' => DownloadStatus.queued,
      'downloading' => DownloadStatus.downloading,
      'paused' => DownloadStatus.paused,
      'completed' => DownloadStatus.completed,
      'failed' => DownloadStatus.failed,
      _ => DownloadStatus.queued,
    };
  }

  static DownloadSourceKind _parseDownloadSourceKind(Object? value) {
    return switch (value) {
      'localFile' => DownloadSourceKind.localFile,
      _ => DownloadSourceKind.localHlsManifest,
    };
  }

  static DownloadFailureKind? _parseDownloadFailureKind(
    Object? value, {
    required DownloadStatus status,
    required String? lastError,
  }) {
    final explicitKind = switch (value) {
      'transferFailed' => DownloadFailureKind.transferFailed,
      'transferInterrupted' => DownloadFailureKind.transferInterrupted,
      'offlineAssetMissing' => DownloadFailureKind.offlineAssetMissing,
      'offlineAssetInvalid' => DownloadFailureKind.offlineAssetInvalid,
      'offlineAssetCorrupted' => DownloadFailureKind.offlineAssetCorrupted,
      'offlinePackageMissing' => DownloadFailureKind.offlinePackageMissing,
      'offlinePackageCorrupted' => DownloadFailureKind.offlinePackageCorrupted,
      _ => null,
    };
    if (explicitKind != null) {
      return explicitKind;
    }

    if (status != DownloadStatus.failed) {
      return null;
    }

    final normalizedError = (lastError ?? '').trim().toLowerCase();
    if (normalizedError.isEmpty) {
      return null;
    }

    if (normalizedError.startsWith('offline asset reference')) {
      return DownloadFailureKind.offlineAssetInvalid;
    }
    if (normalizedError.startsWith('offline asset is missing')) {
      return DownloadFailureKind.offlineAssetMissing;
    }
    if (normalizedError.startsWith('offline asset')) {
      return DownloadFailureKind.offlineAssetCorrupted;
    }
    if (normalizedError.startsWith('offline package directory')) {
      return DownloadFailureKind.offlinePackageMissing;
    }
    if (normalizedError.startsWith('offline package asset is missing')) {
      return DownloadFailureKind.offlinePackageMissing;
    }
    if (normalizedError.startsWith('offline package')) {
      return DownloadFailureKind.offlinePackageCorrupted;
    }

    return DownloadFailureKind.transferFailed;
  }

  static DateTime? _parseDateTime(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }
}
