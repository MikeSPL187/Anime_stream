import 'package:freezed_annotation/freezed_annotation.dart';

import 'episode.dart';
import 'episode_progress.dart';
import 'series.dart';

part 'continue_watching_entry.freezed.dart';
part 'continue_watching_entry.g.dart';

@freezed
class ContinueWatchingEntry with _$ContinueWatchingEntry {
  const factory ContinueWatchingEntry({
    required Series series,
    required Episode episode,
    required EpisodeProgress progress,
    required DateTime lastEngagedAt,
  }) = _ContinueWatchingEntry;

  factory ContinueWatchingEntry.fromJson(Map<String, dynamic> json) =>
      _$ContinueWatchingEntryFromJson(json);
}
