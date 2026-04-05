import '../models/playback_preferences.dart';

abstract interface class PlaybackPreferencesRepository {
  Future<PlaybackPreferences> getPlaybackPreferences();

  Future<void> savePlaybackPreferences(PlaybackPreferences preferences);
}
