import '../models/download_entry.dart';

abstract interface class DownloadsRepository {
  Future<List<DownloadEntry>> getDownloads();

  Future<void> queueEpisodeDownload({
    required String seriesId,
    required String episodeId,
  });

  Future<void> pauseDownload(String downloadId);

  Future<void> removeDownload(String downloadId);
}
