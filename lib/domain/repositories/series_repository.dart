import '../models/episode.dart';
import '../models/series_catalog_page.dart';
import '../models/series.dart';

abstract interface class SeriesRepository {
  Future<List<Series>> getLatestSeries({int limit = 20});

  Future<List<Series>> getTrendingSeries({int limit = 20});

  Future<List<Series>> getPopularSeries({int limit = 20});

  /// Returns a plain page from the provider-backed catalog listing.
  ///
  /// This contract is intentionally narrow: it enables deeper catalog browsing
  /// without implying editorial grouping, recommendations, or richer taxonomy.
  Future<SeriesCatalogPage> getCatalogPage({int page = 1, int pageSize = 20});

  Future<List<Series>> searchSeries(String query, {int limit = 20});

  Future<Series> getSeriesById(String seriesId);

  Future<List<Episode>> getEpisodes(String seriesId);
}
