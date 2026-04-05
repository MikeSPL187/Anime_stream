import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/series.dart';
import '../di/series_repository_provider.dart';

final browseCatalogProvider = FutureProvider.autoDispose<BrowseCatalogData>((
  ref,
) async {
  final repository = ref.watch(seriesRepositoryProvider);
  final latestReleasesFuture = repository.getFeaturedSeries(limit: 8);
  final trendingSeriesFuture = repository.getTrendingSeries(limit: 8);
  final popularSeriesFuture = repository.getPopularSeries(limit: 8);

  return BrowseCatalogData(
    latestReleases: await latestReleasesFuture,
    trendingSeries: await trendingSeriesFuture,
    popularSeries: await popularSeriesFuture,
  );
});

@immutable
class BrowseCatalogData {
  const BrowseCatalogData({
    required this.latestReleases,
    required this.trendingSeries,
    required this.popularSeries,
  });

  final List<Series> latestReleases;
  final List<Series> trendingSeries;
  final List<Series> popularSeries;

  bool get hasAnyContent =>
      latestReleases.isNotEmpty ||
      trendingSeries.isNotEmpty ||
      popularSeries.isNotEmpty;
}
