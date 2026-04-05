import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/series.dart';
import '../di/series_repository_provider.dart';
import 'series_details_data.dart';

final featuredSeriesProvider = FutureProvider.autoDispose<List<Series>>((
  ref,
) async {
  final repository = ref.watch(seriesRepositoryProvider);
  return repository.getFeaturedSeries();
});

final seriesDetailsProvider = FutureProvider.autoDispose
    .family<SeriesDetailsData, String>((ref, seriesId) async {
      final repository = ref.watch(seriesRepositoryProvider);
      final seriesFuture = repository.getSeriesById(seriesId);
      final episodesFuture = repository.getEpisodes(seriesId);

      return SeriesDetailsData(
        series: await seriesFuture,
        episodes: await episodesFuture,
      );
    });
