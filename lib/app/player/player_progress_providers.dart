import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/episode_progress.dart';
import '../../domain/repositories/watch_system_repository.dart';
import '../../features/player/player_screen_context.dart';
import '../di/watch_system_repository_provider.dart';

final playerProgressControllerProvider = Provider<PlayerProgressController>((
  ref,
) {
  return PlayerProgressController(
    watchSystemRepository: ref.watch(watchSystemRepositoryProvider),
  );
});

class PlayerProgressController {
  PlayerProgressController({
    required WatchSystemRepository watchSystemRepository,
  }) : _watchSystemRepository = watchSystemRepository;

  static const minimumPersistedPosition = Duration(seconds: 5);

  final WatchSystemRepository _watchSystemRepository;

  Future<EpisodeProgress?> loadEpisodeProgress(
    PlayerScreenContext context,
  ) async {
    return _watchSystemRepository.getEpisodeProgress(
      seriesId: context.seriesId,
      episodeId: context.episodeId,
    );
  }

  Future<void> savePlaybackSnapshot(
    PlayerScreenContext context, {
    required Duration position,
    Duration? totalDuration,
    required bool isCompleted,
  }) async {
    var normalizedPosition = position < Duration.zero
        ? Duration.zero
        : position;
    final normalizedTotalDuration =
        totalDuration == null || totalDuration <= Duration.zero
        ? null
        : totalDuration;

    if (normalizedTotalDuration != null &&
        normalizedPosition > normalizedTotalDuration) {
      normalizedPosition = normalizedTotalDuration;
    }

    if (!isCompleted && normalizedPosition < minimumPersistedPosition) {
      return;
    }

    final persistedPosition = isCompleted && normalizedTotalDuration != null
        ? normalizedTotalDuration
        : normalizedPosition;

    await _watchSystemRepository.saveEpisodeProgress(
      EpisodeProgress(
        seriesId: context.seriesId,
        episodeId: context.episodeId,
        position: persistedPosition,
        totalDuration: normalizedTotalDuration,
        isCompleted: isCompleted,
        updatedAt: DateTime.now(),
      ),
    );
  }
}
