import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/continue_watching_entry.dart';
import '../../features/player/player_screen_context.dart';
import '../di/watch_system_repository_provider.dart';

final homeContinueWatchingProvider =
    FutureProvider.autoDispose<List<HomeContinueWatchingItem>>((ref) async {
      final watchSystemRepository = ref.watch(watchSystemRepositoryProvider);
      final entries = await watchSystemRepository.getContinueWatching(
        limit: 10,
      );

      return entries
          .map(HomeContinueWatchingItem.fromEntry)
          .toList(growable: false);
    });

@immutable
class HomeContinueWatchingItem {
  const HomeContinueWatchingItem({
    required this.seriesTitle,
    this.seriesPosterImageUrl,
    required this.episodeTitle,
    required this.episodeLabel,
    required this.progressLabel,
    required this.playerContext,
    this.progressFraction,
  });

  factory HomeContinueWatchingItem.fromEntry(ContinueWatchingEntry entry) {
    final totalDuration = entry.progress.totalDuration;
    final position = entry.progress.position;
    final progressFraction =
        totalDuration == null || totalDuration <= Duration.zero
        ? null
        : (position.inMicroseconds / totalDuration.inMicroseconds)
              .clamp(0, 1)
              .toDouble();
    final episodeLabel = 'Episode ${entry.episode.numberLabel}';
    final resolvedEpisodeTitle = entry.episode.title.trim().isEmpty
        ? episodeLabel
        : entry.episode.title;
    final watchedLabel = _formatDuration(position);
    final totalLabel = totalDuration == null || totalDuration <= Duration.zero
        ? null
        : _formatDuration(totalDuration);

    return HomeContinueWatchingItem(
      seriesTitle: entry.series.title,
      seriesPosterImageUrl: entry.series.posterImageUrl,
      episodeTitle: resolvedEpisodeTitle,
      episodeLabel: episodeLabel,
      progressLabel: totalLabel == null
          ? '$watchedLabel watched'
          : '$watchedLabel / $totalLabel watched',
      progressFraction: progressFraction,
      playerContext: PlayerScreenContext(
        seriesId: entry.series.id,
        seriesTitle: entry.series.title,
        episodeId: entry.episode.id,
        episodeNumberLabel: entry.episode.numberLabel,
        episodeTitle: resolvedEpisodeTitle,
      ),
    );
  }

  final String seriesTitle;
  final String? seriesPosterImageUrl;
  final String episodeTitle;
  final String episodeLabel;
  final String progressLabel;
  final double? progressFraction;
  final PlayerScreenContext playerContext;

  String get subtitle => '$episodeLabel  •  $progressLabel';

  static String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours > 0) {
      return minutes == 0 ? '${hours}h' : '${hours}h ${minutes}m';
    }

    if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m';
    }

    return '${duration.inSeconds}s';
  }
}
