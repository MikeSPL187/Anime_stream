import 'availability_state.dart';
import 'media_track.dart';
import 'season.dart';

enum SeriesLifecycleStatus {
  ongoing,
  completed,
  upcoming,
  hiatus,
  unknown,
}

class Series {
  const Series({
    required this.id,
    required this.slug,
    required this.title,
    required this.availability,
    this.originalTitle,
    this.synopsis,
    this.posterImageUrl,
    this.bannerImageUrl,
    this.genres = const [],
    this.releaseYear,
    this.lifecycleStatus = SeriesLifecycleStatus.unknown,
    this.seasons = const [],
    this.availableAudioTracks = const [],
    this.availableSubtitleTracks = const [],
    this.lastUpdatedAt,
  });

  final String id;
  final String slug;
  final String title;
  final String? originalTitle;
  final String? synopsis;
  final String? posterImageUrl;
  final String? bannerImageUrl;
  final List<String> genres;
  final int? releaseYear;
  final SeriesLifecycleStatus lifecycleStatus;
  final List<Season> seasons;
  final List<AudioTrack> availableAudioTracks;
  final List<SubtitleTrack> availableSubtitleTracks;
  final AvailabilityState availability;
  final DateTime? lastUpdatedAt;
}
