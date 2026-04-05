// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'playback_preferences.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

PlaybackPreferences _$PlaybackPreferencesFromJson(Map<String, dynamic> json) {
  return _PlaybackPreferences.fromJson(json);
}

/// @nodoc
mixin _$PlaybackPreferences {
  List<String> get preferredAudioLanguageCodes =>
      throw _privateConstructorUsedError;
  List<String> get preferredSubtitleLanguageCodes =>
      throw _privateConstructorUsedError;
  bool get autoplayNextEpisode => throw _privateConstructorUsedError;
  bool get preferSubtitles => throw _privateConstructorUsedError;
  double get defaultPlaybackSpeed => throw _privateConstructorUsedError;

  /// Serializes this PlaybackPreferences to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of PlaybackPreferences
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $PlaybackPreferencesCopyWith<PlaybackPreferences> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PlaybackPreferencesCopyWith<$Res> {
  factory $PlaybackPreferencesCopyWith(
    PlaybackPreferences value,
    $Res Function(PlaybackPreferences) then,
  ) = _$PlaybackPreferencesCopyWithImpl<$Res, PlaybackPreferences>;
  @useResult
  $Res call({
    List<String> preferredAudioLanguageCodes,
    List<String> preferredSubtitleLanguageCodes,
    bool autoplayNextEpisode,
    bool preferSubtitles,
    double defaultPlaybackSpeed,
  });
}

/// @nodoc
class _$PlaybackPreferencesCopyWithImpl<$Res, $Val extends PlaybackPreferences>
    implements $PlaybackPreferencesCopyWith<$Res> {
  _$PlaybackPreferencesCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of PlaybackPreferences
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? preferredAudioLanguageCodes = null,
    Object? preferredSubtitleLanguageCodes = null,
    Object? autoplayNextEpisode = null,
    Object? preferSubtitles = null,
    Object? defaultPlaybackSpeed = null,
  }) {
    return _then(
      _value.copyWith(
            preferredAudioLanguageCodes: null == preferredAudioLanguageCodes
                ? _value.preferredAudioLanguageCodes
                : preferredAudioLanguageCodes // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            preferredSubtitleLanguageCodes:
                null == preferredSubtitleLanguageCodes
                ? _value.preferredSubtitleLanguageCodes
                : preferredSubtitleLanguageCodes // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            autoplayNextEpisode: null == autoplayNextEpisode
                ? _value.autoplayNextEpisode
                : autoplayNextEpisode // ignore: cast_nullable_to_non_nullable
                      as bool,
            preferSubtitles: null == preferSubtitles
                ? _value.preferSubtitles
                : preferSubtitles // ignore: cast_nullable_to_non_nullable
                      as bool,
            defaultPlaybackSpeed: null == defaultPlaybackSpeed
                ? _value.defaultPlaybackSpeed
                : defaultPlaybackSpeed // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$PlaybackPreferencesImplCopyWith<$Res>
    implements $PlaybackPreferencesCopyWith<$Res> {
  factory _$$PlaybackPreferencesImplCopyWith(
    _$PlaybackPreferencesImpl value,
    $Res Function(_$PlaybackPreferencesImpl) then,
  ) = __$$PlaybackPreferencesImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<String> preferredAudioLanguageCodes,
    List<String> preferredSubtitleLanguageCodes,
    bool autoplayNextEpisode,
    bool preferSubtitles,
    double defaultPlaybackSpeed,
  });
}

/// @nodoc
class __$$PlaybackPreferencesImplCopyWithImpl<$Res>
    extends _$PlaybackPreferencesCopyWithImpl<$Res, _$PlaybackPreferencesImpl>
    implements _$$PlaybackPreferencesImplCopyWith<$Res> {
  __$$PlaybackPreferencesImplCopyWithImpl(
    _$PlaybackPreferencesImpl _value,
    $Res Function(_$PlaybackPreferencesImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of PlaybackPreferences
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? preferredAudioLanguageCodes = null,
    Object? preferredSubtitleLanguageCodes = null,
    Object? autoplayNextEpisode = null,
    Object? preferSubtitles = null,
    Object? defaultPlaybackSpeed = null,
  }) {
    return _then(
      _$PlaybackPreferencesImpl(
        preferredAudioLanguageCodes: null == preferredAudioLanguageCodes
            ? _value._preferredAudioLanguageCodes
            : preferredAudioLanguageCodes // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        preferredSubtitleLanguageCodes: null == preferredSubtitleLanguageCodes
            ? _value._preferredSubtitleLanguageCodes
            : preferredSubtitleLanguageCodes // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        autoplayNextEpisode: null == autoplayNextEpisode
            ? _value.autoplayNextEpisode
            : autoplayNextEpisode // ignore: cast_nullable_to_non_nullable
                  as bool,
        preferSubtitles: null == preferSubtitles
            ? _value.preferSubtitles
            : preferSubtitles // ignore: cast_nullable_to_non_nullable
                  as bool,
        defaultPlaybackSpeed: null == defaultPlaybackSpeed
            ? _value.defaultPlaybackSpeed
            : defaultPlaybackSpeed // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$PlaybackPreferencesImpl implements _PlaybackPreferences {
  const _$PlaybackPreferencesImpl({
    final List<String> preferredAudioLanguageCodes = const <String>[],
    final List<String> preferredSubtitleLanguageCodes = const <String>[],
    this.autoplayNextEpisode = true,
    this.preferSubtitles = false,
    this.defaultPlaybackSpeed = 1.0,
  }) : _preferredAudioLanguageCodes = preferredAudioLanguageCodes,
       _preferredSubtitleLanguageCodes = preferredSubtitleLanguageCodes;

  factory _$PlaybackPreferencesImpl.fromJson(Map<String, dynamic> json) =>
      _$$PlaybackPreferencesImplFromJson(json);

  final List<String> _preferredAudioLanguageCodes;
  @override
  @JsonKey()
  List<String> get preferredAudioLanguageCodes {
    if (_preferredAudioLanguageCodes is EqualUnmodifiableListView)
      return _preferredAudioLanguageCodes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_preferredAudioLanguageCodes);
  }

  final List<String> _preferredSubtitleLanguageCodes;
  @override
  @JsonKey()
  List<String> get preferredSubtitleLanguageCodes {
    if (_preferredSubtitleLanguageCodes is EqualUnmodifiableListView)
      return _preferredSubtitleLanguageCodes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_preferredSubtitleLanguageCodes);
  }

  @override
  @JsonKey()
  final bool autoplayNextEpisode;
  @override
  @JsonKey()
  final bool preferSubtitles;
  @override
  @JsonKey()
  final double defaultPlaybackSpeed;

  @override
  String toString() {
    return 'PlaybackPreferences(preferredAudioLanguageCodes: $preferredAudioLanguageCodes, preferredSubtitleLanguageCodes: $preferredSubtitleLanguageCodes, autoplayNextEpisode: $autoplayNextEpisode, preferSubtitles: $preferSubtitles, defaultPlaybackSpeed: $defaultPlaybackSpeed)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PlaybackPreferencesImpl &&
            const DeepCollectionEquality().equals(
              other._preferredAudioLanguageCodes,
              _preferredAudioLanguageCodes,
            ) &&
            const DeepCollectionEquality().equals(
              other._preferredSubtitleLanguageCodes,
              _preferredSubtitleLanguageCodes,
            ) &&
            (identical(other.autoplayNextEpisode, autoplayNextEpisode) ||
                other.autoplayNextEpisode == autoplayNextEpisode) &&
            (identical(other.preferSubtitles, preferSubtitles) ||
                other.preferSubtitles == preferSubtitles) &&
            (identical(other.defaultPlaybackSpeed, defaultPlaybackSpeed) ||
                other.defaultPlaybackSpeed == defaultPlaybackSpeed));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_preferredAudioLanguageCodes),
    const DeepCollectionEquality().hash(_preferredSubtitleLanguageCodes),
    autoplayNextEpisode,
    preferSubtitles,
    defaultPlaybackSpeed,
  );

  /// Create a copy of PlaybackPreferences
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$PlaybackPreferencesImplCopyWith<_$PlaybackPreferencesImpl> get copyWith =>
      __$$PlaybackPreferencesImplCopyWithImpl<_$PlaybackPreferencesImpl>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$$PlaybackPreferencesImplToJson(this);
  }
}

abstract class _PlaybackPreferences implements PlaybackPreferences {
  const factory _PlaybackPreferences({
    final List<String> preferredAudioLanguageCodes,
    final List<String> preferredSubtitleLanguageCodes,
    final bool autoplayNextEpisode,
    final bool preferSubtitles,
    final double defaultPlaybackSpeed,
  }) = _$PlaybackPreferencesImpl;

  factory _PlaybackPreferences.fromJson(Map<String, dynamic> json) =
      _$PlaybackPreferencesImpl.fromJson;

  @override
  List<String> get preferredAudioLanguageCodes;
  @override
  List<String> get preferredSubtitleLanguageCodes;
  @override
  bool get autoplayNextEpisode;
  @override
  bool get preferSubtitles;
  @override
  double get defaultPlaybackSpeed;

  /// Create a copy of PlaybackPreferences
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$PlaybackPreferencesImplCopyWith<_$PlaybackPreferencesImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
