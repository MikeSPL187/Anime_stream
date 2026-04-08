import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/series.dart';
import '../di/series_repository_provider.dart';

final homeDiscoveryProvider = FutureProvider.autoDispose<HomeDiscoveryData>((
  ref,
) async {
  final repository = ref.watch(seriesRepositoryProvider);
  final latestReleasesFuture = _loadHomeSlice(
    () => repository.getLatestSeries(limit: 20),
  );
  final trendingSeriesFuture = _loadHomeSlice(
    () => repository.getTrendingSeries(limit: 8),
  );
  final popularSeriesFuture = _loadHomeSlice(
    () => repository.getPopularSeries(limit: 8),
  );

  final latestReleases = await latestReleasesFuture;
  final trendingSeries = await trendingSeriesFuture;
  final popularSeries = await popularSeriesFuture;

  return HomeDiscoveryData(
    latestReleases: latestReleases.seriesList,
    latestError: latestReleases.errorMessage,
    trendingSeries: trendingSeries.seriesList,
    trendingError: trendingSeries.errorMessage,
    popularSeries: popularSeries.seriesList,
    popularError: popularSeries.errorMessage,
  );
});

Future<_HomeSliceLoadResult> _loadHomeSlice(
  Future<List<Series>> Function() loader,
) async {
  try {
    return _HomeSliceLoadResult(seriesList: await loader());
  } catch (error) {
    return _HomeSliceLoadResult(
      seriesList: const [],
      errorMessage: error.toString(),
    );
  }
}

@immutable
class HomeDiscoveryData {
  const HomeDiscoveryData({
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

class _HomeSliceLoadResult {
  const _HomeSliceLoadResult({required this.seriesList, this.errorMessage});

  final List<Series> seriesList;
  final String? errorMessage;
}
