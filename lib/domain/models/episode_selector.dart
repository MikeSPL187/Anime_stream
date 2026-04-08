import 'package:flutter/foundation.dart';

@immutable
class EpisodeSelector {
  const EpisodeSelector({
    required this.episodeId,
    required this.episodeNumberLabel,
    required this.episodeTitle,
  });

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

    final normalizedTitle = title.trim();
    return normalizedTitle.isNotEmpty && normalizedTitle == episodeTitle.trim();
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is EpisodeSelector &&
        other.episodeId == episodeId &&
        other.episodeNumberLabel == episodeNumberLabel &&
        other.episodeTitle == episodeTitle;
  }

  @override
  int get hashCode => Object.hash(episodeId, episodeNumberLabel, episodeTitle);
}
