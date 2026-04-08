import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anime_stream_app/app/di/playback_repository_provider.dart';
import 'package:anime_stream_app/app/settings/playback_preferences_providers.dart';
import 'package:anime_stream_app/domain/models/playback_preferences.dart';
import 'package:anime_stream_app/domain/repositories/playback_repository.dart';

void main() {
  group('PlaybackPreferencesController', () {
    test('loads saved playback preferences from the repository seam', () async {
      final repository = _FakePlaybackRepository(
        preferences: const PlaybackPreferences(
          autoplayNextEpisode: false,
          defaultPlaybackSpeed: 1.25,
        ),
      );
      final container = ProviderContainer(
        overrides: [playbackRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final preferences = await container.read(
        playbackPreferencesControllerProvider.future,
      );

      expect(preferences.autoplayNextEpisode, isFalse);
      expect(preferences.defaultPlaybackSpeed, 1.25);
    });

    test('persists autoplay and playback speed updates', () async {
      final repository = _FakePlaybackRepository(
        preferences: const PlaybackPreferences(),
      );
      final container = ProviderContainer(
        overrides: [playbackRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      await container.read(playbackPreferencesControllerProvider.future);

      await container
          .read(playbackPreferencesControllerProvider.notifier)
          .setAutoplayNextEpisode(false);
      await container
          .read(playbackPreferencesControllerProvider.notifier)
          .setDefaultPlaybackSpeed(1.5);

      final preferences = container.read(playbackPreferencesProvider);

      expect(preferences.autoplayNextEpisode, isFalse);
      expect(preferences.defaultPlaybackSpeed, 1.5);
      expect(repository.savedPreferences, [
        const PlaybackPreferences(autoplayNextEpisode: false),
        const PlaybackPreferences(
          autoplayNextEpisode: false,
          defaultPlaybackSpeed: 1.5,
        ),
      ]);
    });
  });
}

class _FakePlaybackRepository implements PlaybackRepository {
  _FakePlaybackRepository({required this.preferences});

  PlaybackPreferences preferences;
  final List<PlaybackPreferences> savedPreferences = [];

  @override
  Future<PlaybackPreferences> getPlaybackPreferences() async {
    return preferences;
  }

  @override
  Future<void> savePlaybackPreferences(PlaybackPreferences preferences) async {
    savedPreferences.add(preferences);
    this.preferences = preferences;
  }
}
