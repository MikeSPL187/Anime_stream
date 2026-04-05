// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'episode_progress.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

EpisodeProgress _$EpisodeProgressFromJson(Map<String, dynamic> json) {
  return _EpisodeProgress.fromJson(json);
}

/// @nodoc
mixin _$EpisodeProgress {
  String get seriesId => throw _privateConstructorUsedError;
  String get episodeId => throw _privateConstructorUsedError;
  Duration get position => throw _privateConstructorUsedError;
  Duration? get totalDuration => throw _privateConstructorUsedError;
  bool get isCompleted => throw _privateConstructorUsedError;
  DateTime get updatedAt => throw _privateConstructorUsedError;

  /// Serializes this EpisodeProgress to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of EpisodeProgress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EpisodeProgressCopyWith<EpisodeProgress> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EpisodeProgressCopyWith<$Res> {
  factory $EpisodeProgressCopyWith(
    EpisodeProgress value,
    $Res Function(EpisodeProgress) then,
  ) = _$EpisodeProgressCopyWithImpl<$Res, EpisodeProgress>;
  @useResult
  $Res call({
    String seriesId,
    String episodeId,
    Duration position,
    Duration? totalDuration,
    bool isCompleted,
    DateTime updatedAt,
  });
}

/// @nodoc
class _$EpisodeProgressCopyWithImpl<$Res, $Val extends EpisodeProgress>
    implements $EpisodeProgressCopyWith<$Res> {
  _$EpisodeProgressCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of EpisodeProgress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? seriesId = null,
    Object? episodeId = null,
    Object? position = null,
    Object? totalDuration = freezed,
    Object? isCompleted = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _value.copyWith(
            seriesId: null == seriesId
                ? _value.seriesId
                : seriesId // ignore: cast_nullable_to_non_nullable
                      as String,
            episodeId: null == episodeId
                ? _value.episodeId
                : episodeId // ignore: cast_nullable_to_non_nullable
                      as String,
            position: null == position
                ? _value.position
                : position // ignore: cast_nullable_to_non_nullable
                      as Duration,
            totalDuration: freezed == totalDuration
                ? _value.totalDuration
                : totalDuration // ignore: cast_nullable_to_non_nullable
                      as Duration?,
            isCompleted: null == isCompleted
                ? _value.isCompleted
                : isCompleted // ignore: cast_nullable_to_non_nullable
                      as bool,
            updatedAt: null == updatedAt
                ? _value.updatedAt
                : updatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$EpisodeProgressImplCopyWith<$Res>
    implements $EpisodeProgressCopyWith<$Res> {
  factory _$$EpisodeProgressImplCopyWith(
    _$EpisodeProgressImpl value,
    $Res Function(_$EpisodeProgressImpl) then,
  ) = __$$EpisodeProgressImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String seriesId,
    String episodeId,
    Duration position,
    Duration? totalDuration,
    bool isCompleted,
    DateTime updatedAt,
  });
}

/// @nodoc
class __$$EpisodeProgressImplCopyWithImpl<$Res>
    extends _$EpisodeProgressCopyWithImpl<$Res, _$EpisodeProgressImpl>
    implements _$$EpisodeProgressImplCopyWith<$Res> {
  __$$EpisodeProgressImplCopyWithImpl(
    _$EpisodeProgressImpl _value,
    $Res Function(_$EpisodeProgressImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of EpisodeProgress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? seriesId = null,
    Object? episodeId = null,
    Object? position = null,
    Object? totalDuration = freezed,
    Object? isCompleted = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _$EpisodeProgressImpl(
        seriesId: null == seriesId
            ? _value.seriesId
            : seriesId // ignore: cast_nullable_to_non_nullable
                  as String,
        episodeId: null == episodeId
            ? _value.episodeId
            : episodeId // ignore: cast_nullable_to_non_nullable
                  as String,
        position: null == position
            ? _value.position
            : position // ignore: cast_nullable_to_non_nullable
                  as Duration,
        totalDuration: freezed == totalDuration
            ? _value.totalDuration
            : totalDuration // ignore: cast_nullable_to_non_nullable
                  as Duration?,
        isCompleted: null == isCompleted
            ? _value.isCompleted
            : isCompleted // ignore: cast_nullable_to_non_nullable
                  as bool,
        updatedAt: null == updatedAt
            ? _value.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$EpisodeProgressImpl implements _EpisodeProgress {
  const _$EpisodeProgressImpl({
    required this.seriesId,
    required this.episodeId,
    required this.position,
    this.totalDuration,
    this.isCompleted = false,
    required this.updatedAt,
  });

  factory _$EpisodeProgressImpl.fromJson(Map<String, dynamic> json) =>
      _$$EpisodeProgressImplFromJson(json);

  @override
  final String seriesId;
  @override
  final String episodeId;
  @override
  final Duration position;
  @override
  final Duration? totalDuration;
  @override
  @JsonKey()
  final bool isCompleted;
  @override
  final DateTime updatedAt;

  @override
  String toString() {
    return 'EpisodeProgress(seriesId: $seriesId, episodeId: $episodeId, position: $position, totalDuration: $totalDuration, isCompleted: $isCompleted, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EpisodeProgressImpl &&
            (identical(other.seriesId, seriesId) ||
                other.seriesId == seriesId) &&
            (identical(other.episodeId, episodeId) ||
                other.episodeId == episodeId) &&
            (identical(other.position, position) ||
                other.position == position) &&
            (identical(other.totalDuration, totalDuration) ||
                other.totalDuration == totalDuration) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    seriesId,
    episodeId,
    position,
    totalDuration,
    isCompleted,
    updatedAt,
  );

  /// Create a copy of EpisodeProgress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EpisodeProgressImplCopyWith<_$EpisodeProgressImpl> get copyWith =>
      __$$EpisodeProgressImplCopyWithImpl<_$EpisodeProgressImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$EpisodeProgressImplToJson(this);
  }
}

abstract class _EpisodeProgress implements EpisodeProgress {
  const factory _EpisodeProgress({
    required final String seriesId,
    required final String episodeId,
    required final Duration position,
    final Duration? totalDuration,
    final bool isCompleted,
    required final DateTime updatedAt,
  }) = _$EpisodeProgressImpl;

  factory _EpisodeProgress.fromJson(Map<String, dynamic> json) =
      _$EpisodeProgressImpl.fromJson;

  @override
  String get seriesId;
  @override
  String get episodeId;
  @override
  Duration get position;
  @override
  Duration? get totalDuration;
  @override
  bool get isCompleted;
  @override
  DateTime get updatedAt;

  /// Create a copy of EpisodeProgress
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EpisodeProgressImplCopyWith<_$EpisodeProgressImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
