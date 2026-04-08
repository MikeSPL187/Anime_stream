import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:anime_stream_app/app/history/history_providers.dart';
import 'package:anime_stream_app/app/router/app_router.dart';
import 'package:anime_stream_app/domain/models/availability_state.dart';
import 'package:anime_stream_app/domain/models/episode.dart';
import 'package:anime_stream_app/domain/models/history_entry.dart';
import 'package:anime_stream_app/domain/models/episode_progress.dart';
import 'package:anime_stream_app/domain/models/series.dart';
import 'package:anime_stream_app/features/history/history_screen.dart';

void main() {
  testWidgets('HistoryScreen retries a failed load from the error state', (
    tester,
  ) async {
    var requests = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          watchHistoryProvider.overrideWith((ref) async {
            requests += 1;
            if (requests == 1) {
              throw StateError('history failed');
            }
            return const <HistoryEntry>[];
          }),
        ],
        child: const MaterialApp(home: HistoryScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('History unavailable'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(requests, 2);
    expect(find.text('No watch history yet'), findsOneWidget);
  });

  testWidgets(
    'HistoryScreen replays the completed episode from a history row',
    (tester) async {
      final router = GoRouter(
        initialLocation: AppRoutePaths.history,
        routes: [
          GoRoute(
            path: AppRoutePaths.history,
            builder: (context, state) => const HistoryScreen(),
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
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            watchHistoryProvider.overrideWith(
              (ref) async => [_sampleHistoryEntry],
            ),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Frieren: Beyond Journey\'s End'));
      await tester.pumpAndSettle();

      expect(find.text('Player route'), findsOneWidget);
    },
  );

  testWidgets('HistoryScreen keeps a secondary path back to the series hub', (
    tester,
  ) async {
    final router = GoRouter(
      initialLocation: AppRoutePaths.history,
      routes: [
        GoRoute(
          path: AppRoutePaths.history,
          builder: (context, state) => const HistoryScreen(),
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
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          watchHistoryProvider.overrideWith(
            (ref) async => [_sampleHistoryEntry],
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Open series'));
    await tester.pumpAndSettle();

    expect(find.text('Series route'), findsOneWidget);
  });
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
