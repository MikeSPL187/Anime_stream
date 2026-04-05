import 'package:flutter/foundation.dart';

import '../../domain/models/episode.dart';
import '../../domain/models/series.dart';

@immutable
class SeriesDetailsData {
  SeriesDetailsData({required this.series, required List<Episode> episodes})
    : episodes = List.unmodifiable(episodes);

  final Series series;
  final List<Episode> episodes;
}
