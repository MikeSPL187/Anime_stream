import '../models/playback_preferences.dart';

abstract interface class PlaybackRepository {
  Future<PlaybackPreferences> getPlaybackPreferences();

  Future<void> savePlaybackPreferences(PlaybackPreferences preferences);
}
