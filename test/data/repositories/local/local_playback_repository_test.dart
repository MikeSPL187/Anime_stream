import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:anime_stream_app/data/local/json_playback_preferences_store.dart';
import 'package:anime_stream_app/data/repositories/local/local_playback_repository.dart';
import 'package:anime_stream_app/domain/models/playback_preferences.dart';

void main() {
  group('LocalPlaybackRepository', () {
    test('returns default preferences when no stored payload exists', () async {
      final sandbox = await Directory.systemTemp.createTemp(
        'playback-repository-defaults',
      );
      addTearDown(() async {
        if (await sandbox.exists()) {
          await sandbox.delete(recursive: true);
        }
      });

      final repository = LocalPlaybackRepository(
        playbackPreferencesStore: JsonPlaybackPreferencesStore(
          directoryProvider: () async => sandbox,
          relativeFilePath: 'preferences.json',
        ),
      );

      final preferences = await repository.getPlaybackPreferences();

      expect(preferences, const PlaybackPreferences());
    });

    test('persists and restores saved playback preferences', () async {
      final sandbox = await Directory.systemTemp.createTemp(
        'playback-repository-roundtrip',
      );
      addTearDown(() async {
        if (await sandbox.exists()) {
          await sandbox.delete(recursive: true);
        }
      });

      final repository = LocalPlaybackRepository(
        playbackPreferencesStore: JsonPlaybackPreferencesStore(
          directoryProvider: () async => sandbox,
          relativeFilePath: 'preferences.json',
        ),
      );
      const savedPreferences = PlaybackPreferences(
        autoplayNextEpisode: false,
        defaultPlaybackSpeed: 1.25,
      );

      await repository.savePlaybackPreferences(savedPreferences);

      final restoredPreferences = await repository.getPlaybackPreferences();

      expect(restoredPreferences, savedPreferences);
    });
  });
}
