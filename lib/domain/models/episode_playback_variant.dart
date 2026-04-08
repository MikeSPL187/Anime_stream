import 'package:flutter/foundation.dart';

@immutable
class EpisodePlaybackVariant {
  const EpisodePlaybackVariant({
    required this.sourceUri,
    required this.qualityLabel,
  });

  final String sourceUri;
  final String qualityLabel;
}
