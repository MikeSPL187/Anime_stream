import '../models/continue_watching_entry.dart';
import '../models/episode_progress.dart';

abstract interface class WatchSystemRepository {
  Future<List<ContinueWatchingEntry>> getContinueWatching({int limit = 20});

  Future<EpisodeProgress?> getEpisodeProgress({
    required String seriesId,
    required String episodeId,
  });

  Future<void> saveEpisodeProgress(EpisodeProgress progress);
}
