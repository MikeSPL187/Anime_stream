import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/playback_preferences.dart';
import '../di/playback_repository_provider.dart';

final playbackPreferencesControllerProvider =
    AsyncNotifierProvider<PlaybackPreferencesController, PlaybackPreferences>(
      PlaybackPreferencesController.new,
    );

final playbackPreferencesProvider = Provider<PlaybackPreferences>((ref) {
  return ref.watch(playbackPreferencesControllerProvider).valueOrNull ??
      const PlaybackPreferences();
});

class PlaybackPreferencesController extends AsyncNotifier<PlaybackPreferences> {
  @override
  Future<PlaybackPreferences> build() {
    return ref.watch(playbackRepositoryProvider).getPlaybackPreferences();
  }

  Future<void> setAutoplayNextEpisode(bool enabled) async {
    final current = state.valueOrNull ?? const PlaybackPreferences();
    final updated = current.copyWith(autoplayNextEpisode: enabled);
    await _persist(updated, fallback: current);
  }

  Future<void> setDefaultPlaybackSpeed(double playbackRate) async {
    final current = state.valueOrNull ?? const PlaybackPreferences();
    final updated = current.copyWith(defaultPlaybackSpeed: playbackRate);
    await _persist(updated, fallback: current);
  }

  Future<void> setDefaultDownloadQuality(String qualityLabel) async {
    final current = state.valueOrNull ?? const PlaybackPreferences();
    final updated = current.copyWith(
      defaultDownloadQuality: normalizeDownloadQualityLabel(qualityLabel),
    );
    await _persist(updated, fallback: current);
  }

  Future<void> _persist(
    PlaybackPreferences updated, {
    required PlaybackPreferences fallback,
  }) async {
    state = AsyncData(updated);

    try {
      await ref
          .read(playbackRepositoryProvider)
          .savePlaybackPreferences(updated);
    } catch (error, stackTrace) {
      state = AsyncData(fallback);
      Error.throwWithStackTrace(error, stackTrace);
    }
  }
}
