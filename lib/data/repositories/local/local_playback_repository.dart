import '../../../domain/models/playback_preferences.dart';
import '../../../domain/repositories/playback_repository.dart';
import '../../local/json_playback_preferences_store.dart';

class LocalPlaybackRepository implements PlaybackRepository {
  LocalPlaybackRepository({
    required JsonPlaybackPreferencesStore playbackPreferencesStore,
  }) : _playbackPreferencesStore = playbackPreferencesStore;

  final JsonPlaybackPreferencesStore _playbackPreferencesStore;

  @override
  Future<PlaybackPreferences> getPlaybackPreferences() async {
    final payload = await _playbackPreferencesStore.read();
    if (payload.isEmpty) {
      return const PlaybackPreferences();
    }

    try {
      final preferences = PlaybackPreferences.fromJson(payload);
      return preferences.copyWith(
        defaultDownloadQuality: normalizeDownloadQualityLabel(
          preferences.defaultDownloadQuality,
        ),
      );
    } on FormatException {
      return const PlaybackPreferences();
    } on TypeError {
      return const PlaybackPreferences();
    }
  }

  @override
  Future<void> savePlaybackPreferences(PlaybackPreferences preferences) async {
    await _playbackPreferencesStore.write(preferences.toJson());
  }
}
