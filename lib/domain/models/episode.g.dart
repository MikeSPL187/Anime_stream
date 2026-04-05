// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'episode.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$EpisodeImpl _$$EpisodeImplFromJson(Map<String, dynamic> json) =>
    _$EpisodeImpl(
      id: json['id'] as String,
      seriesId: json['seriesId'] as String,
      sortOrder: (json['sortOrder'] as num).toInt(),
      numberLabel: json['numberLabel'] as String,
      title: json['title'] as String,
      synopsis: json['synopsis'] as String?,
      duration: json['duration'] == null
          ? null
          : Duration(microseconds: (json['duration'] as num).toInt()),
      thumbnailImageUrl: json['thumbnailImageUrl'] as String?,
      airDate: json['airDate'] == null
          ? null
          : DateTime.parse(json['airDate'] as String),
      isFiller: json['isFiller'] as bool? ?? false,
      isRecap: json['isRecap'] as bool? ?? false,
      availability: json['availability'] == null
          ? const AvailabilityState()
          : AvailabilityState.fromJson(
              json['availability'] as Map<String, dynamic>,
            ),
      availableAudioLanguageCodes:
          (json['availableAudioLanguageCodes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      availableSubtitleLanguageCodes:
          (json['availableSubtitleLanguageCodes'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
    );

Map<String, dynamic> _$$EpisodeImplToJson(_$EpisodeImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'seriesId': instance.seriesId,
      'sortOrder': instance.sortOrder,
      'numberLabel': instance.numberLabel,
      'title': instance.title,
      'synopsis': instance.synopsis,
      'duration': instance.duration?.inMicroseconds,
      'thumbnailImageUrl': instance.thumbnailImageUrl,
      'airDate': instance.airDate?.toIso8601String(),
      'isFiller': instance.isFiller,
      'isRecap': instance.isRecap,
      'availability': instance.availability,
      'availableAudioLanguageCodes': instance.availableAudioLanguageCodes,
      'availableSubtitleLanguageCodes': instance.availableSubtitleLanguageCodes,
    };
