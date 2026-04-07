enum DownloadStatus {
  queued,
  downloading,
  paused,
  completed,
  failed,
}

enum DownloadSourceKind {
  localHlsManifest,
  localFile,
}

class DownloadEntry {
  const DownloadEntry({
    required this.id,
    required this.seriesId,
    required this.episodeId,
    required this.selectedQuality,
    required this.status,
    this.bytesDownloaded = 0,
    this.totalBytes,
    this.localAssetUri,
    this.storageDirectoryPath,
    this.createdAt,
    this.completedAt,
    this.lastError,
    this.sourceKind = DownloadSourceKind.localHlsManifest,
  });

  final String id;
  final String seriesId;
  final String episodeId;
  final String selectedQuality;
  final DownloadStatus status;
  final int bytesDownloaded;
  final int? totalBytes;
  final String? localAssetUri;
  final String? storageDirectoryPath;
  final DateTime? createdAt;
  final DateTime? completedAt;
  final String? lastError;
  final DownloadSourceKind sourceKind;

  bool get isPlayableOffline {
    final assetUri = localAssetUri?.trim();
    return status == DownloadStatus.completed &&
        assetUri != null &&
        assetUri.isNotEmpty;
  }

  DownloadEntry copyWith({
    String? id,
    String? seriesId,
    String? episodeId,
    String? selectedQuality,
    DownloadStatus? status,
    int? bytesDownloaded,
    int? totalBytes,
    String? localAssetUri,
    String? storageDirectoryPath,
    DateTime? createdAt,
    DateTime? completedAt,
    String? lastError,
    DownloadSourceKind? sourceKind,
  }) {
    return DownloadEntry(
      id: id ?? this.id,
      seriesId: seriesId ?? this.seriesId,
      episodeId: episodeId ?? this.episodeId,
      selectedQuality: selectedQuality ?? this.selectedQuality,
      status: status ?? this.status,
      bytesDownloaded: bytesDownloaded ?? this.bytesDownloaded,
      totalBytes: totalBytes ?? this.totalBytes,
      localAssetUri: localAssetUri ?? this.localAssetUri,
      storageDirectoryPath: storageDirectoryPath ?? this.storageDirectoryPath,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      lastError: lastError ?? this.lastError,
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
      'bytesDownloaded': bytesDownloaded,
      'totalBytes': totalBytes,
      'localAssetUri': localAssetUri,
      'storageDirectoryPath': storageDirectoryPath,
      'createdAt': createdAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'lastError': lastError,
      'sourceKind': sourceKind.name,
    };
  }

  factory DownloadEntry.fromJson(Map<String, dynamic> json) {
    return DownloadEntry(
      id: json['id'] as String? ?? '',
      seriesId: json['seriesId'] as String? ?? '',
      episodeId: json['episodeId'] as String? ?? '',
      selectedQuality: json['selectedQuality'] as String? ?? '1080p',
      status: _parseDownloadStatus(json['status']),
      bytesDownloaded: (json['bytesDownloaded'] as num?)?.toInt() ?? 0,
      totalBytes: (json['totalBytes'] as num?)?.toInt(),
      localAssetUri: json['localAssetUri'] as String?,
      storageDirectoryPath: json['storageDirectoryPath'] as String?,
      createdAt: _parseDateTime(json['createdAt']),
      completedAt: _parseDateTime(json['completedAt']),
      lastError: json['lastError'] as String?,
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

  static DateTime? _parseDateTime(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      return null;
    }
    return DateTime.tryParse(value);
  }
}
