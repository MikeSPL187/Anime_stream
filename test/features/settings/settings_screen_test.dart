import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anime_stream_app/app/di/playback_repository_provider.dart';
import 'package:anime_stream_app/domain/models/playback_preferences.dart';
import 'package:anime_stream_app/domain/repositories/playback_repository.dart';
import 'package:anime_stream_app/features/settings/settings_screen.dart';

void main() {
  testWidgets('SettingsScreen persists default download quality changes', (
    tester,
  ) async {
    final repository = _RecordingPlaybackRepository(
      preferences: const PlaybackPreferences(defaultDownloadQuality: '1080p'),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [playbackRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Default download quality'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Default download quality'), findsOneWidget);
    expect(find.text('1080p'), findsOneWidget);
    expect(find.text('720p'), findsOneWidget);

    await tester.tap(find.text('720p'));
    await tester.pumpAndSettle();

    expect(repository.savedPreferences.last.defaultDownloadQuality, '720p');
  });
}

class _RecordingPlaybackRepository implements PlaybackRepository {
  _RecordingPlaybackRepository({required this.preferences});

  PlaybackPreferences preferences;
  final List<PlaybackPreferences> savedPreferences = [];

  @override
  Future<PlaybackPreferences> getPlaybackPreferences() async => preferences;

  @override
  Future<void> savePlaybackPreferences(PlaybackPreferences preferences) async {
    savedPreferences.add(preferences);
    this.preferences = preferences;
  }
}
