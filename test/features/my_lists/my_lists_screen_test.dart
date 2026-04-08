import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:anime_stream_app/app/downloads/downloads_providers.dart';
import 'package:anime_stream_app/app/history/history_providers.dart';
import 'package:anime_stream_app/app/router/app_router.dart';
import 'package:anime_stream_app/app/series/series_providers.dart';
import 'package:anime_stream_app/app/watchlist/watchlist_providers.dart';
import 'package:anime_stream_app/domain/models/availability_state.dart';
import 'package:anime_stream_app/domain/models/download_entry.dart';
import 'package:anime_stream_app/domain/models/episode.dart';
import 'package:anime_stream_app/domain/models/episode_progress.dart';
import 'package:anime_stream_app/domain/models/history_entry.dart';
import 'package:anime_stream_app/domain/models/series.dart';
import 'package:anime_stream_app/domain/models/watchlist_snapshot.dart';
import 'package:anime_stream_app/features/my_lists/my_lists_screen.dart';
import 'package:anime_stream_app/shared/widgets/anime_cached_artwork.dart';

void main() {
  testWidgets(
    'MyListsScreen refresh re-requests watchlist, downloads, and history',
    (tester) async {
      var watchlistRequests = 0;
      var downloadsRequests = 0;
      var historyRequests = 0;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            watchlistProvider.overrideWith((ref) async {
              watchlistRequests += 1;
              return const WatchlistSnapshot();
            }),
            downloadsListProvider.overrideWith((ref) async {
              downloadsRequests += 1;
              return const <DownloadEntry>[];
            }),
            watchHistoryProvider.overrideWith((ref) async {
              historyRequests += 1;
              return const <HistoryEntry>[];
            }),
          ],
          child: const MaterialApp(home: MyListsScreen()),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(watchlistRequests, 1);
      expect(downloadsRequests, 1);
      expect(historyRequests, 1);

      await tester.fling(
        find.byType(ListView).first,
        const Offset(0, 320),
        1000,
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump(const Duration(seconds: 1));

      expect(watchlistRequests, 2);
      expect(downloadsRequests, 2);
      expect(historyRequests, 2);
    },
  );

  testWidgets(
    'MyListsScreen keeps download metadata readable when content lookup fails',
    (tester) async {
      const entry = DownloadEntry(
        id: 'series-1::episode-3::1080p',
        seriesId: 'series-1',
        episodeId: 'episode-3',
        selectedQuality: '1080p',
        status: DownloadStatus.completed,
        seriesTitle: 'Frieren',
        episodeNumberLabel: '3',
        episodeTitle: 'Killing Magic',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            watchlistProvider.overrideWith((ref) async {
              return const WatchlistSnapshot();
            }),
            downloadsListProvider.overrideWith((ref) async {
              return const [entry];
            }),
            watchHistoryProvider.overrideWith((ref) async {
              return const <HistoryEntry>[];
            }),
            seriesContentProvider('series-1').overrideWith((ref) async {
              throw StateError('series content failed');
            }),
          ],
          child: const MaterialApp(home: MyListsScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Frieren'), findsWidgets);
      expect(find.text('Episode 3'), findsOneWidget);
      expect(find.text('series-1'), findsNothing);
    },
  );

  testWidgets('MyListsScreen history preview replays the completed episode', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: AppRoutePaths.myLists,
      routes: [
        GoRoute(
          path: AppRoutePaths.myLists,
          builder: (context, state) => const MyListsScreen(),
        ),
        GoRoute(
          path: AppRoutePaths.player,
          builder: (context, state) =>
              const Scaffold(body: Text('Player route')),
        ),
        GoRoute(
          path: AppRoutePaths.history,
          builder: (context, state) =>
              const Scaffold(body: Text('History route')),
        ),
        GoRoute(
          path: AppRoutePaths.search,
          builder: (context, state) =>
              const Scaffold(body: Text('Search route')),
        ),
        GoRoute(
          path: AppRoutePaths.settings,
          builder: (context, state) =>
              const Scaffold(body: Text('Settings route')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          watchlistProvider.overrideWith((ref) async {
            return const WatchlistSnapshot();
          }),
          downloadsListProvider.overrideWith((ref) async {
            return const <DownloadEntry>[];
          }),
          watchHistoryProvider.overrideWith(
            (ref) async => [_sampleHistoryEntry],
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Killing Magic'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Killing Magic'));
    await tester.pumpAndSettle();

    expect(find.text('Player route'), findsOneWidget);
  });

  testWidgets(
    'MyListsScreen download preview replays an offline-ready episode even when content lookup fails',
    (tester) async {
      const entry = DownloadEntry(
        id: 'series-1::episode-3::1080p',
        seriesId: 'series-1',
        episodeId: 'episode-3',
        selectedQuality: '1080p',
        status: DownloadStatus.completed,
        seriesTitle: 'Frieren',
        episodeNumberLabel: '3',
        episodeTitle: 'Killing Magic',
        localAssetUri: '/tmp/frieren-episode-3.m3u8',
      );
      final router = GoRouter(
        initialLocation: AppRoutePaths.myLists,
        routes: [
          GoRoute(
            path: AppRoutePaths.myLists,
            builder: (context, state) => const MyListsScreen(),
          ),
          GoRoute(
            path: AppRoutePaths.player,
            builder: (context, state) =>
                const Scaffold(body: Text('Player route')),
          ),
          GoRoute(
            path: AppRoutePaths.downloads,
            builder: (context, state) =>
                const Scaffold(body: Text('Downloads route')),
          ),
          GoRoute(
            path: AppRoutePaths.history,
            builder: (context, state) =>
                const Scaffold(body: Text('History route')),
          ),
          GoRoute(
            path: AppRoutePaths.search,
            builder: (context, state) =>
                const Scaffold(body: Text('Search route')),
          ),
          GoRoute(
            path: AppRoutePaths.settings,
            builder: (context, state) =>
                const Scaffold(body: Text('Settings route')),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            watchlistProvider.overrideWith((ref) async {
              return const WatchlistSnapshot();
            }),
            downloadsListProvider.overrideWith((ref) async {
              return const [entry];
            }),
            watchHistoryProvider.overrideWith((ref) async {
              return const <HistoryEntry>[];
            }),
            seriesContentProvider('series-1').overrideWith((ref) async {
              throw StateError('series content failed');
            }),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      final previewCard = find.ancestor(
        of: find.byType(AnimeCachedArtwork),
        matching: find.byType(InkWell),
      );
      await tester.ensureVisible(previewCard.first);
      await tester.pumpAndSettle();
      await tester.tap(previewCard.first);
      await tester.pumpAndSettle();

      expect(find.text('Player route'), findsOneWidget);
      expect(find.text('Downloads route'), findsNothing);
    },
  );

  testWidgets(
    'MyListsScreen non-playable download preview stays on the downloads route',
    (tester) async {
      const entry = DownloadEntry(
        id: 'series-1::episode-3::1080p',
        seriesId: 'series-1',
        episodeId: 'episode-3',
        selectedQuality: '1080p',
        status: DownloadStatus.failed,
        seriesTitle: 'Frieren',
        episodeNumberLabel: '3',
        episodeTitle: 'Killing Magic',
      );
      final router = GoRouter(
        initialLocation: AppRoutePaths.myLists,
        routes: [
          GoRoute(
            path: AppRoutePaths.myLists,
            builder: (context, state) => const MyListsScreen(),
          ),
          GoRoute(
            path: AppRoutePaths.player,
            builder: (context, state) =>
                const Scaffold(body: Text('Player route')),
          ),
          GoRoute(
            path: AppRoutePaths.downloads,
            builder: (context, state) =>
                const Scaffold(body: Text('Downloads route')),
          ),
          GoRoute(
            path: AppRoutePaths.history,
            builder: (context, state) =>
                const Scaffold(body: Text('History route')),
          ),
          GoRoute(
            path: AppRoutePaths.search,
            builder: (context, state) =>
                const Scaffold(body: Text('Search route')),
          ),
          GoRoute(
            path: AppRoutePaths.settings,
            builder: (context, state) =>
                const Scaffold(body: Text('Settings route')),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            watchlistProvider.overrideWith((ref) async {
              return const WatchlistSnapshot();
            }),
            downloadsListProvider.overrideWith((ref) async {
              return const [entry];
            }),
            watchHistoryProvider.overrideWith((ref) async {
              return const <HistoryEntry>[];
            }),
            seriesContentProvider('series-1').overrideWith((ref) async {
              throw StateError('series content failed');
            }),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      final previewCard = find.ancestor(
        of: find.byType(AnimeCachedArtwork),
        matching: find.byType(InkWell),
      );
      await tester.ensureVisible(previewCard.first);
      await tester.pumpAndSettle();
      await tester.tap(previewCard.first);
      await tester.pumpAndSettle();

      expect(find.text('Downloads route'), findsOneWidget);
      expect(find.text('Player route'), findsNothing);
    },
  );
}

final _sampleHistoryEntry = HistoryEntry(
  id: 'history-1',
  series: const Series(
    id: 'series-1',
    slug: 'frieren',
    title: 'Frieren: Beyond Journey\'s End',
    availability: AvailabilityState(),
  ),
  episode: const Episode(
    id: 'episode-3',
    seriesId: 'series-1',
    sortOrder: 3,
    numberLabel: '3',
    title: 'Killing Magic',
    availability: AvailabilityState(),
  ),
  progress: EpisodeProgress(
    seriesId: 'series-1',
    episodeId: 'episode-3',
    position: Duration(minutes: 24),
    totalDuration: Duration(minutes: 24),
    isCompleted: true,
    updatedAt: DateTime(2026, 4, 8),
  ),
  watchedAt: DateTime(2026, 4, 8),
);
