import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anime_stream_app/app/di/watchlist_repository_provider.dart';
import 'package:anime_stream_app/domain/models/availability_state.dart';
import 'package:anime_stream_app/domain/models/series.dart';
import 'package:anime_stream_app/domain/models/watchlist_entry.dart';
import 'package:anime_stream_app/domain/models/watchlist_snapshot.dart';
import 'package:anime_stream_app/domain/repositories/watchlist_repository.dart';
import 'package:anime_stream_app/features/watchlist/watchlist_screen.dart';

void main() {
  testWidgets(
    'WatchlistScreen keeps saved counts honest when some titles are unavailable',
    (tester) async {
      final repository = _FakeWatchlistRepository(
        snapshot: WatchlistSnapshot(
          entries: [
            WatchlistEntry(
              series: const Series(
                id: 'series-1',
                slug: 'frieren',
                title: 'Frieren',
                availability: AvailabilityState(),
              ),
              addedAt: DateTime(2026, 4, 8, 12),
            ),
          ],
          temporarilyUnavailableCount: 1,
        ),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            watchlistRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(home: WatchlistScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2 saved'), findsOneWidget);
      expect(find.text('1 unavailable'), findsOneWidget);
      expect(find.text('Some saved titles are unavailable'), findsOneWidget);
      expect(find.text('Frieren'), findsOneWidget);
      expect(find.text('No saved titles yet'), findsNothing);
    },
  );

  testWidgets(
    'WatchlistScreen does not collapse into empty state when all saved titles are temporarily unavailable',
    (tester) async {
      final repository = _FakeWatchlistRepository(
        snapshot: const WatchlistSnapshot(temporarilyUnavailableCount: 2),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            watchlistRepositoryProvider.overrideWithValue(repository),
          ],
          child: const MaterialApp(home: WatchlistScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('2 saved'), findsOneWidget);
      expect(find.text('2 unavailable'), findsOneWidget);
      expect(find.text('Some saved titles are unavailable'), findsOneWidget);
      expect(find.text('No saved titles yet'), findsNothing);
      expect(
        find.textContaining('Pull to refresh and try restoring them later'),
        findsOneWidget,
      );
    },
  );
}

class _FakeWatchlistRepository implements WatchlistRepository {
  const _FakeWatchlistRepository({required this.snapshot});

  final WatchlistSnapshot snapshot;

  @override
  Future<void> addToWatchlist(String seriesId) async {}

  @override
  Future<WatchlistSnapshot> getWatchlist() async => snapshot;

  @override
  Future<bool> isInWatchlist(String seriesId) async {
    return snapshot.entries.any((entry) => entry.series.id == seriesId);
  }

  @override
  Future<void> removeFromWatchlist(String seriesId) async {}
}
