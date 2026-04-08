import 'package:flutter/foundation.dart';

enum PlayerPlaybackSourceKind { remoteHls, localHlsManifest, localFile }

@immutable
class PlayerPlaybackQualityOption {
  const PlayerPlaybackQualityOption({
    required this.variantIndex,
    required this.label,
    required this.isSelected,
    required this.isOffline,
  });

  final int variantIndex;
  final String label;
  final bool isSelected;
  final bool isOffline;
}

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

  bool get supportsManualQualitySelection => variants.length > 1;

  PlayerPlaybackVariant variantAt(int index) => variants[index];

  List<PlayerPlaybackQualityOption> qualityOptions({
    required int activeVariantIndex,
  }) {
    assert(
      activeVariantIndex >= 0 && activeVariantIndex < variants.length,
      'Active playback variant index is out of bounds.',
    );

    if (!supportsManualQualitySelection) {
      return const [];
    }

    return List.unmodifiable([
      for (var index = 0; index < variants.length; index++)
        PlayerPlaybackQualityOption(
          variantIndex: index,
          label: variants[index].qualityLabel,
          isSelected: index == activeVariantIndex,
          isOffline: variants[index].isOffline,
        ),
    ]);
  }

  bool hasFallbackAfter(int index) => nextVariantIndexAfter(index) != null;

  int? nextVariantIndexAfter(int index) {
    final nextIndex = index + 1;
    if (nextIndex < 0 || nextIndex >= variants.length) {
      return null;
    }

    return nextIndex;
  }
}
