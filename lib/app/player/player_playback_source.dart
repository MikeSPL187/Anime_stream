import 'package:flutter/foundation.dart';

@immutable
class PlayerPlaybackSource {
  const PlayerPlaybackSource({
    required this.streamUri,
    required this.qualityLabel,
  });

  final String streamUri;
  final String qualityLabel;
}
