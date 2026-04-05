import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anime_stream_app/app/di/watchlist_repository_provider.dart';
import 'package:anime_stream_app/app/watchlist/watchlist_providers.dart';
import 'package:anime_stream_app/domain/models/availability_state.dart';
import 'package:anime_stream_app/domain/models/series.dart';
import 'package:anime_stream_app/domain/models/watchlist_entry.dart';
import 'package:anime_stream_app/domain/repositories/watchlist_repository.dart';

void main() {
  group('watchlist providers', () {
    test('sync membership changes into the saved watchlist surface', () async {
      final repository = _FakeWatchlistRepository(
        seriesById: {
          'series-1': const Series(
            id: 'series-1',
            slug: 'frieren',
            title: 'Frieren',
            availability: AvailabilityState(),
          ),
        },
      );
      final container = ProviderContainer(
        overrides: [watchlistRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      expect(await container.read(watchlistProvider.future), isEmpty);
      expect(
        await container.read(
          watchlistMembershipControllerProvider('series-1').future,
        ),
        isFalse,
      );

      await container
          .read(watchlistMembershipControllerProvider('series-1').notifier)
          .addToWatchlist();

      expect(
        container.read(watchlistMembershipControllerProvider('series-1')).value,
        isTrue,
      );
      expect(
        (await container.read(
          watchlistProvider.future,
        )).map((entry) => entry.series.id),
        ['series-1'],
      );

      await container
          .read(watchlistMembershipControllerProvider('series-1').notifier)
          .removeFromWatchlist();

      expect(
        container.read(watchlistMembershipControllerProvider('series-1')).value,
        isFalse,
      );
      expect(await container.read(watchlistProvider.future), isEmpty);
    });
  });
}

class _FakeWatchlistRepository implements WatchlistRepository {
  _FakeWatchlistRepository({required this.seriesById});

  final Map<String, Series> seriesById;
  final Map<String, DateTime> _savedAtBySeriesId = {};

  @override
  Future<void> addToWatchlist(String seriesId) async {
    _savedAtBySeriesId.putIfAbsent(seriesId, DateTime.now);
  }

  @override
  Future<List<WatchlistEntry>> getWatchlist() async {
    final entries = _savedAtBySeriesId.entries.toList(growable: false)
      ..sort((left, right) => right.value.compareTo(left.value));

    return entries
        .map(
          (entry) => WatchlistEntry(
            series: seriesById[entry.key]!,
            addedAt: entry.value,
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<bool> isInWatchlist(String seriesId) async {
    return _savedAtBySeriesId.containsKey(seriesId);
  }

  @override
  Future<void> removeFromWatchlist(String seriesId) async {
    _savedAtBySeriesId.remove(seriesId);
  }
}
