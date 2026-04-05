class AudioTrack {
  const AudioTrack({
    required this.id,
    required this.languageCode,
    required this.label,
    this.isDefault = false,
  });

  final String id;
  final String languageCode;
  final String label;
  final bool isDefault;
}

enum SubtitleTrackKind {
  full,
  forced,
  closedCaption,
}

class SubtitleTrack {
  const SubtitleTrack({
    required this.id,
    required this.languageCode,
    required this.label,
    this.kind = SubtitleTrackKind.full,
  });

  final String id;
  final String languageCode;
  final String label;
  final SubtitleTrackKind kind;
}
