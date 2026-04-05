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

        final initialEntries = await repository.getWatchlist();

        expect(initialEntries, hasLength(2));
        expect(initialEntries.first.series.id, 'series-2');
        expect(initialEntries.first.status, WatchlistEntryStatus.queued);
        expect(initialEntries.last.series.id, 'series-1');
        expect(await repository.isInWatchlist('series-1'), isTrue);
        expect(await repository.isInWatchlist('series-3'), isFalse);

        await repository.addToWatchlist('series-3');

        expect(await repository.isInWatchlist('series-3'), isTrue);

        await repository.removeFromWatchlist('series-2');

        final updatedEntries = await repository.getWatchlist();
        expect(updatedEntries.map((entry) => entry.series.id), [
          'series-3',
          'series-1',
        ]);
      },
    );
  });
}

class _FakeSeriesRepository implements SeriesRepository {
  const _FakeSeriesRepository({required this.seriesById});

  final Map<String, Series> seriesById;

  @override
  Future<List<Series>> getFeaturedSeries({int limit = 20}) async {
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
    final series = seriesById[seriesId];
    if (series == null) {
      throw StateError('Missing series $seriesId');
    }

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
