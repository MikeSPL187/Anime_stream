import 'episode.dart';
import 'episode_progress.dart';
import 'series.dart';

class ContinueWatchingEntry {
  const ContinueWatchingEntry({
    required this.series,
    required this.episode,
    required this.progress,
    required this.lastEngagedAt,
    this.nextEpisodeId,
  });

  final Series series;
  final Episode episode;
  final EpisodeProgress progress;
  final DateTime lastEngagedAt;
  final String? nextEpisodeId;
}
