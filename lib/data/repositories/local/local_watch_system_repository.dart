import '../../../domain/models/availability_state.dart';
import '../../../domain/models/continue_watching_entry.dart';
import '../../../domain/models/episode.dart';
import '../../../domain/models/episode_progress.dart';
import '../../../domain/models/history_entry.dart';
import '../../../domain/models/series.dart';
import '../../../domain/repositories/series_repository.dart';
import '../../../domain/repositories/watch_system_repository.dart';
import '../../local/json_episode_progress_store.dart';

class LocalWatchSystemRepository implements WatchSystemRepository {
  static const _minimumMeaningfulResumePosition = Duration(seconds: 5);

  LocalWatchSystemRepository({
    required JsonEpisodeProgressStore episodeProgressStore,
    required SeriesRepository seriesRepository,
  }) : _episodeProgressStore = episodeProgressStore,
       _seriesRepository = seriesRepository;

  final JsonEpisodeProgressStore _episodeProgressStore;
  final SeriesRepository _seriesRepository;

  @override
  Future<List<ContinueWatchingEntry>> getContinueWatching({
    int limit = 20,
  }) async {
    if (limit <= 0) {
      return const [];
    }

    final progressEntries = await _readStoredProgressEntries();
    final candidateProgressEntries = progressEntries
        .where(_isMeaningfulContinueWatchingProgress)
        .toList(growable: false);
    if (candidateProgressEntries.isEmpty) {
      return const [];
    }

    final seriesPayloadById = <String, _SeriesWatchPayload>{};
    await Future.wait([
      for (final seriesId
          in candidateProgressEntries
              .map((progress) => progress.seriesId)
              .toSet())
        _loadSeriesWatchPayload(seriesId).then((payload) {
          if (payload != null) {
            seriesPayloadById[seriesId] = payload;
          }
        }),
    ]);

    final continueWatching = <ContinueWatchingEntry>[];
    for (final progress in candidateProgressEntries) {
      final seriesPayload = seriesPayloadById[progress.seriesId];
      if (seriesPayload == null) {
        continue;
      }

      final episode = seriesPayload.episodeById[progress.episodeId];
      if (episode == null || !_isMeaningfulPlaybackEpisode(episode)) {
        continue;
      }

      continueWatching.add(
        ContinueWatchingEntry(
          series: seriesPayload.series,
          episode: episode,
          progress: progress,
          lastEngagedAt: progress.updatedAt,
        ),
      );

      if (continueWatching.length >= limit) {
        break;
      }
    }

    return List.unmodifiable(continueWatching);
  }

  @override
  Future<List<HistoryEntry>> getWatchHistory({int limit = 50}) async {
    if (limit <= 0) {
      return const [];
    }

    final progressEntries = await _readStoredProgressEntries();
    final completedProgressEntries = progressEntries
        .where(_isMeaningfulHistoryProgress)
        .toList(growable: false);
    if (completedProgressEntries.isEmpty) {
      return const [];
    }

    final seriesPayloadById = <String, _SeriesWatchPayload>{};
    await Future.wait([
      for (final seriesId
          in completedProgressEntries
              .map((progress) => progress.seriesId)
              .toSet())
        _loadSeriesWatchPayload(seriesId).then((payload) {
          if (payload != null) {
            seriesPayloadById[seriesId] = payload;
          }
        }),
    ]);

    final historyEntries = <HistoryEntry>[];
    for (final progress in completedProgressEntries) {
      final seriesPayload = seriesPayloadById[progress.seriesId];
      if (seriesPayload == null) {
        continue;
      }

      final episode = seriesPayload.episodeById[progress.episodeId];
      if (episode == null) {
        continue;
      }

      historyEntries.add(
        HistoryEntry(
          id: _buildKey(
            seriesId: progress.seriesId,
            episodeId: progress.episodeId,
          ),
          series: seriesPayload.series,
          episode: episode,
          progress: progress,
          watchedAt: progress.updatedAt,
        ),
      );

      if (historyEntries.length >= limit) {
        break;
      }
    }

    return List.unmodifiable(historyEntries);
  }

  @override
  Future<List<EpisodeProgress>> getSeriesEpisodeProgress({
    required String seriesId,
  }) async {
    final progressEntries = (await _readStoredProgressEntries())
        .where((progress) => progress.seriesId == seriesId)
        .toList(growable: false);

    progressEntries.sort(
      (left, right) => right.updatedAt.compareTo(left.updatedAt),
    );
    return List.unmodifiable(progressEntries);
  }

  @override
  Future<EpisodeProgress?> getEpisodeProgress({
    required String seriesId,
    required String episodeId,
  }) async {
    final storedEntries = await _episodeProgressStore.readAll();
    final payload =
        storedEntries[_buildKey(seriesId: seriesId, episodeId: episodeId)];
    if (payload is! Map) {
      return null;
    }

    try {
      return EpisodeProgress.fromJson(Map<String, dynamic>.from(payload));
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> saveEpisodeProgress(EpisodeProgress progress) async {
    final storedEntries = Map<String, dynamic>.from(
      await _episodeProgressStore.readAll(),
    );
    storedEntries[_buildKey(
      seriesId: progress.seriesId,
      episodeId: progress.episodeId,
    )] = progress
        .toJson();
    await _episodeProgressStore.writeAll(storedEntries);
  }

  @override
  Future<void> markEpisodeWatched({
    required String seriesId,
    required String episodeId,
  }) async {
    final episode = await _findEpisode(seriesId, episodeId);
    if (episode == null || !_isMeaningfulPlaybackEpisode(episode)) {
      throw StateError(
        'Episode $episodeId for series $seriesId is unavailable for watched state updates.',
      );
    }

    final existingProgress = await getEpisodeProgress(
      seriesId: seriesId,
      episodeId: episodeId,
    );
    final resolvedTotalDuration = episode.duration ?? existingProgress?.totalDuration;
    final resolvedPosition = resolvedTotalDuration ?? Duration.zero;

    await saveEpisodeProgress(
      EpisodeProgress(
        seriesId: seriesId,
        episodeId: episodeId,
        position: resolvedPosition,
        totalDuration: resolvedTotalDuration,
        isCompleted: true,
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> markEpisodeUnwatched({
    required String seriesId,
    required String episodeId,
  }) async {
    final storedEntries = Map<String, dynamic>.from(
      await _episodeProgressStore.readAll(),
    );
    storedEntries.remove(
      _buildKey(seriesId: seriesId, episodeId: episodeId),
    );
    await _episodeProgressStore.writeAll(storedEntries);
  }

  String _buildKey({required String seriesId, required String episodeId}) {
    return '$seriesId::$episodeId';
  }

  Future<List<EpisodeProgress>> _readStoredProgressEntries() async {
    final storedEntries = await _episodeProgressStore.readAll();
    final progressEntries = <EpisodeProgress>[];

    for (final entry in storedEntries.values) {
      if (entry is! Map) {
        continue;
      }

      try {
        progressEntries.add(
          EpisodeProgress.fromJson(Map<String, dynamic>.from(entry)),
        );
      } on FormatException {
        continue;
      }
    }

    progressEntries.sort(
      (left, right) => right.updatedAt.compareTo(left.updatedAt),
    );
    return List.unmodifiable(progressEntries);
  }

  bool _isMeaningfulContinueWatchingProgress(EpisodeProgress progress) {
    if (progress.isCompleted) {
      return false;
    }

    if (progress.position < _minimumMeaningfulResumePosition) {
      return false;
    }

    final totalDuration = progress.totalDuration;
    if (totalDuration != null &&
        totalDuration > Duration.zero &&
        progress.position >= totalDuration) {
      return false;
    }

    return true;
  }

  bool _isMeaningfulHistoryProgress(EpisodeProgress progress) {
    return progress.isCompleted;
  }

  bool _isMeaningfulPlaybackEpisode(Episode episode) {
    return episode.availability.status == AvailabilityStatus.available;
  }

  Future<Episode?> _findEpisode(String seriesId, String episodeId) async {
    final episodes = await _seriesRepository.getEpisodes(seriesId);
    for (final episode in episodes) {
      if (episode.id == episodeId) {
        return episode;
      }
    }

    return null;
  }

  Future<_SeriesWatchPayload?> _loadSeriesWatchPayload(String seriesId) async {
    try {
      final seriesFuture = _seriesRepository.getSeriesById(seriesId);
      final episodesFuture = _seriesRepository.getEpisodes(seriesId);

      final series = await seriesFuture;
      final episodes = await episodesFuture;

      return _SeriesWatchPayload(
        series: series,
        episodeById: {for (final episode in episodes) episode.id: episode},
      );
    } catch (_) {
      return null;
    }
  }
}

class _SeriesWatchPayload {
  const _SeriesWatchPayload({required this.series, required this.episodeById});

  final Series series;
  final Map<String, Episode> episodeById;
}
