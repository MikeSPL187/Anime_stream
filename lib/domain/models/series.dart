import 'package:freezed_annotation/freezed_annotation.dart';

import 'availability_state.dart';

part 'series.freezed.dart';
part 'series.g.dart';

enum SeriesStatus { ongoing, completed, upcoming, hiatus, unknown }

@freezed
class Series with _$Series {
  const factory Series({
    required String id,
    required String slug,
    required String title,
    String? originalTitle,
    String? synopsis,
    String? posterImageUrl,
    String? bannerImageUrl,
    @Default(<String>[]) List<String> genres,
    int? releaseYear,
    @Default(SeriesStatus.unknown) SeriesStatus status,
    @Default(AvailabilityState()) AvailabilityState availability,
    DateTime? lastUpdatedAt,
  }) = _Series;

  factory Series.fromJson(Map<String, dynamic> json) => _$SeriesFromJson(json);
}
