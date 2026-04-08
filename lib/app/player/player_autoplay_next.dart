const playerAutoplayNextEpisodeDelay = Duration(seconds: 8);

String formatPlayerAutoplayNextEpisodeLabel({
  required String episodeNumberLabel,
  required int secondsRemaining,
}) {
  return 'Next Episode $episodeNumberLabel in ${secondsRemaining.clamp(1, playerAutoplayNextEpisodeDelay.inSeconds)}s';
}

String formatPlayerAutoplayNextEpisodeStatus(int secondsRemaining) {
  return 'Next episode starts in ${secondsRemaining.clamp(1, playerAutoplayNextEpisodeDelay.inSeconds)}s unless you stay here.';
}
