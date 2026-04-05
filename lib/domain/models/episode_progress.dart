class EpisodeProgress {
  const EpisodeProgress({
    required this.seriesId,
    required this.episodeId,
    required this.position,
    required this.updatedAt,
    this.totalDuration,
    this.isCompleted = false,
  });

  final String seriesId;
  final String episodeId;
  final Duration position;
  final Duration? totalDuration;
  final bool isCompleted;
  final DateTime updatedAt;
}
