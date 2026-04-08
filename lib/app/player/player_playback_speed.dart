import 'package:flutter/foundation.dart';

const supportedPlayerPlaybackRates = <double>[0.75, 1.0, 1.25, 1.5, 2.0];

@immutable
class PlayerPlaybackSpeedOption {
  const PlayerPlaybackSpeedOption({
    required this.rate,
    required this.label,
    required this.isSelected,
  });

  final double rate;
  final String label;
  final bool isSelected;
}

List<PlayerPlaybackSpeedOption> buildPlayerPlaybackSpeedOptions({
  required double activeRate,
}) {
  final normalizedActiveRate = normalizePlayerPlaybackRate(activeRate);
  return supportedPlayerPlaybackRates
      .map(
        (rate) => PlayerPlaybackSpeedOption(
          rate: rate,
          label: formatPlayerPlaybackRateLabel(rate),
          isSelected: (normalizedActiveRate - rate).abs() < 0.001,
        ),
      )
      .toList(growable: false);
}

double normalizePlayerPlaybackRate(double rate) {
  for (final supportedRate in supportedPlayerPlaybackRates) {
    if ((supportedRate - rate).abs() < 0.001) {
      return supportedRate;
    }
  }

  return 1.0;
}

String formatPlayerPlaybackRateLabel(double rate) {
  final normalizedRate = normalizePlayerPlaybackRate(rate);
  final fixedValue = normalizedRate.toStringAsFixed(2);
  final trimmedValue = fixedValue.replaceFirst(RegExp(r'\.?0+$'), '');
  return '${trimmedValue}x';
}
