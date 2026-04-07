import '../models/download_entry.dart';

abstract interface class DownloadsRepository {
  Future<List<DownloadEntry>> getDownloads();

  Future<DownloadEntry?> getPlayableDownload({
    required String seriesId,
    required String episodeId,
  });

  Future<void> queueEpisodeDownload({
    required String seriesId,
    required String episodeId,
    String selectedQuality = '1080p',
  });

  Future<DownloadEntry> startEpisodeDownload({
    required String seriesId,
    required String episodeId,
    String selectedQuality = '1080p',
  });

  Future<void> pauseDownload(String downloadId);

  Future<void> removeDownload(String downloadId);
}
