import '../models/episode.dart';
import '../models/series.dart';

abstract interface class SeriesDetailsRepository {
  Future<Series> getSeriesDetails(String seriesId);

  Future<List<Episode>> getEpisodesForSeason({
    required String seriesId,
    required String seasonId,
  });
}
