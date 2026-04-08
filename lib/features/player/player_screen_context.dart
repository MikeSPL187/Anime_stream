import 'package:flutter/foundation.dart';

import '../../domain/models/episode_selector.dart';

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

  EpisodeSelector get episodeSelector => EpisodeSelector(
    episodeId: episodeId,
    episodeNumberLabel: episodeNumberLabel,
    episodeTitle: episodeTitle,
  );

  num? get episodeOrdinal => num.tryParse(episodeNumberLabel.trim());

  bool matchesEpisode({
    required String id,
    required String numberLabel,
    required String title,
  }) {
    return episodeSelector.matchesEpisode(
      id: id,
      numberLabel: numberLabel,
      title: title,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is PlayerScreenContext &&
        other.seriesId == seriesId &&
        other.episodeId == episodeId;
  }

  @override
  int get hashCode => Object.hash(seriesId, episodeId);
}
