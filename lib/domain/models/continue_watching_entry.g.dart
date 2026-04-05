// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'continue_watching_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ContinueWatchingEntryImpl _$$ContinueWatchingEntryImplFromJson(
  Map<String, dynamic> json,
) => _$ContinueWatchingEntryImpl(
  series: Series.fromJson(json['series'] as Map<String, dynamic>),
  episode: Episode.fromJson(json['episode'] as Map<String, dynamic>),
  progress: EpisodeProgress.fromJson(json['progress'] as Map<String, dynamic>),
  lastEngagedAt: DateTime.parse(json['lastEngagedAt'] as String),
);

Map<String, dynamic> _$$ContinueWatchingEntryImplToJson(
  _$ContinueWatchingEntryImpl instance,
) => <String, dynamic>{
  'series': instance.series,
  'episode': instance.episode,
  'progress': instance.progress,
  'lastEngagedAt': instance.lastEngagedAt.toIso8601String(),
};
