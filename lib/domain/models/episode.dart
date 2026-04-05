import 'availability_state.dart';
import 'media_track.dart';

class Episode {
  const Episode({
    required this.id,
    required this.seriesId,
    required this.seasonId,
    required this.sortOrder,
    required this.numberLabel,
    required this.title,
    required this.availability,
    this.synopsis,
    this.duration,
    this.thumbnailImageUrl,
    this.airDate,
    this.isFiller = false,
    this.isRecap = false,
    this.audioTracks = const [],
    this.subtitleTracks = const [],
  });

  final String id;
  final String seriesId;
  final String seasonId;
  final int sortOrder;
  final String numberLabel;
  final String title;
  final String? synopsis;
  final Duration? duration;
  final String? thumbnailImageUrl;
  final DateTime? airDate;
  final bool isFiller;
  final bool isRecap;
  final AvailabilityState availability;
  final List<AudioTrack> audioTracks;
  final List<SubtitleTrack> subtitleTracks;
}
