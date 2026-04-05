import 'package:freezed_annotation/freezed_annotation.dart';

part 'playback_preferences.freezed.dart';
part 'playback_preferences.g.dart';

@freezed
class PlaybackPreferences with _$PlaybackPreferences {
  const factory PlaybackPreferences({
    @Default(<String>[]) List<String> preferredAudioLanguageCodes,
    @Default(<String>[]) List<String> preferredSubtitleLanguageCodes,
    @Default(true) bool autoplayNextEpisode,
    @Default(false) bool preferSubtitles,
    @Default(1.0) double defaultPlaybackSpeed,
  }) = _PlaybackPreferences;

  factory PlaybackPreferences.fromJson(Map<String, dynamic> json) =>
      _$PlaybackPreferencesFromJson(json);
}
