import 'package:flutter/foundation.dart';

enum PlayerPlaybackSourceKind { remoteHls, localHlsManifest, localFile }

@immutable
class PlayerPlaybackVariant {
  const PlayerPlaybackVariant({
    required this.sourceUri,
    required this.qualityLabel,
    required this.kind,
  });

  final String sourceUri;
  final String qualityLabel;
  final PlayerPlaybackSourceKind kind;

  bool get isOffline => kind != PlayerPlaybackSourceKind.remoteHls;
}

@immutable
class PlayerPlaybackSource {
  PlayerPlaybackSource({
    required List<PlayerPlaybackVariant> variants,
    this.selectedVariantIndex = 0,
  }) : assert(variants.isNotEmpty, 'Playback variants must not be empty.'),
       assert(
         selectedVariantIndex >= 0 && selectedVariantIndex < variants.length,
         'Selected playback variant index is out of bounds.',
       ),
       variants = List.unmodifiable(variants);

  final List<PlayerPlaybackVariant> variants;
  final int selectedVariantIndex;

  PlayerPlaybackVariant get activeVariant => variants[selectedVariantIndex];

  String get sourceUri => activeVariant.sourceUri;

  String get streamUri => activeVariant.sourceUri;

  String get qualityLabel => activeVariant.qualityLabel;

  PlayerPlaybackSourceKind get kind => activeVariant.kind;

  bool get isOffline => activeVariant.isOffline;

  PlayerPlaybackVariant variantAt(int index) => variants[index];

  bool hasFallbackAfter(int index) => nextVariantIndexAfter(index) != null;

  int? nextVariantIndexAfter(int index) {
    final nextIndex = index + 1;
    if (nextIndex < 0 || nextIndex >= variants.length) {
      return null;
    }

    return nextIndex;
  }
}
