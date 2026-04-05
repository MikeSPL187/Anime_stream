import 'episode.dart';
import 'episode_progress.dart';
import 'series.dart';

class HistoryEntry {
  const HistoryEntry({
    required this.id,
    required this.series,
    required this.episode,
    required this.progress,
    required this.watchedAt,
  });

  final String id;
  final Series series;
  final Episode episode;
  final EpisodeProgress progress;
  final DateTime watchedAt;
}
