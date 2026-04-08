import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anime_stream_app/app/di/downloads_repository_provider.dart';
import 'package:anime_stream_app/app/di/watchlist_repository_provider.dart';
import 'package:anime_stream_app/app/series/series_details_data.dart';
import 'package:anime_stream_app/app/series/series_providers.dart';
import 'package:anime_stream_app/domain/models/availability_state.dart';
import 'package:anime_stream_app/domain/models/download_entry.dart';
import 'package:anime_stream_app/domain/models/episode.dart';
import 'package:anime_stream_app/domain/models/series.dart';
import 'package:anime_stream_app/domain/models/watchlist_snapshot.dart';
import 'package:anime_stream_app/domain/repositories/downloads_repository.dart';
import 'package:anime_stream_app/domain/repositories/watchlist_repository.dart';
import 'package:anime_stream_app/features/series/series_screen.dart';

void main() {
  testWidgets(
    'SeriesScreen shows retry state and can recover from a load failure',
    (tester) async {
      var requests = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            seriesDetailsProvider.overrideWith((ref, seriesId) async {
              requests += 1;
              if (requests == 1) {
                throw StateError('series load failed');
              }

              return _seriesDetailsData();
            }),
            watchlistRepositoryProvider.overrideWithValue(
              _FakeWatchlistRepository(),
            ),
            downloadsRepositoryProvider.overrideWithValue(
              const _FakeDownloadsRepository(),
            ),
          ],
          child: const MaterialApp(home: SeriesScreen(seriesId: 'series-1')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Series unavailable'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(RefreshIndicator), findsOneWidget);
      expect(find.text('Frieren'), findsWidgets);
      await tester.scrollUntilVisible(
        find.text('Episodes'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Episodes'), findsOneWidget);
    },
  );

  testWidgets(
    'SeriesScreen surfaces degraded watch-state copy without losing the hub',
    (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            seriesDetailsProvider.overrideWith((ref, seriesId) async {
              return _seriesDetailsData(
                watchStateErrorMessage: 'watch progress unavailable',
              );
            }),
            watchlistRepositoryProvider.overrideWithValue(
              _FakeWatchlistRepository(),
            ),
            downloadsRepositoryProvider.overrideWithValue(
              const _FakeDownloadsRepository(),
            ),
          ],
          child: const MaterialApp(home: SeriesScreen(seriesId: 'series-1')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Watch activity unavailable'), findsWidgets);
      expect(find.text('Start Watching'), findsNothing);
      expect(find.text('Play Episode 1'), findsWidgets);
      expect(
        find.textContaining(
          'Resume progress and watched markers could not be loaded right now',
        ),
        findsWidgets,
      );
    },
  );

  testWidgets('SeriesScreen filters episodes by local finder query', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          seriesDetailsProvider.overrideWith((ref, seriesId) async {
            return _seriesDetailsData(
              episodes: const [
                Episode(
                  id: 'episode-1',
                  seriesId: 'series-1',
                  sortOrder: 1,
                  numberLabel: '1',
                  title: 'The Journey Begins',
                ),
                Episode(
                  id: 'episode-12',
                  seriesId: 'series-1',
                  sortOrder: 12,
                  numberLabel: '12',
                  title: 'First-Class Mage Exam',
                ),
                Episode(
                  id: 'episode-28',
                  seriesId: 'series-1',
                  sortOrder: 28,
                  numberLabel: '28',
                  title: 'An Old Friend',
                ),
              ],
            );
          }),
          watchlistRepositoryProvider.overrideWithValue(
            _FakeWatchlistRepository(),
          ),
          downloadsRepositoryProvider.overrideWithValue(
            const _FakeDownloadsRepository(),
          ),
        ],
        child: const MaterialApp(home: SeriesScreen(seriesId: 'series-1')),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byType(TextField),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('First-Class Mage Exam'), findsOneWidget);
    expect(find.text('An Old Friend'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '12');
    await tester.pumpAndSettle();

    expect(find.text('First-Class Mage Exam'), findsOneWidget);
    expect(find.text('The Journey Begins'), findsNothing);
    expect(find.text('An Old Friend'), findsNothing);

    await tester.enterText(find.byType(TextField), 'missing');
    await tester.pumpAndSettle();

    expect(find.text('Nothing in this filter'), findsOneWidget);
    expect(
      find.text('No episodes match "missing" in this view.'),
      findsOneWidget,
    );
  });
}

SeriesDetailsData _seriesDetailsData({
  String? watchStateErrorMessage,
  List<Episode> episodes = const [
    Episode(
      id: 'episode-1',
      seriesId: 'series-1',
      sortOrder: 1,
      numberLabel: '1',
      title: 'The Journey Begins',
    ),
  ],
}) {
  return SeriesDetailsData(
    series: const Series(
      id: 'series-1',
      slug: 'frieren',
      title: 'Frieren',
      availability: AvailabilityState(),
    ),
    episodes: episodes,
    watchStateErrorMessage: watchStateErrorMessage,
  );
}

class _FakeWatchlistRepository implements WatchlistRepository {
  @override
  Future<void> addToWatchlist(String seriesId) async {}

  @override
  Future<WatchlistSnapshot> getWatchlist() async => const WatchlistSnapshot();

  @override
  Future<bool> isInWatchlist(String seriesId) async => false;

  @override
  Future<void> removeFromWatchlist(String seriesId) async {}
}

class _FakeDownloadsRepository implements DownloadsRepository {
  const _FakeDownloadsRepository();

  @override
  Future<List<DownloadEntry>> getDownloads() async => const [];

  @override
  Future<DownloadEntry?> getPlayableDownload({
    required String seriesId,
    required String episodeId,
  }) async => null;

  @override
  Future<void> removeDownload(String downloadId) async {}

  @override
  Future<DownloadEntry> startEpisodeDownload({
    required String seriesId,
    required String episodeId,
    String selectedQuality = '1080p',
  }) async {
    throw UnimplementedError();
  }
}
