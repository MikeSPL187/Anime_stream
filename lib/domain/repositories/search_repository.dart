import '../models/series.dart';

@Deprecated('Use SeriesRepository for stable product-facing search contracts.')
abstract interface class SearchRepository {
  Future<List<Series>> searchSeries(String query, {int limit = 20});
}
