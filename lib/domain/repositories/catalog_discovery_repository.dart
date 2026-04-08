import '../models/series.dart';

@Deprecated(
  'Use SeriesRepository for stable product-facing series discovery contracts.',
)
abstract interface class CatalogDiscoveryRepository {
  Future<List<Series>> getLatestSeries({int limit = 20});

  Future<List<Series>> getTrendingSeries({int limit = 20});

  Future<List<Series>> getPopularSeries({int limit = 20});
}
