import 'availability_state.dart';
import 'episode.dart';

class Season {
  const Season({
    required this.id,
    required this.seriesId,
    required this.seasonNumber,
    required this.title,
    required this.availability,
    this.synopsis,
    this.posterImageUrl,
    this.episodes = const [],
  });

  final String id;
  final String seriesId;
  final int seasonNumber;
  final String title;
  final String? synopsis;
  final String? posterImageUrl;
  final List<Episode> episodes;
  final AvailabilityState availability;
}
