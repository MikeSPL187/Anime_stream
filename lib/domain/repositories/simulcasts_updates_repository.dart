import '../models/episode.dart';
import '../models/series.dart';

abstract interface class SimulcastsUpdatesRepository {
  Future<List<Series>> getSimulcasts({int limit = 20});

  Future<List<Episode>> getLatestEpisodeUpdates({int limit = 20});
}
