import 'package:freezed_annotation/freezed_annotation.dart';

part 'episode_progress.freezed.dart';
part 'episode_progress.g.dart';

@freezed
class EpisodeProgress with _$EpisodeProgress {
  const factory EpisodeProgress({
    required String seriesId,
    required String episodeId,
    required Duration position,
    Duration? totalDuration,
    @Default(false) bool isCompleted,
    required DateTime updatedAt,
  }) = _EpisodeProgress;

  factory EpisodeProgress.fromJson(Map<String, dynamic> json) =>
      _$EpisodeProgressFromJson(json);
}
