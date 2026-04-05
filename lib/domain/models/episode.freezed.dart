// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'episode.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Episode _$EpisodeFromJson(Map<String, dynamic> json) {
  return _Episode.fromJson(json);
}

/// @nodoc
mixin _$Episode {
  String get id => throw _privateConstructorUsedError;
  String get seriesId => throw _privateConstructorUsedError;
  int get sortOrder => throw _privateConstructorUsedError;
  String get numberLabel => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get synopsis => throw _privateConstructorUsedError;
  Duration? get duration => throw _privateConstructorUsedError;
  String? get thumbnailImageUrl => throw _privateConstructorUsedError;
  DateTime? get airDate => throw _privateConstructorUsedError;
  bool get isFiller => throw _privateConstructorUsedError;
  bool get isRecap => throw _privateConstructorUsedError;
  AvailabilityState get availability => throw _privateConstructorUsedError;
  List<String> get availableAudioLanguageCodes =>
      throw _privateConstructorUsedError;
  List<String> get availableSubtitleLanguageCodes =>
      throw _privateConstructorUsedError;

  /// Serializes this Episode to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Episode
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $EpisodeCopyWith<Episode> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $EpisodeCopyWith<$Res> {
  factory $EpisodeCopyWith(Episode value, $Res Function(Episode) then) =
      _$EpisodeCopyWithImpl<$Res, Episode>;
  @useResult
  $Res call({
    String id,
    String seriesId,
    int sortOrder,
    String numberLabel,
    String title,
    String? synopsis,
    Duration? duration,
    String? thumbnailImageUrl,
    DateTime? airDate,
    bool isFiller,
    bool isRecap,
    AvailabilityState availability,
    List<String> availableAudioLanguageCodes,
    List<String> availableSubtitleLanguageCodes,
  });

  $AvailabilityStateCopyWith<$Res> get availability;
}

/// @nodoc
class _$EpisodeCopyWithImpl<$Res, $Val extends Episode>
    implements $EpisodeCopyWith<$Res> {
  _$EpisodeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Episode
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? seriesId = null,
    Object? sortOrder = null,
    Object? numberLabel = null,
    Object? title = null,
    Object? synopsis = freezed,
    Object? duration = freezed,
    Object? thumbnailImageUrl = freezed,
    Object? airDate = freezed,
    Object? isFiller = null,
    Object? isRecap = null,
    Object? availability = null,
    Object? availableAudioLanguageCodes = null,
    Object? availableSubtitleLanguageCodes = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            seriesId: null == seriesId
                ? _value.seriesId
                : seriesId // ignore: cast_nullable_to_non_nullable
                      as String,
            sortOrder: null == sortOrder
                ? _value.sortOrder
                : sortOrder // ignore: cast_nullable_to_non_nullable
                      as int,
            numberLabel: null == numberLabel
                ? _value.numberLabel
                : numberLabel // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            synopsis: freezed == synopsis
                ? _value.synopsis
                : synopsis // ignore: cast_nullable_to_non_nullable
                      as String?,
            duration: freezed == duration
                ? _value.duration
                : duration // ignore: cast_nullable_to_non_nullable
                      as Duration?,
            thumbnailImageUrl: freezed == thumbnailImageUrl
                ? _value.thumbnailImageUrl
                : thumbnailImageUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            airDate: freezed == airDate
                ? _value.airDate
                : airDate // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
            isFiller: null == isFiller
                ? _value.isFiller
                : isFiller // ignore: cast_nullable_to_non_nullable
                      as bool,
            isRecap: null == isRecap
                ? _value.isRecap
                : isRecap // ignore: cast_nullable_to_non_nullable
                      as bool,
            availability: null == availability
                ? _value.availability
                : availability // ignore: cast_nullable_to_non_nullable
                      as AvailabilityState,
            availableAudioLanguageCodes: null == availableAudioLanguageCodes
                ? _value.availableAudioLanguageCodes
                : availableAudioLanguageCodes // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            availableSubtitleLanguageCodes:
                null == availableSubtitleLanguageCodes
                ? _value.availableSubtitleLanguageCodes
                : availableSubtitleLanguageCodes // ignore: cast_nullable_to_non_nullable
                      as List<String>,
          )
          as $Val,
    );
  }

  /// Create a copy of Episode
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $AvailabilityStateCopyWith<$Res> get availability {
    return $AvailabilityStateCopyWith<$Res>(_value.availability, (value) {
      return _then(_value.copyWith(availability: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$EpisodeImplCopyWith<$Res> implements $EpisodeCopyWith<$Res> {
  factory _$$EpisodeImplCopyWith(
    _$EpisodeImpl value,
    $Res Function(_$EpisodeImpl) then,
  ) = __$$EpisodeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String seriesId,
    int sortOrder,
    String numberLabel,
    String title,
    String? synopsis,
    Duration? duration,
    String? thumbnailImageUrl,
    DateTime? airDate,
    bool isFiller,
    bool isRecap,
    AvailabilityState availability,
    List<String> availableAudioLanguageCodes,
    List<String> availableSubtitleLanguageCodes,
  });

  @override
  $AvailabilityStateCopyWith<$Res> get availability;
}

/// @nodoc
class __$$EpisodeImplCopyWithImpl<$Res>
    extends _$EpisodeCopyWithImpl<$Res, _$EpisodeImpl>
    implements _$$EpisodeImplCopyWith<$Res> {
  __$$EpisodeImplCopyWithImpl(
    _$EpisodeImpl _value,
    $Res Function(_$EpisodeImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Episode
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? seriesId = null,
    Object? sortOrder = null,
    Object? numberLabel = null,
    Object? title = null,
    Object? synopsis = freezed,
    Object? duration = freezed,
    Object? thumbnailImageUrl = freezed,
    Object? airDate = freezed,
    Object? isFiller = null,
    Object? isRecap = null,
    Object? availability = null,
    Object? availableAudioLanguageCodes = null,
    Object? availableSubtitleLanguageCodes = null,
  }) {
    return _then(
      _$EpisodeImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        seriesId: null == seriesId
            ? _value.seriesId
            : seriesId // ignore: cast_nullable_to_non_nullable
                  as String,
        sortOrder: null == sortOrder
            ? _value.sortOrder
            : sortOrder // ignore: cast_nullable_to_non_nullable
                  as int,
        numberLabel: null == numberLabel
            ? _value.numberLabel
            : numberLabel // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        synopsis: freezed == synopsis
            ? _value.synopsis
            : synopsis // ignore: cast_nullable_to_non_nullable
                  as String?,
        duration: freezed == duration
            ? _value.duration
            : duration // ignore: cast_nullable_to_non_nullable
                  as Duration?,
        thumbnailImageUrl: freezed == thumbnailImageUrl
            ? _value.thumbnailImageUrl
            : thumbnailImageUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        airDate: freezed == airDate
            ? _value.airDate
            : airDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        isFiller: null == isFiller
            ? _value.isFiller
            : isFiller // ignore: cast_nullable_to_non_nullable
                  as bool,
        isRecap: null == isRecap
            ? _value.isRecap
            : isRecap // ignore: cast_nullable_to_non_nullable
                  as bool,
        availability: null == availability
            ? _value.availability
            : availability // ignore: cast_nullable_to_non_nullable
                  as AvailabilityState,
        availableAudioLanguageCodes: null == availableAudioLanguageCodes
            ? _value._availableAudioLanguageCodes
            : availableAudioLanguageCodes // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        availableSubtitleLanguageCodes: null == availableSubtitleLanguageCodes
            ? _value._availableSubtitleLanguageCodes
            : availableSubtitleLanguageCodes // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$EpisodeImpl implements _Episode {
  const _$EpisodeImpl({
    required this.id,
    required this.seriesId,
    required this.sortOrder,
    required this.numberLabel,
    required this.title,
    this.synopsis,
    this.duration,
    this.thumbnailImageUrl,
    this.airDate,
    this.isFiller = false,
    this.isRecap = false,
    this.availability = const AvailabilityState(),
    final List<String> availableAudioLanguageCodes = const <String>[],
    final List<String> availableSubtitleLanguageCodes = const <String>[],
  }) : _availableAudioLanguageCodes = availableAudioLanguageCodes,
       _availableSubtitleLanguageCodes = availableSubtitleLanguageCodes;

  factory _$EpisodeImpl.fromJson(Map<String, dynamic> json) =>
      _$$EpisodeImplFromJson(json);

  @override
  final String id;
  @override
  final String seriesId;
  @override
  final int sortOrder;
  @override
  final String numberLabel;
  @override
  final String title;
  @override
  final String? synopsis;
  @override
  final Duration? duration;
  @override
  final String? thumbnailImageUrl;
  @override
  final DateTime? airDate;
  @override
  @JsonKey()
  final bool isFiller;
  @override
  @JsonKey()
  final bool isRecap;
  @override
  @JsonKey()
  final AvailabilityState availability;
  final List<String> _availableAudioLanguageCodes;
  @override
  @JsonKey()
  List<String> get availableAudioLanguageCodes {
    if (_availableAudioLanguageCodes is EqualUnmodifiableListView)
      return _availableAudioLanguageCodes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_availableAudioLanguageCodes);
  }

  final List<String> _availableSubtitleLanguageCodes;
  @override
  @JsonKey()
  List<String> get availableSubtitleLanguageCodes {
    if (_availableSubtitleLanguageCodes is EqualUnmodifiableListView)
      return _availableSubtitleLanguageCodes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_availableSubtitleLanguageCodes);
  }

  @override
  String toString() {
    return 'Episode(id: $id, seriesId: $seriesId, sortOrder: $sortOrder, numberLabel: $numberLabel, title: $title, synopsis: $synopsis, duration: $duration, thumbnailImageUrl: $thumbnailImageUrl, airDate: $airDate, isFiller: $isFiller, isRecap: $isRecap, availability: $availability, availableAudioLanguageCodes: $availableAudioLanguageCodes, availableSubtitleLanguageCodes: $availableSubtitleLanguageCodes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$EpisodeImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.seriesId, seriesId) ||
                other.seriesId == seriesId) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            (identical(other.numberLabel, numberLabel) ||
                other.numberLabel == numberLabel) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.synopsis, synopsis) ||
                other.synopsis == synopsis) &&
            (identical(other.duration, duration) ||
                other.duration == duration) &&
            (identical(other.thumbnailImageUrl, thumbnailImageUrl) ||
                other.thumbnailImageUrl == thumbnailImageUrl) &&
            (identical(other.airDate, airDate) || other.airDate == airDate) &&
            (identical(other.isFiller, isFiller) ||
                other.isFiller == isFiller) &&
            (identical(other.isRecap, isRecap) || other.isRecap == isRecap) &&
            (identical(other.availability, availability) ||
                other.availability == availability) &&
            const DeepCollectionEquality().equals(
              other._availableAudioLanguageCodes,
              _availableAudioLanguageCodes,
            ) &&
            const DeepCollectionEquality().equals(
              other._availableSubtitleLanguageCodes,
              _availableSubtitleLanguageCodes,
            ));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    seriesId,
    sortOrder,
    numberLabel,
    title,
    synopsis,
    duration,
    thumbnailImageUrl,
    airDate,
    isFiller,
    isRecap,
    availability,
    const DeepCollectionEquality().hash(_availableAudioLanguageCodes),
    const DeepCollectionEquality().hash(_availableSubtitleLanguageCodes),
  );

  /// Create a copy of Episode
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$EpisodeImplCopyWith<_$EpisodeImpl> get copyWith =>
      __$$EpisodeImplCopyWithImpl<_$EpisodeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$EpisodeImplToJson(this);
  }
}

abstract class _Episode implements Episode {
  const factory _Episode({
    required final String id,
    required final String seriesId,
    required final int sortOrder,
    required final String numberLabel,
    required final String title,
    final String? synopsis,
    final Duration? duration,
    final String? thumbnailImageUrl,
    final DateTime? airDate,
    final bool isFiller,
    final bool isRecap,
    final AvailabilityState availability,
    final List<String> availableAudioLanguageCodes,
    final List<String> availableSubtitleLanguageCodes,
  }) = _$EpisodeImpl;

  factory _Episode.fromJson(Map<String, dynamic> json) = _$EpisodeImpl.fromJson;

  @override
  String get id;
  @override
  String get seriesId;
  @override
  int get sortOrder;
  @override
  String get numberLabel;
  @override
  String get title;
  @override
  String? get synopsis;
  @override
  Duration? get duration;
  @override
  String? get thumbnailImageUrl;
  @override
  DateTime? get airDate;
  @override
  bool get isFiller;
  @override
  bool get isRecap;
  @override
  AvailabilityState get availability;
  @override
  List<String> get availableAudioLanguageCodes;
  @override
  List<String> get availableSubtitleLanguageCodes;

  /// Create a copy of Episode
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$EpisodeImplCopyWith<_$EpisodeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
