import '../models/series.dart';

abstract interface class SearchRepository {
  Future<List<Series>> searchSeries(String query, {int limit = 20});
}
