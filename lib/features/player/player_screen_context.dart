import 'package:flutter/foundation.dart';

@immutable
class PlayerScreenContext {
  const PlayerScreenContext({
    required this.seriesId,
    required this.seriesTitle,
    required this.episodeId,
    required this.episodeNumberLabel,
    required this.episodeTitle,
  });

  final String seriesId;
  final String seriesTitle;
  final String episodeId;
  final String episodeNumberLabel;
  final String episodeTitle;

  String get episodeDisplayLabel => 'Episode $episodeNumberLabel';

  num? get episodeOrdinal => num.tryParse(episodeNumberLabel.trim());

  bool matchesEpisode({
    required String id,
    required String numberLabel,
    required String title,
  }) {
    if (id == episodeId) {
      return true;
    }

    final normalizedNumberLabel = numberLabel.trim();
    if (normalizedNumberLabel == episodeNumberLabel.trim()) {
      return true;
    }

    final selectedOrdinal = episodeOrdinal;
    if (selectedOrdinal != null &&
        num.tryParse(normalizedNumberLabel) == selectedOrdinal) {
      return true;
    }

    return title == episodeTitle;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is PlayerScreenContext &&
        other.seriesId == seriesId &&
        other.seriesTitle == seriesTitle &&
        other.episodeId == episodeId &&
        other.episodeNumberLabel == episodeNumberLabel &&
        other.episodeTitle == episodeTitle;
  }

  @override
  int get hashCode => Object.hash(
    seriesId,
    seriesTitle,
    episodeId,
    episodeNumberLabel,
    episodeTitle,
  );
}
