import '../models/episode.dart';
import '../models/series.dart';

@Deprecated(
  'Use SeriesRepository for stable product-facing series details contracts.',
)
abstract interface class SeriesDetailsRepository {
  Future<Series> getSeriesDetails(String seriesId);

  Future<List<Episode>> getEpisodesForSeason({
    required String seriesId,
    required String seasonId,
  });
}
