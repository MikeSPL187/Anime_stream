import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/episode_progress.dart';
import '../../domain/models/series.dart';
import '../di/series_repository_provider.dart';
import '../di/watch_system_repository_provider.dart';
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
      final watchSystemRepository = ref.watch(watchSystemRepositoryProvider);
      final seriesFuture = repository.getSeriesById(seriesId);
      final episodesFuture = repository.getEpisodes(seriesId);
      final progressFuture = watchSystemRepository.getSeriesEpisodeProgress(
        seriesId: seriesId,
      );

      final progressEntries = await progressFuture;
      final episodeProgressById = <String, EpisodeProgress>{
        for (final progress in progressEntries) progress.episodeId: progress,
      };

      return SeriesDetailsData(
        series: await seriesFuture,
        episodes: await episodesFuture,
        episodeProgressById: episodeProgressById,
      );
    });
