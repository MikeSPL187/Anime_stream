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
  group('seriesDetailsProvider', () {
    test('hydrates saved episode progress into series details data', () async {
      final container = ProviderContainer(
        overrides: [
          seriesRepositoryProvider.overrideWithValue(
            _FakeSeriesRepository(
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
            ),
          ),
          watchSystemRepositoryProvider.overrideWithValue(
            _FakeWatchSystemRepository(
              progressEntries: [
                EpisodeProgress(
                  seriesId: 'series-100',
                  episodeId: 'episode-2',
                  position: Duration(minutes: 14),
                  updatedAt: DateTime(2026, 4, 5, 10, 0),
                ),
              ],
            ),
          ),
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
    });
  });
}

class _FakeSeriesRepository implements SeriesRepository {
  const _FakeSeriesRepository({required this.series, required this.episodes});

  final Series series;
  final List<Episode> episodes;

  @override
  Future<List<Series>> getFeaturedSeries({int limit = 20}) async {
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
    return episodes;
  }

  @override
  Future<List<Series>> getPopularSeries({int limit = 20}) async {
    throw UnimplementedError();
  }

  @override
  Future<Series> getSeriesById(String seriesId) async {
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
  const _FakeWatchSystemRepository({this.progressEntries = const []});

  final List<EpisodeProgress> progressEntries;

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
    return progressEntries
        .where((progress) => progress.seriesId == seriesId)
        .toList(growable: false);
  }

  @override
  Future<void> saveEpisodeProgress(EpisodeProgress progress) async {
    throw UnimplementedError();
  }
}
