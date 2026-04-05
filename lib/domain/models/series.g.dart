// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'series.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SeriesImpl _$$SeriesImplFromJson(Map<String, dynamic> json) => _$SeriesImpl(
  id: json['id'] as String,
  slug: json['slug'] as String,
  title: json['title'] as String,
  originalTitle: json['originalTitle'] as String?,
  synopsis: json['synopsis'] as String?,
  posterImageUrl: json['posterImageUrl'] as String?,
  bannerImageUrl: json['bannerImageUrl'] as String?,
  genres:
      (json['genres'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const <String>[],
  releaseYear: (json['releaseYear'] as num?)?.toInt(),
  status:
      $enumDecodeNullable(_$SeriesStatusEnumMap, json['status']) ??
      SeriesStatus.unknown,
  availability: json['availability'] == null
      ? const AvailabilityState()
      : AvailabilityState.fromJson(
          json['availability'] as Map<String, dynamic>,
        ),
  lastUpdatedAt: json['lastUpdatedAt'] == null
      ? null
      : DateTime.parse(json['lastUpdatedAt'] as String),
);

Map<String, dynamic> _$$SeriesImplToJson(_$SeriesImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'slug': instance.slug,
      'title': instance.title,
      'originalTitle': instance.originalTitle,
      'synopsis': instance.synopsis,
      'posterImageUrl': instance.posterImageUrl,
      'bannerImageUrl': instance.bannerImageUrl,
      'genres': instance.genres,
      'releaseYear': instance.releaseYear,
      'status': _$SeriesStatusEnumMap[instance.status]!,
      'availability': instance.availability,
      'lastUpdatedAt': instance.lastUpdatedAt?.toIso8601String(),
    };

const _$SeriesStatusEnumMap = {
  SeriesStatus.ongoing: 'ongoing',
  SeriesStatus.completed: 'completed',
  SeriesStatus.upcoming: 'upcoming',
  SeriesStatus.hiatus: 'hiatus',
  SeriesStatus.unknown: 'unknown',
};
