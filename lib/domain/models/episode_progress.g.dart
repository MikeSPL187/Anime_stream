// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'episode_progress.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$EpisodeProgressImpl _$$EpisodeProgressImplFromJson(
  Map<String, dynamic> json,
) => _$EpisodeProgressImpl(
  seriesId: json['seriesId'] as String,
  episodeId: json['episodeId'] as String,
  position: Duration(microseconds: (json['position'] as num).toInt()),
  totalDuration: json['totalDuration'] == null
      ? null
      : Duration(microseconds: (json['totalDuration'] as num).toInt()),
  isCompleted: json['isCompleted'] as bool? ?? false,
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$$EpisodeProgressImplToJson(
  _$EpisodeProgressImpl instance,
) => <String, dynamic>{
  'seriesId': instance.seriesId,
  'episodeId': instance.episodeId,
  'position': instance.position.inMicroseconds,
  'totalDuration': instance.totalDuration?.inMicroseconds,
  'isCompleted': instance.isCompleted,
  'updatedAt': instance.updatedAt.toIso8601String(),
};
