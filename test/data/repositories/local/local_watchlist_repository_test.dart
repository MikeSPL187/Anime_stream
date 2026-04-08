import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:anime_stream_app/data/local/json_watchlist_store.dart';
import 'package:anime_stream_app/data/repositories/local/local_watchlist_repository.dart';
import 'package:anime_stream_app/domain/models/availability_state.dart';
import 'package:anime_stream_app/domain/models/episode.dart';
import 'package:anime_stream_app/domain/models/series.dart';
import 'package:anime_stream_app/domain/models/series_catalog_page.dart';
import 'package:anime_stream_app/domain/models/watchlist_entry.dart';
import 'package:anime_stream_app/domain/repositories/series_repository.dart';

void main() {
  group('LocalWatchlistRepository', () {
    test(
      'hydrates stored watchlist entries and supports add/remove semantics',
      () async {
        final tempDirectory = await Directory.systemTemp.createTemp(
          'watchlist-repository-test',
        );
        addTearDown(() async {
          if (await tempDirectory.exists()) {
            await tempDirectory.delete(recursive: true);
          }
        });

        final watchlistStore = JsonWatchlistStore(
          directoryProvider: () async => tempDirectory,
          relativeFilePath: 'watchlist.json',
        );
        await watchlistStore.writeAll({
          'series-1': {
            'seriesId': 'series-1',
            'addedAt': DateTime(2026, 4, 5, 10, 0).toIso8601String(),
          },
          'series-2': {
            'seriesId': 'series-2',
            'addedAt': DateTime(2026, 4, 5, 12, 0).toIso8601String(),
          },
          'missing': {
            'seriesId': 'missing',
            'addedAt': DateTime(2026, 4, 5, 11, 0).toIso8601String(),
          },
        });

        final repository = LocalWatchlistRepository(
          watchlistStore: watchlistStore,
          seriesRepository: _FakeSeriesRepository(
            seriesById: {
              'series-1': const Series(
                id: 'series-1',
                slug: 'frieren',
                title: 'Frieren',
                availability: AvailabilityState(),
              ),
              'series-2': const Series(
                id: 'series-2',
                slug: 'pluto',
                title: 'Pluto',
                availability: AvailabilityState(),
              ),
              'series-3': const Series(
                id: 'series-3',
                slug: 'monster',
                title: 'Monster',
                availability: AvailabilityState(),
              ),
            },
          ),
        );

        final initialSnapshot = await repository.getWatchlist();
        final normalizedStore = await watchlistStore.readAll();

        expect(initialSnapshot.entries, hasLength(2));
        expect(initialSnapshot.temporarilyUnavailableCount, 0);
        expect(initialSnapshot.entries.first.series.id, 'series-2');
        expect(
          initialSnapshot.entries.first.status,
          WatchlistEntryStatus.queued,
        );
        expect(initialSnapshot.entries.last.series.id, 'series-1');
        expect(await repository.isInWatchlist('series-1'), isTrue);
        expect(await repository.isInWatchlist('missing'), isFalse);
        expect(await repository.isInWatchlist('series-3'), isFalse);
        expect(normalizedStore.containsKey('missing'), isFalse);

        await repository.addToWatchlist('series-3');

        expect(await repository.isInWatchlist('series-3'), isTrue);

        await repository.removeFromWatchlist('series-2');

        final updatedSnapshot = await repository.getWatchlist();
        expect(updatedSnapshot.temporarilyUnavailableCount, 0);
        expect(updatedSnapshot.entries.map((entry) => entry.series.id), [
          'series-3',
          'series-1',
        ]);
      },
    );

    test(
      'preserves saved membership when series lookup fails for a transient reason',
      () async {
        final tempDirectory = await Directory.systemTemp.createTemp(
          'watchlist-transient-failure-test',
        );
        addTearDown(() async {
          if (await tempDirectory.exists()) {
            await tempDirectory.delete(recursive: true);
          }
        });

        final watchlistStore = JsonWatchlistStore(
          directoryProvider: () async => tempDirectory,
          relativeFilePath: 'watchlist.json',
        );
        await watchlistStore.writeAll({
          'series-1': {
            'seriesId': 'series-1',
            'addedAt': DateTime(2026, 4, 6, 10, 0).toIso8601String(),
          },
        });

        final repository = LocalWatchlistRepository(
          watchlistStore: watchlistStore,
          seriesRepository: _FakeSeriesRepository(
            seriesById: const {},
            errorsById: {'series-1': Exception('network unavailable')},
          ),
        );

        expect(await repository.isInWatchlist('series-1'), isTrue);
        expect(
          (await watchlistStore.readAll()).containsKey('series-1'),
          isTrue,
        );
        final snapshot = await repository.getWatchlist();
        expect(snapshot.entries, isEmpty);
        expect(snapshot.temporarilyUnavailableCount, 1);
        expect(
          (await watchlistStore.readAll()).containsKey('series-1'),
          isTrue,
        );
      },
    );

    test(
      'hydrates saved titles concurrently while keeping watchlist order stable',
      () async {
        final tempDirectory = await Directory.systemTemp.createTemp(
          'watchlist-concurrency-test',
        );
        addTearDown(() async {
          if (await tempDirectory.exists()) {
            await tempDirectory.delete(recursive: true);
          }
        });

        final watchlistStore = JsonWatchlistStore(
          directoryProvider: () async => tempDirectory,
          relativeFilePath: 'watchlist.json',
        );
        await watchlistStore.writeAll({
          'series-1': {
            'seriesId': 'series-1',
            'addedAt': DateTime(2026, 4, 7, 10, 0).toIso8601String(),
          },
          'series-2': {
            'seriesId': 'series-2',
            'addedAt': DateTime(2026, 4, 7, 12, 0).toIso8601String(),
          },
        });

        final fakeSeriesRepository = _FakeSeriesRepository(
          seriesById: {
            'series-1': const Series(
              id: 'series-1',
              slug: 'frieren',
              title: 'Frieren',
              availability: AvailabilityState(),
            ),
            'series-2': const Series(
              id: 'series-2',
              slug: 'pluto',
              title: 'Pluto',
              availability: AvailabilityState(),
            ),
          },
          delaysById: const {
            'series-1': Duration(milliseconds: 40),
            'series-2': Duration(milliseconds: 40),
          },
        );
        final repository = LocalWatchlistRepository(
          watchlistStore: watchlistStore,
          seriesRepository: fakeSeriesRepository,
        );

        final snapshot = await repository.getWatchlist();

        expect(snapshot.entries.map((entry) => entry.series.id).toList(), [
          'series-2',
          'series-1',
        ]);
        expect(fakeSeriesRepository.maxConcurrentRequests, greaterThan(1));
      },
    );
  });
}

class _FakeSeriesRepository implements SeriesRepository {
  _FakeSeriesRepository({
    required this.seriesById,
    this.errorsById = const {},
    this.delaysById = const {},
  });

  final Map<String, Series> seriesById;
  final Map<String, Object> errorsById;
  final Map<String, Duration> delaysById;
  int _activeRequests = 0;
  int maxConcurrentRequests = 0;

  @override
  Future<List<Series>> getLatestSeries({int limit = 20}) async {
    throw UnimplementedError();
  }

  @override
  Future<List<Episode>> getEpisodes(String seriesId) async {
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
  Future<List<Series>> getPopularSeries({int limit = 20}) async {
    throw UnimplementedError();
  }

  @override
  Future<Series> getSeriesById(String seriesId) async {
    _activeRequests += 1;
    if (_activeRequests > maxConcurrentRequests) {
      maxConcurrentRequests = _activeRequests;
    }

    try {
      final delay = delaysById[seriesId];
      if (delay != null) {
        await Future<void>.delayed(delay);
      }

      final error = errorsById[seriesId];
      if (error != null) {
        throw error;
      }

      final series = seriesById[seriesId];
      if (series == null) {
        throw StateError('Missing series $seriesId');
      }

      return series;
    } finally {
      _activeRequests -= 1;
    }
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
