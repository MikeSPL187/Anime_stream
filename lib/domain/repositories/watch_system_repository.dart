import '../models/continue_watching_entry.dart';
import '../models/episode_progress.dart';
import '../models/history_entry.dart';

abstract interface class WatchSystemRepository {
  Future<List<ContinueWatchingEntry>> getContinueWatching({int limit = 20});

  Future<List<HistoryEntry>> getWatchHistory({int limit = 50});

  Future<List<EpisodeProgress>> getSeriesEpisodeProgress({
    required String seriesId,
  });

  Future<EpisodeProgress?> getEpisodeProgress({
    required String seriesId,
    required String episodeId,
  });

  Future<void> saveEpisodeProgress(EpisodeProgress progress);
}
