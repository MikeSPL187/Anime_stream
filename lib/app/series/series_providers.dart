import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/episode_progress.dart';
import '../../shared/user_facing_async_error.dart';
import '../di/series_repository_provider.dart';
import '../di/watch_system_repository_provider.dart';
import 'series_details_data.dart';

final seriesContentProvider = FutureProvider.autoDispose
    .family<SeriesContentData, String>((ref, seriesId) async {
      final repository = ref.watch(seriesRepositoryProvider);
      final seriesFuture = repository.getSeriesById(seriesId);
      final episodesFuture = repository.getEpisodes(seriesId);

      return SeriesContentData(
        series: await seriesFuture,
        episodes: await episodesFuture,
      );
    });

final seriesDetailsProvider = FutureProvider.autoDispose
    .family<SeriesDetailsData, String>((ref, seriesId) async {
      final watchSystemRepository = ref.watch(watchSystemRepositoryProvider);
      final contentFuture = ref.watch(seriesContentProvider(seriesId).future);
      String? watchStateErrorMessage;
      final progressFuture =
          Future<List<EpisodeProgress>>.sync(
            () => watchSystemRepository.getSeriesEpisodeProgress(
              seriesId: seriesId,
            ),
          ).catchError((Object error, StackTrace stackTrace) {
            watchStateErrorMessage ??= userFacingAsyncErrorMessage(
              error,
              fallbackMessage:
                  'Resume progress and watched markers could not be loaded right now.',
            );
            return <EpisodeProgress>[];
          });

      final content = await contentFuture;
      final episodeProgressById = <String, EpisodeProgress>{};
      final progressEntries = await progressFuture;
      episodeProgressById.addEntries(
        progressEntries.map(
          (progress) => MapEntry(progress.episodeId, progress),
        ),
      );

      return SeriesDetailsData(
        series: content.series,
        episodes: content.episodes,
        episodeProgressById: episodeProgressById,
        watchStateErrorMessage: watchStateErrorMessage,
      );
    });
