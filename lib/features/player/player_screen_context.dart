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
