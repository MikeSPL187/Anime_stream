import '../models/episode.dart';
import '../models/series.dart';

abstract interface class SeriesRepository {
  Future<List<Series>> getFeaturedSeries({int limit = 20});

  Future<List<Series>> getTrendingSeries({int limit = 20});

  Future<List<Series>> getPopularSeries({int limit = 20});

  Future<List<Series>> searchSeries(String query, {int limit = 20});

  Future<Series> getSeriesById(String seriesId);

  Future<List<Episode>> getEpisodes(String seriesId);
}
