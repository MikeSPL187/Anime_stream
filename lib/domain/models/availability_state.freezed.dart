// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'availability_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

AvailabilityState _$AvailabilityStateFromJson(Map<String, dynamic> json) {
  return _AvailabilityState.fromJson(json);
}

/// @nodoc
mixin _$AvailabilityState {
  AvailabilityStatus get status => throw _privateConstructorUsedError;
  DateTime? get availableFrom => throw _privateConstructorUsedError;
  DateTime? get expiresAt => throw _privateConstructorUsedError;
  String? get reason => throw _privateConstructorUsedError;

  /// Serializes this AvailabilityState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AvailabilityState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AvailabilityStateCopyWith<AvailabilityState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AvailabilityStateCopyWith<$Res> {
  factory $AvailabilityStateCopyWith(
    AvailabilityState value,
    $Res Function(AvailabilityState) then,
  ) = _$AvailabilityStateCopyWithImpl<$Res, AvailabilityState>;
  @useResult
  $Res call({
    AvailabilityStatus status,
    DateTime? availableFrom,
    DateTime? expiresAt,
    String? reason,
  });
}

/// @nodoc
class _$AvailabilityStateCopyWithImpl<$Res, $Val extends AvailabilityState>
    implements $AvailabilityStateCopyWith<$Res> {
  _$AvailabilityStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AvailabilityState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? availableFrom = freezed,
    Object? expiresAt = freezed,
    Object? reason = freezed,
  }) {
    return _then(
      _value.copyWith(
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as AvailabilityStatus,
            availableFrom: freezed == availableFrom
                ? _value.availableFrom
                : availableFrom // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            expiresAt: freezed == expiresAt
                ? _value.expiresAt
                : expiresAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            reason: freezed == reason
                ? _value.reason
                : reason // ignore: cast_nullable_to_non_nullable
                      as String?,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$AvailabilityStateImplCopyWith<$Res>
    implements $AvailabilityStateCopyWith<$Res> {
  factory _$$AvailabilityStateImplCopyWith(
    _$AvailabilityStateImpl value,
    $Res Function(_$AvailabilityStateImpl) then,
  ) = __$$AvailabilityStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    AvailabilityStatus status,
    DateTime? availableFrom,
    DateTime? expiresAt,
    String? reason,
  });
}

/// @nodoc
class __$$AvailabilityStateImplCopyWithImpl<$Res>
    extends _$AvailabilityStateCopyWithImpl<$Res, _$AvailabilityStateImpl>
    implements _$$AvailabilityStateImplCopyWith<$Res> {
  __$$AvailabilityStateImplCopyWithImpl(
    _$AvailabilityStateImpl _value,
    $Res Function(_$AvailabilityStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of AvailabilityState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? status = null,
    Object? availableFrom = freezed,
    Object? expiresAt = freezed,
    Object? reason = freezed,
  }) {
    return _then(
      _$AvailabilityStateImpl(
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as AvailabilityStatus,
        availableFrom: freezed == availableFrom
            ? _value.availableFrom
            : availableFrom // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        expiresAt: freezed == expiresAt
            ? _value.expiresAt
            : expiresAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        reason: freezed == reason
            ? _value.reason
            : reason // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$AvailabilityStateImpl implements _AvailabilityState {
  const _$AvailabilityStateImpl({
    this.status = AvailabilityStatus.available,
    this.availableFrom,
    this.expiresAt,
    this.reason,
  });

  factory _$AvailabilityStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$AvailabilityStateImplFromJson(json);

  @override
  @JsonKey()
  final AvailabilityStatus status;
  @override
  final DateTime? availableFrom;
  @override
  final DateTime? expiresAt;
  @override
  final String? reason;

  @override
  String toString() {
    return 'AvailabilityState(status: $status, availableFrom: $availableFrom, expiresAt: $expiresAt, reason: $reason)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AvailabilityStateImpl &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.availableFrom, availableFrom) ||
                other.availableFrom == availableFrom) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            (identical(other.reason, reason) || other.reason == reason));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, status, availableFrom, expiresAt, reason);

  /// Create a copy of AvailabilityState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AvailabilityStateImplCopyWith<_$AvailabilityStateImpl> get copyWith =>
      __$$AvailabilityStateImplCopyWithImpl<_$AvailabilityStateImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$AvailabilityStateImplToJson(this);
  }
}

abstract class _AvailabilityState implements AvailabilityState {
  const factory _AvailabilityState({
    final AvailabilityStatus status,
    final DateTime? availableFrom,
    final DateTime? expiresAt,
    final String? reason,
  }) = _$AvailabilityStateImpl;

  factory _AvailabilityState.fromJson(Map<String, dynamic> json) =
      _$AvailabilityStateImpl.fromJson;

  @override
  AvailabilityStatus get status;
  @override
  DateTime? get availableFrom;
  @override
  DateTime? get expiresAt;
  @override
  String? get reason;

  /// Create a copy of AvailabilityState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AvailabilityStateImplCopyWith<_$AvailabilityStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
