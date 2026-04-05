// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'availability_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AvailabilityStateImpl _$$AvailabilityStateImplFromJson(
  Map<String, dynamic> json,
) => _$AvailabilityStateImpl(
  status:
      $enumDecodeNullable(_$AvailabilityStatusEnumMap, json['status']) ??
      AvailabilityStatus.available,
  availableFrom: json['availableFrom'] == null
      ? null
      : DateTime.parse(json['availableFrom'] as String),
  expiresAt: json['expiresAt'] == null
      ? null
      : DateTime.parse(json['expiresAt'] as String),
  reason: json['reason'] as String?,
);

Map<String, dynamic> _$$AvailabilityStateImplToJson(
  _$AvailabilityStateImpl instance,
) => <String, dynamic>{
  'status': _$AvailabilityStatusEnumMap[instance.status]!,
  'availableFrom': instance.availableFrom?.toIso8601String(),
  'expiresAt': instance.expiresAt?.toIso8601String(),
  'reason': instance.reason,
};

const _$AvailabilityStatusEnumMap = {
  AvailabilityStatus.available: 'available',
  AvailabilityStatus.scheduled: 'scheduled',
  AvailabilityStatus.unavailable: 'unavailable',
  AvailabilityStatus.regionRestricted: 'regionRestricted',
  AvailabilityStatus.subscriptionRequired: 'subscriptionRequired',
};
