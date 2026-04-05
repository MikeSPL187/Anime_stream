class PlaybackPreferences {
  const PlaybackPreferences({
    this.preferredAudioLanguageCodes = const [],
    this.preferredSubtitleLanguageCodes = const [],
    this.autoplayNextEpisode = true,
    this.preferSubtitles = false,
    this.defaultPlaybackSpeed = 1.0,
  });

  final List<String> preferredAudioLanguageCodes;
  final List<String> preferredSubtitleLanguageCodes;
  final bool autoplayNextEpisode;
  final bool preferSubtitles;
  final double defaultPlaybackSpeed;
}
