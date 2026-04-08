import '../models/episode_playback_variant.dart';
import '../models/episode_selector.dart';

abstract interface class EpisodePlaybackRepository {
  Future<List<EpisodePlaybackVariant>> getRemotePlaybackVariants({
    required String seriesId,
    required EpisodeSelector episodeSelector,
  });
}

class EpisodePlaybackLookupException implements Exception {
  const EpisodePlaybackLookupException(this.message);

  final String message;

  @override
  String toString() => message;
}
