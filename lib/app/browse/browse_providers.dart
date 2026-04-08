import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/series.dart';
import '../di/series_repository_provider.dart';

final browseCatalogProvider = FutureProvider.autoDispose<BrowseCatalogData>((
  ref,
) async {
  final repository = ref.watch(seriesRepositoryProvider);
  final latestReleasesFuture = _loadBrowseSlice(
    () => repository.getLatestSeries(limit: 8),
  );
  final trendingSeriesFuture = _loadBrowseSlice(
    () => repository.getTrendingSeries(limit: 8),
  );
  final popularSeriesFuture = _loadBrowseSlice(
    () => repository.getPopularSeries(limit: 8),
  );

  final latestReleases = await latestReleasesFuture;
  final trendingSeries = await trendingSeriesFuture;
  final popularSeries = await popularSeriesFuture;

  return BrowseCatalogData(
    latestReleases: latestReleases.seriesList,
    latestError: latestReleases.errorMessage,
    trendingSeries: trendingSeries.seriesList,
    trendingError: trendingSeries.errorMessage,
    popularSeries: popularSeries.seriesList,
    popularError: popularSeries.errorMessage,
  );
});

Future<_BrowseSliceLoadResult> _loadBrowseSlice(
  Future<List<Series>> Function() loader,
) async {
  try {
    return _BrowseSliceLoadResult(seriesList: await loader());
  } catch (error) {
    return _BrowseSliceLoadResult(
      seriesList: const [],
      errorMessage: error.toString(),
    );
  }
}

@immutable
class BrowseCatalogData {
  const BrowseCatalogData({
    required this.latestReleases,
    this.latestError,
    required this.trendingSeries,
    this.trendingError,
    required this.popularSeries,
    this.popularError,
  });

  final List<Series> latestReleases;
  final String? latestError;
  final List<Series> trendingSeries;
  final String? trendingError;
  final List<Series> popularSeries;
  final String? popularError;

  bool get hasAnyContent =>
      latestReleases.isNotEmpty ||
      trendingSeries.isNotEmpty ||
      popularSeries.isNotEmpty;

  bool get hasAnyUnavailableSlice =>
      _hasError(latestError) ||
      _hasError(trendingError) ||
      _hasError(popularError);

  static bool _hasError(String? errorMessage) =>
      errorMessage != null && errorMessage.trim().isNotEmpty;
}

class _BrowseSliceLoadResult {
  const _BrowseSliceLoadResult({required this.seriesList, this.errorMessage});

  final List<Series> seriesList;
  final String? errorMessage;
}
