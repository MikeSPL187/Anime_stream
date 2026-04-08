import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:anime_stream_app/app/downloads/downloads_providers.dart';
import 'package:anime_stream_app/app/router/app_router.dart';
import 'package:anime_stream_app/app/series/series_providers.dart';
import 'package:anime_stream_app/domain/models/download_entry.dart';
import 'package:anime_stream_app/features/downloads/downloads_screen.dart';
import 'package:anime_stream_app/shared/widgets/anime_cached_artwork.dart';

void main() {
  testWidgets('DownloadsScreen retries a failed load from the error state', (
    tester,
  ) async {
    var requests = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          downloadsListProvider.overrideWith((ref) async {
            requests += 1;
            if (requests == 1) {
              throw StateError('downloads failed');
            }
            return const <DownloadEntry>[];
          }),
        ],
        child: const MaterialApp(home: DownloadsScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Downloads unavailable'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(requests, 2);
    expect(find.text('No downloads yet'), findsOneWidget);
  });

  test(
    'DownloadEntry display metadata prefers persisted labels over raw ids',
    () {
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

      expect(entry.displaySeriesTitle, 'Frieren');
      expect(entry.displayEpisodeNumberLabel, '3');
      expect(entry.displayEpisodeLabel, 'Episode 3');
      expect(entry.displayEpisodeTitle, 'Killing Magic');
    },
  );

  testWidgets(
    'DownloadsScreen opens offline-ready entries directly in player',
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
        initialLocation: AppRoutePaths.downloads,
        routes: [
          GoRoute(
            path: AppRoutePaths.downloads,
            builder: (context, state) => const DownloadsScreen(),
          ),
          GoRoute(
            path: AppRoutePaths.player,
            builder: (context, state) =>
                const Scaffold(body: Text('Player route')),
          ),
          GoRoute(
            path: AppRoutePaths.series,
            builder: (context, state) =>
                const Scaffold(body: Text('Series route')),
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
            downloadsListProvider.overrideWith((ref) async {
              return const [entry];
            }),
            seriesContentProvider('series-1').overrideWith((ref) async {
              throw StateError('series content failed');
            }),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      final card = find.ancestor(
        of: find.byType(AnimeCachedArtwork),
        matching: find.byType(InkWell),
      );
      await tester.ensureVisible(card.first);
      await tester.tap(card.first);
      await tester.pumpAndSettle();

      expect(find.text('Player route'), findsOneWidget);
      expect(find.text('Series route'), findsNothing);
    },
  );

  testWidgets('DownloadsScreen keeps failed entries on the series hub path', (
    tester,
  ) async {
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
      initialLocation: AppRoutePaths.downloads,
      routes: [
        GoRoute(
          path: AppRoutePaths.downloads,
          builder: (context, state) => const DownloadsScreen(),
        ),
        GoRoute(
          path: AppRoutePaths.player,
          builder: (context, state) =>
              const Scaffold(body: Text('Player route')),
        ),
        GoRoute(
          path: AppRoutePaths.series,
          builder: (context, state) =>
              const Scaffold(body: Text('Series route')),
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
          downloadsListProvider.overrideWith((ref) async {
            return const [entry];
          }),
          seriesContentProvider('series-1').overrideWith((ref) async {
            throw StateError('series content failed');
          }),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    final card = find.ancestor(
      of: find.byType(AnimeCachedArtwork),
      matching: find.byType(InkWell),
    );
    await tester.ensureVisible(card.first);
    await tester.tap(card.first);
    await tester.pumpAndSettle();

    expect(find.text('Series route'), findsOneWidget);
    expect(find.text('Player route'), findsNothing);
  });
}
