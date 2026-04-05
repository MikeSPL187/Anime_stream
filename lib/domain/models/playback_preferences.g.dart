// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'playback_preferences.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PlaybackPreferencesImpl _$$PlaybackPreferencesImplFromJson(
  Map<String, dynamic> json,
) => _$PlaybackPreferencesImpl(
  preferredAudioLanguageCodes:
      (json['preferredAudioLanguageCodes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  preferredSubtitleLanguageCodes:
      (json['preferredSubtitleLanguageCodes'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const <String>[],
  autoplayNextEpisode: json['autoplayNextEpisode'] as bool? ?? true,
  preferSubtitles: json['preferSubtitles'] as bool? ?? false,
  defaultPlaybackSpeed:
      (json['defaultPlaybackSpeed'] as num?)?.toDouble() ?? 1.0,
);

Map<String, dynamic> _$$PlaybackPreferencesImplToJson(
  _$PlaybackPreferencesImpl instance,
) => <String, dynamic>{
  'preferredAudioLanguageCodes': instance.preferredAudioLanguageCodes,
  'preferredSubtitleLanguageCodes': instance.preferredSubtitleLanguageCodes,
  'autoplayNextEpisode': instance.autoplayNextEpisode,
  'preferSubtitles': instance.preferSubtitles,
  'defaultPlaybackSpeed': instance.defaultPlaybackSpeed,
};
