import '../models/playback_preferences.dart';

@Deprecated('Use PlaybackRepository for stable playback preference contracts.')
abstract interface class PlaybackPreferencesRepository {
  Future<PlaybackPreferences> getPlaybackPreferences();

  Future<void> savePlaybackPreferences(PlaybackPreferences preferences);
}
