import '../models/continue_watching_entry.dart';
import '../models/episode_progress.dart';
import '../models/history_entry.dart';

abstract interface class ProgressRepository {
  Future<List<ContinueWatchingEntry>> getContinueWatching({int limit = 20});

  Future<List<HistoryEntry>> getWatchHistory({int limit = 50});

  Future<EpisodeProgress?> getEpisodeProgress(String episodeId);

  Future<void> saveEpisodeProgress(EpisodeProgress progress);
}
