import '../models/series.dart';

abstract interface class CatalogDiscoveryRepository {
  Future<List<Series>> getFeaturedSeries({int limit = 20});

  Future<List<Series>> getTrendingSeries({int limit = 20});

  Future<List<Series>> getPopularSeries({int limit = 20});
}
