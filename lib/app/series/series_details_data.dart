import 'package:flutter/foundation.dart';

import '../../domain/models/episode.dart';
import '../../domain/models/episode_progress.dart';
import '../../domain/models/series.dart';

enum SeriesPrimaryWatchActionKind {
  startWatching,
  resumeEpisode,
  continueEpisode,
  endOfAvailableContent,
  unavailable,
}

@immutable
class SeriesContentData {
  SeriesContentData({required this.series, required List<Episode> episodes})
    : episodes = List.unmodifiable(episodes);

  final Series series;
  final List<Episode> episodes;

  Episode? episodeById(String episodeId) {
    for (final episode in episodes) {
      if (episode.id == episodeId) {
        return episode;
      }
    }

    return null;
  }
}

@immutable
class SeriesPrimaryWatchAction {
  const SeriesPrimaryWatchAction({
    required this.kind,
    required this.label,
    this.targetEpisode,
  });

  final SeriesPrimaryWatchActionKind kind;
  final String label;
  final Episode? targetEpisode;

  bool get isAvailable => targetEpisode != null;
}

@immutable
class SeriesDetailsData {
  SeriesDetailsData({
    required this.series,
    required List<Episode> episodes,
    Map<String, EpisodeProgress> episodeProgressById = const {},
    this.watchStateErrorMessage,
  }) : episodes = List.unmodifiable(episodes),
       episodeProgressById = Map.unmodifiable(episodeProgressById);

  final Series series;
  final List<Episode> episodes;
  final Map<String, EpisodeProgress> episodeProgressById;
  final String? watchStateErrorMessage;

  bool get isWatchStateAvailable =>
      watchStateErrorMessage == null || watchStateErrorMessage!.trim().isEmpty;

  EpisodeProgress? progressForEpisode(String episodeId) {
    return episodeProgressById[episodeId];
  }

  bool hasSavedProgress(String episodeId) {
    return episodeProgressById.containsKey(episodeId);
  }

  bool isEpisodeCompleted(String episodeId) {
    return progressForEpisode(episodeId)?.isCompleted == true;
  }

  bool isEpisodeInProgress(String episodeId) {
    final progress = progressForEpisode(episodeId);
    return progress != null && !progress.isCompleted;
  }

  int get completedEpisodeCount {
    return episodeProgressById.values
        .where((progress) => progress.isCompleted)
        .length;
  }

  int get inProgressEpisodeCount {
    return episodeProgressById.values
        .where((progress) => !progress.isCompleted)
        .length;
  }

  EpisodeProgress? get latestProgress {
    if (episodeProgressById.isEmpty) {
      return null;
    }

    final progressEntries = episodeProgressById.values.toList(growable: false)
      ..sort((left, right) => right.updatedAt.compareTo(left.updatedAt));
    return progressEntries.first;
  }

  Episode? get firstEpisode {
    final sortedEpisodes = _sortedEpisodes;
    if (sortedEpisodes.isEmpty) {
      return null;
    }

    return sortedEpisodes.first;
  }

  SeriesPrimaryWatchAction get primaryWatchAction {
    final latestProgress = this.latestProgress;
    if (latestProgress != null) {
      final progressEpisode = episodeForProgress(latestProgress);
      if (latestProgress.isCompleted) {
        final nextEpisode = nextEpisodeAfter(progressEpisode);
        if (nextEpisode != null) {
          return SeriesPrimaryWatchAction(
            kind: SeriesPrimaryWatchActionKind.continueEpisode,
            label: 'Continue Episode ${nextEpisode.numberLabel}',
            targetEpisode: nextEpisode,
          );
        }

        if (progressEpisode != null) {
          return const SeriesPrimaryWatchAction(
            kind: SeriesPrimaryWatchActionKind.endOfAvailableContent,
            label: 'Up to Date',
          );
        }
      } else if (progressEpisode != null) {
        return SeriesPrimaryWatchAction(
          kind: SeriesPrimaryWatchActionKind.resumeEpisode,
          label: 'Resume Episode ${progressEpisode.numberLabel}',
          targetEpisode: progressEpisode,
        );
      }
    }

    final startEpisode = firstEpisode;
    if (startEpisode != null) {
      return SeriesPrimaryWatchAction(
        kind: SeriesPrimaryWatchActionKind.startWatching,
        label: 'Start Watching',
        targetEpisode: startEpisode,
      );
    }

    return const SeriesPrimaryWatchAction(
      kind: SeriesPrimaryWatchActionKind.unavailable,
      label: 'Episodes Unavailable',
    );
  }

  Episode? episodeForProgress(EpisodeProgress progress) {
    for (final episode in _sortedEpisodes) {
      if (episode.id == progress.episodeId) {
        return episode;
      }
    }

    return null;
  }

  Episode? nextEpisodeAfter(Episode? episode) {
    if (episode == null) {
      return null;
    }

    final sortedEpisodes = _sortedEpisodes;
    for (var index = 0; index < sortedEpisodes.length; index++) {
      if (sortedEpisodes[index].id != episode.id) {
        continue;
      }

      final nextIndex = index + 1;
      if (nextIndex >= sortedEpisodes.length) {
        return null;
      }

      return sortedEpisodes[nextIndex];
    }

    return null;
  }

  List<Episode> get _sortedEpisodes {
    final sortedEpisodes = episodes.toList(growable: false)
      ..sort((left, right) => left.sortOrder.compareTo(right.sortOrder));
    return sortedEpisodes;
  }
}
