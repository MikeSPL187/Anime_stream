import 'package:freezed_annotation/freezed_annotation.dart';

import 'availability_state.dart';

part 'episode.freezed.dart';
part 'episode.g.dart';

@freezed
class Episode with _$Episode {
  const factory Episode({
    required String id,
    required String seriesId,
    required int sortOrder,
    required String numberLabel,
    required String title,
    String? synopsis,
    Duration? duration,
    String? thumbnailImageUrl,
    DateTime? airDate,
    @Default(false) bool isFiller,
    @Default(false) bool isRecap,
    @Default(AvailabilityState()) AvailabilityState availability,
    @Default(<String>[]) List<String> availableAudioLanguageCodes,
    @Default(<String>[]) List<String> availableSubtitleLanguageCodes,
  }) = _Episode;

  factory Episode.fromJson(Map<String, dynamic> json) =>
      _$EpisodeFromJson(json);
}
