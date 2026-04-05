// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'series.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Series _$SeriesFromJson(Map<String, dynamic> json) {
  return _Series.fromJson(json);
}

/// @nodoc
mixin _$Series {
  String get id => throw _privateConstructorUsedError;
  String get slug => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  String? get originalTitle => throw _privateConstructorUsedError;
  String? get synopsis => throw _privateConstructorUsedError;
  String? get posterImageUrl => throw _privateConstructorUsedError;
  String? get bannerImageUrl => throw _privateConstructorUsedError;
  List<String> get genres => throw _privateConstructorUsedError;
  int? get releaseYear => throw _privateConstructorUsedError;
  SeriesStatus get status => throw _privateConstructorUsedError;
  AvailabilityState get availability => throw _privateConstructorUsedError;
  DateTime? get lastUpdatedAt => throw _privateConstructorUsedError;

  /// Serializes this Series to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Series
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $SeriesCopyWith<Series> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SeriesCopyWith<$Res> {
  factory $SeriesCopyWith(Series value, $Res Function(Series) then) =
      _$SeriesCopyWithImpl<$Res, Series>;
  @useResult
  $Res call({
    String id,
    String slug,
    String title,
    String? originalTitle,
    String? synopsis,
    String? posterImageUrl,
    String? bannerImageUrl,
    List<String> genres,
    int? releaseYear,
    SeriesStatus status,
    AvailabilityState availability,
    DateTime? lastUpdatedAt,
  });

  $AvailabilityStateCopyWith<$Res> get availability;
}

/// @nodoc
class _$SeriesCopyWithImpl<$Res, $Val extends Series>
    implements $SeriesCopyWith<$Res> {
  _$SeriesCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Series
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? slug = null,
    Object? title = null,
    Object? originalTitle = freezed,
    Object? synopsis = freezed,
    Object? posterImageUrl = freezed,
    Object? bannerImageUrl = freezed,
    Object? genres = null,
    Object? releaseYear = freezed,
    Object? status = null,
    Object? availability = null,
    Object? lastUpdatedAt = freezed,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            slug: null == slug
                ? _value.slug
                : slug // ignore: cast_nullable_to_non_nullable
                      as String,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            originalTitle: freezed == originalTitle
                ? _value.originalTitle
                : originalTitle // ignore: cast_nullable_to_non_nullable
                      as String?,
            synopsis: freezed == synopsis
                ? _value.synopsis
                : synopsis // ignore: cast_nullable_to_non_nullable
                      as String?,
            posterImageUrl: freezed == posterImageUrl
                ? _value.posterImageUrl
                : posterImageUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            bannerImageUrl: freezed == bannerImageUrl
                ? _value.bannerImageUrl
                : bannerImageUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            genres: null == genres
                ? _value.genres
                : genres // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            releaseYear: freezed == releaseYear
                ? _value.releaseYear
                : releaseYear // ignore: cast_nullable_to_non_nullable
                      as int?,
            status: null == status
                ? _value.status
                : status // ignore: cast_nullable_to_non_nullable
                      as SeriesStatus,
            availability: null == availability
                ? _value.availability
                : availability // ignore: cast_nullable_to_non_nullable
                      as AvailabilityState,
            lastUpdatedAt: freezed == lastUpdatedAt
                ? _value.lastUpdatedAt
                : lastUpdatedAt // ignore: cast_nullable_to_non_nullable
                      as DateTime?,
          )
          as $Val,
    );
  }

  /// Create a copy of Series
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
abstract class _$$SeriesImplCopyWith<$Res> implements $SeriesCopyWith<$Res> {
  factory _$$SeriesImplCopyWith(
    _$SeriesImpl value,
    $Res Function(_$SeriesImpl) then,
  ) = __$$SeriesImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String slug,
    String title,
    String? originalTitle,
    String? synopsis,
    String? posterImageUrl,
    String? bannerImageUrl,
    List<String> genres,
    int? releaseYear,
    SeriesStatus status,
    AvailabilityState availability,
    DateTime? lastUpdatedAt,
  });

  @override
  $AvailabilityStateCopyWith<$Res> get availability;
}

/// @nodoc
class __$$SeriesImplCopyWithImpl<$Res>
    extends _$SeriesCopyWithImpl<$Res, _$SeriesImpl>
    implements _$$SeriesImplCopyWith<$Res> {
  __$$SeriesImplCopyWithImpl(
    _$SeriesImpl _value,
    $Res Function(_$SeriesImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Series
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? slug = null,
    Object? title = null,
    Object? originalTitle = freezed,
    Object? synopsis = freezed,
    Object? posterImageUrl = freezed,
    Object? bannerImageUrl = freezed,
    Object? genres = null,
    Object? releaseYear = freezed,
    Object? status = null,
    Object? availability = null,
    Object? lastUpdatedAt = freezed,
  }) {
    return _then(
      _$SeriesImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        slug: null == slug
            ? _value.slug
            : slug // ignore: cast_nullable_to_non_nullable
                  as String,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        originalTitle: freezed == originalTitle
            ? _value.originalTitle
            : originalTitle // ignore: cast_nullable_to_non_nullable
                  as String?,
        synopsis: freezed == synopsis
            ? _value.synopsis
            : synopsis // ignore: cast_nullable_to_non_nullable
                  as String?,
        posterImageUrl: freezed == posterImageUrl
            ? _value.posterImageUrl
            : posterImageUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        bannerImageUrl: freezed == bannerImageUrl
            ? _value.bannerImageUrl
            : bannerImageUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        genres: null == genres
            ? _value._genres
            : genres // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        releaseYear: freezed == releaseYear
            ? _value.releaseYear
            : releaseYear // ignore: cast_nullable_to_non_nullable
                  as int?,
        status: null == status
            ? _value.status
            : status // ignore: cast_nullable_to_non_nullable
                  as SeriesStatus,
        availability: null == availability
            ? _value.availability
            : availability // ignore: cast_nullable_to_non_nullable
                  as AvailabilityState,
        lastUpdatedAt: freezed == lastUpdatedAt
            ? _value.lastUpdatedAt
            : lastUpdatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$SeriesImpl implements _Series {
  const _$SeriesImpl({
    required this.id,
    required this.slug,
    required this.title,
    this.originalTitle,
    this.synopsis,
    this.posterImageUrl,
    this.bannerImageUrl,
    final List<String> genres = const <String>[],
    this.releaseYear,
    this.status = SeriesStatus.unknown,
    this.availability = const AvailabilityState(),
    this.lastUpdatedAt,
  }) : _genres = genres;

  factory _$SeriesImpl.fromJson(Map<String, dynamic> json) =>
      _$$SeriesImplFromJson(json);

  @override
  final String id;
  @override
  final String slug;
  @override
  final String title;
  @override
  final String? originalTitle;
  @override
  final String? synopsis;
  @override
  final String? posterImageUrl;
  @override
  final String? bannerImageUrl;
  final List<String> _genres;
  @override
  @JsonKey()
  List<String> get genres {
    if (_genres is EqualUnmodifiableListView) return _genres;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_genres);
  }

  @override
  final int? releaseYear;
  @override
  @JsonKey()
  final SeriesStatus status;
  @override
  @JsonKey()
  final AvailabilityState availability;
  @override
  final DateTime? lastUpdatedAt;

  @override
  String toString() {
    return 'Series(id: $id, slug: $slug, title: $title, originalTitle: $originalTitle, synopsis: $synopsis, posterImageUrl: $posterImageUrl, bannerImageUrl: $bannerImageUrl, genres: $genres, releaseYear: $releaseYear, status: $status, availability: $availability, lastUpdatedAt: $lastUpdatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SeriesImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.slug, slug) || other.slug == slug) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.originalTitle, originalTitle) ||
                other.originalTitle == originalTitle) &&
            (identical(other.synopsis, synopsis) ||
                other.synopsis == synopsis) &&
            (identical(other.posterImageUrl, posterImageUrl) ||
                other.posterImageUrl == posterImageUrl) &&
            (identical(other.bannerImageUrl, bannerImageUrl) ||
                other.bannerImageUrl == bannerImageUrl) &&
            const DeepCollectionEquality().equals(other._genres, _genres) &&
            (identical(other.releaseYear, releaseYear) ||
                other.releaseYear == releaseYear) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.availability, availability) ||
                other.availability == availability) &&
            (identical(other.lastUpdatedAt, lastUpdatedAt) ||
                other.lastUpdatedAt == lastUpdatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    slug,
    title,
    originalTitle,
    synopsis,
    posterImageUrl,
    bannerImageUrl,
    const DeepCollectionEquality().hash(_genres),
    releaseYear,
    status,
    availability,
    lastUpdatedAt,
  );

  /// Create a copy of Series
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$SeriesImplCopyWith<_$SeriesImpl> get copyWith =>
      __$$SeriesImplCopyWithImpl<_$SeriesImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SeriesImplToJson(this);
  }
}

abstract class _Series implements Series {
  const factory _Series({
    required final String id,
    required final String slug,
    required final String title,
    final String? originalTitle,
    final String? synopsis,
    final String? posterImageUrl,
    final String? bannerImageUrl,
    final List<String> genres,
    final int? releaseYear,
    final SeriesStatus status,
    final AvailabilityState availability,
    final DateTime? lastUpdatedAt,
  }) = _$SeriesImpl;

  factory _Series.fromJson(Map<String, dynamic> json) = _$SeriesImpl.fromJson;

  @override
  String get id;
  @override
  String get slug;
  @override
  String get title;
  @override
  String? get originalTitle;
  @override
  String? get synopsis;
  @override
  String? get posterImageUrl;
  @override
  String? get bannerImageUrl;
  @override
  List<String> get genres;
  @override
  int? get releaseYear;
  @override
  SeriesStatus get status;
  @override
  AvailabilityState get availability;
  @override
  DateTime? get lastUpdatedAt;

  /// Create a copy of Series
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$SeriesImplCopyWith<_$SeriesImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
