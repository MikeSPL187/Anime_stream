import '../models/download_entry.dart';

abstract interface class DownloadsRepository {
  Future<List<DownloadEntry>> getDownloads();

  Future<DownloadEntry?> getPlayableDownload({
    required String seriesId,
    required String episodeId,
  });

  Future<DownloadEntry> startEpisodeDownload({
    required String seriesId,
    required String episodeId,
    String selectedQuality = '1080p',
    String? seriesTitle,
    String? episodeNumberLabel,
    String? episodeTitle,
  });

  Future<void> removeDownload(String downloadId);
}
