import 'episode.dart';
import 'series.dart';

enum DownloadStatus {
  queued,
  downloading,
  paused,
  completed,
  failed,
}

class DownloadEntry {
  const DownloadEntry({
    required this.id,
    required this.series,
    required this.episode,
    required this.status,
    this.bytesDownloaded = 0,
    this.totalBytes,
    this.localPath,
    this.createdAt,
    this.completedAt,
  });

  final String id;
  final Series series;
  final Episode episode;
  final DownloadStatus status;
  final int bytesDownloaded;
  final int? totalBytes;
  final String? localPath;
  final DateTime? createdAt;
  final DateTime? completedAt;
}
