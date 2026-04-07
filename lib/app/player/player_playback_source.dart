import 'package:flutter/foundation.dart';

enum PlayerPlaybackSourceKind {
  remoteHls,
  localHlsManifest,
  localFile,
}

@immutable
class PlayerPlaybackSource {
  const PlayerPlaybackSource({
    required this.sourceUri,
    required this.qualityLabel,
    required this.kind,
  });

  final String sourceUri;
  final String qualityLabel;
  final PlayerPlaybackSourceKind kind;

  String get streamUri => sourceUri;

  bool get isOffline => kind != PlayerPlaybackSourceKind.remoteHls;
}
