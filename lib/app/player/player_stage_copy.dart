enum PlayerPlaybackOpeningPhase {
  openingStream,
  switchingQuality,
  recoveringPlayback,
  retryingPlayback,
}

class PlayerPlaybackStageCopy {
  const PlayerPlaybackStageCopy({
    required this.title,
    required this.message,
    required this.statusLabel,
    required this.statusText,
  });

  final String title;
  final String message;
  final String statusLabel;
  final String statusText;
}

PlayerPlaybackStageCopy buildPlayerOpeningStageCopy({
  required PlayerPlaybackOpeningPhase phase,
  required String qualityLabel,
}) {
  return switch (phase) {
    PlayerPlaybackOpeningPhase.openingStream => PlayerPlaybackStageCopy(
      title: 'Opening Stream',
      message: 'Opening $qualityLabel playback for this episode.',
      statusLabel: 'Opening',
      statusText: 'Player is opening this stream.',
    ),
    PlayerPlaybackOpeningPhase.switchingQuality => PlayerPlaybackStageCopy(
      title: 'Switching Quality',
      message:
          'Moving playback to $qualityLabel. Your position will be restored if the stream opens.',
      statusLabel: 'Switching',
      statusText: 'Player is switching to a different stream quality.',
    ),
    PlayerPlaybackOpeningPhase.recoveringPlayback => PlayerPlaybackStageCopy(
      title: 'Recovering Playback',
      message:
          'The current stream failed. Trying $qualityLabel to keep playback running.',
      statusLabel: 'Recovering',
      statusText: 'Player is recovering on another available stream.',
    ),
    PlayerPlaybackOpeningPhase.retryingPlayback => PlayerPlaybackStageCopy(
      title: 'Retrying Stream',
      message: 'Trying $qualityLabel again for this episode.',
      statusLabel: 'Retrying',
      statusText: 'Player is retrying the current stream.',
    ),
  };
}
