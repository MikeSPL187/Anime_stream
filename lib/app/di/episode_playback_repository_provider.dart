import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/anilibria/anilibria_episode_playback_repository.dart';
import '../../domain/repositories/episode_playback_repository.dart';
import 'series_repository_provider.dart';

final episodePlaybackRepositoryProvider = Provider<EpisodePlaybackRepository>((
  ref,
) {
  return AnilibriaEpisodePlaybackRepository(
    remoteDataSource: ref.watch(anilibriaRemoteDataSourceProvider),
  );
});
