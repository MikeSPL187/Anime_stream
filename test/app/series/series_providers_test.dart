import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anime_stream_app/app/di/series_repository_provider.dart';
import 'package:anime_stream_app/app/di/watch_system_repository_provider.dart';
import 'package:anime_stream_app/app/series/series_providers.dart';
import 'package:anime_stream_app/domain/models/availability_state.dart';
import 'package:anime_stream_app/domain/models/continue_watching_entry.dart';
import 'package:anime_stream_app/domain/models/episode.dart';
import 'package:anime_stream_app/domain/models/episode_progress.dart';
import 'package:anime_stream_app/domain/models/history_entry.dart';
import 'package:anime_stream_app/domain/models/series.dart';
import 'package:anime_stream_app/domain/models/series_catalog_page.dart';
import 'package:anime_stream_app/domain/repositories/series_repository.dart';
import 'package:anime_stream_app/domain/repositories/watch_system_repository.dart';

void main() {
  group('seriesContentProvider', () {
    test('loads series content without watch progress state', () async {
      final repository = _FakeSeriesRepository(
        series: const Series(
          id: 'series-200',
          slug: 'dandadan',
          title: 'Dandadan',
          availability: AvailabilityState(),
        ),
        episodes: const [
          Episode(
            id: 'episode-1',
            seriesId: 'series-200',
            sortOrder: 1,
            numberLabel: '1',
            title: 'First Contact',
          ),
          Episode(
            id: 'episode-2',
            seriesId: 'series-200',
            sortOrder: 2,
            numberLabel: '2',
            title: 'Turbo Granny',
          ),
        ],
      );
      final container = ProviderContainer(
        overrides: [seriesRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final content = await container.read(
        seriesContentProvider('series-200').future,
      );

      expect(content.series.title, 'Dandadan');
      expect(content.episodes, hasLength(2));
      expect(content.episodeById('episode-2')?.title, 'Turbo Granny');
      expect(repository.getSeriesByIdCallCount, 1);
      expect(repository.getEpisodesCallCount, 1);
    });
  });

  group('seriesDetailsProvider', () {
    test('hydrates saved episode progress into series details data', () async {
      final repository = _FakeSeriesRepository(
        series: const Series(
          id: 'series-100',
          slug: 'frieren',
          title: 'Frieren',
          availability: AvailabilityState(),
        ),
        episodes: const [
          Episode(
            id: 'episode-1',
            seriesId: 'series-100',
            sortOrder: 1,
            numberLabel: '1',
            title: 'Departure',
          ),
          Episode(
            id: 'episode-2',
            seriesId: 'series-100',
            sortOrder: 2,
            numberLabel: '2',
            title: 'Journey',
          ),
        ],
      );
      final watchRepository = _FakeWatchSystemRepository(
        progressEntries: [
          EpisodeProgress(
            seriesId: 'series-100',
            episodeId: 'episode-2',
            position: Duration(minutes: 14),
            updatedAt: DateTime(2026, 4, 5, 10, 0),
          ),
        ],
      );
      final container = ProviderContainer(
        overrides: [
          seriesRepositoryProvider.overrideWithValue(repository),
          watchSystemRepositoryProvider.overrideWithValue(watchRepository),
        ],
      );
      addTearDown(container.dispose);

      final details = await container.read(
        seriesDetailsProvider('series-100').future,
      );

      expect(details.episodes, hasLength(2));
      expect(details.hasSavedProgress('episode-1'), isFalse);
      expect(details.hasSavedProgress('episode-2'), isTrue);
      expect(details.isEpisodeInProgress('episode-2'), isTrue);
      expect(details.isEpisodeCompleted('episode-2'), isFalse);
      expect(details.inProgressEpisodeCount, 1);
      expect(details.completedEpisodeCount, 0);
      expect(details.latestProgress?.episodeId, 'episode-2');
      expect(
        details.progressForEpisode('episode-2')?.position,
        const Duration(minutes: 14),
      );
      expect(repository.getSeriesByIdCallCount, 1);
      expect(repository.getEpisodesCallCount, 1);
      expect(watchRepository.getSeriesEpisodeProgressCallCount, 1);
    });

    test(
      'keeps series content available when watch progress state cannot be loaded',
      () async {
        final repository = _FakeSeriesRepository(
          series: const Series(
            id: 'series-400',
            slug: 'monster',
            title: 'Monster',
            availability: AvailabilityState(),
          ),
          episodes: const [
            Episode(
              id: 'episode-1',
              seriesId: 'series-400',
              sortOrder: 1,
              numberLabel: '1',
              title: 'Herr Doktor Tenma',
            ),
          ],
        );
        final watchRepository = _FakeWatchSystemRepository(
          progressError: StateError('watch progress unavailable'),
        );
        final container = ProviderContainer(
          overrides: [
            seriesRepositoryProvider.overrideWithValue(repository),
            watchSystemRepositoryProvider.overrideWithValue(watchRepository),
          ],
        );
        addTearDown(container.dispose);

        final details = await container.read(
          seriesDetailsProvider('series-400').future,
        );

        expect(details.series.title, 'Monster');
        expect(details.episodes, hasLength(1));
        expect(details.episodeProgressById, isEmpty);
        expect(details.isWatchStateAvailable, isFalse);
        expect(
          details.watchStateErrorMessage,
          'Resume progress and watched markers could not be loaded right now.',
        );
        expect(repository.getSeriesByIdCallCount, 1);
        expect(repository.getEpisodesCallCount, 1);
        expect(watchRepository.getSeriesEpisodeProgressCallCount, 1);
      },
    );
  });
}

class _FakeSeriesRepository implements SeriesRepository {
  _FakeSeriesRepository({required this.series, required this.episodes});

  final Series series;
  final List<Episode> episodes;
  int getEpisodesCallCount = 0;
  int getSeriesByIdCallCount = 0;

  @override
  Future<List<Series>> getLatestSeries({int limit = 20}) async {
    throw UnimplementedError();
  }

  @override
  Future<SeriesCatalogPage> getCatalogPage({
    int page = 1,
    int pageSize = 20,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<Episode>> getEpisodes(String seriesId) async {
    getEpisodesCallCount += 1;
    return episodes;
  }

  @override
  Future<List<Series>> getPopularSeries({int limit = 20}) async {
    throw UnimplementedError();
  }

  @override
  Future<Series> getSeriesById(String seriesId) async {
    getSeriesByIdCallCount += 1;
    return series;
  }

  @override
  Future<List<Series>> getTrendingSeries({int limit = 20}) async {
    throw UnimplementedError();
  }

  @override
  Future<List<Series>> searchSeries(String query, {int limit = 20}) async {
    throw UnimplementedError();
  }
}

class _FakeWatchSystemRepository implements WatchSystemRepository {
  _FakeWatchSystemRepository({
    this.progressEntries = const [],
    this.progressError,
  });

  final List<EpisodeProgress> progressEntries;
  final Object? progressError;
  int getSeriesEpisodeProgressCallCount = 0;

  @override
  Future<List<ContinueWatchingEntry>> getContinueWatching({
    int limit = 20,
  }) async {
    return const [];
  }

  @override
  Future<List<HistoryEntry>> getWatchHistory({int limit = 50}) async {
    return const [];
  }

  @override
  Future<EpisodeProgress?> getEpisodeProgress({
    required String seriesId,
    required String episodeId,
  }) async {
    for (final progress in progressEntries) {
      if (progress.seriesId == seriesId && progress.episodeId == episodeId) {
        return progress;
      }
    }

    return null;
  }

  @override
  Future<List<EpisodeProgress>> getSeriesEpisodeProgress({
    required String seriesId,
  }) async {
    getSeriesEpisodeProgressCallCount += 1;
    if (progressError != null) {
      throw progressError!;
    }
    return progressEntries
        .where((progress) => progress.seriesId == seriesId)
        .toList(growable: false);
  }

  @override
  Future<void> saveEpisodeProgress(EpisodeProgress progress) async {
    throw UnimplementedError();
  }

  @override
  Future<void> markEpisodeWatched({
    required String seriesId,
    required String episodeId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> markEpisodeUnwatched({
    required String seriesId,
    required String episodeId,
  }) async {
    throw UnimplementedError();
  }
}
