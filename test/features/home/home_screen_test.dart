import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anime_stream_app/app/home/home_continue_watching.dart';
import 'package:anime_stream_app/app/home/home_discovery.dart';
import 'package:anime_stream_app/domain/models/availability_state.dart';
import 'package:anime_stream_app/domain/models/series.dart';
import 'package:anime_stream_app/features/home/home_screen.dart';
import 'package:anime_stream_app/features/player/player_screen_context.dart';

void main() {
  testWidgets(
    'Home surfaces continue watching while remote discovery is still loading',
    (tester) async {
      final discoveryCompleter = Completer<HomeDiscoveryData>();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeContinueWatchingProvider.overrideWith(
              (ref) async => [_homeContinueWatchingItem()],
            ),
            homeDiscoveryProvider.overrideWith(
              (ref) => discoveryCompleter.future,
            ),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pump();

      expect(find.text('Continue Watching'), findsOneWidget);
      expect(find.text('Episode 5'), findsOneWidget);
      expect(find.text('Latest Spotlight'), findsOneWidget);
      expect(find.text('Latest release unavailable'), findsNothing);
    },
  );

  testWidgets('Home refresh re-requests continue watching and discovery data', (
    tester,
  ) async {
    var continueWatchingRequests = 0;
    var discoveryRequests = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeContinueWatchingProvider.overrideWith((ref) async {
            continueWatchingRequests += 1;
            return [_homeContinueWatchingItem()];
          }),
          homeDiscoveryProvider.overrideWith((ref) async {
            discoveryRequests += 1;
            return HomeDiscoveryData(
              latestReleases: [_series(id: 'latest-$discoveryRequests')],
              trendingSeries: const [],
              popularSeries: const [],
            );
          }),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(continueWatchingRequests, 1);
    expect(discoveryRequests, 1);

    await tester.fling(find.byType(ListView).first, const Offset(0, 320), 1000);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));

    expect(continueWatchingRequests, 2);
    expect(discoveryRequests, 2);
  });

  testWidgets('Home retries discovery from the inline error action', (
    tester,
  ) async {
    var discoveryRequests = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeContinueWatchingProvider.overrideWith(
            (ref) async => const <HomeContinueWatchingItem>[],
          ),
          homeDiscoveryProvider.overrideWith((ref) async {
            discoveryRequests += 1;
            if (discoveryRequests == 1) {
              throw StateError('discovery failed');
            }
            return HomeDiscoveryData(
              latestReleases: [_series(id: 'latest-2')],
              trendingSeries: const [],
              popularSeries: const [],
            );
          }),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Latest Spotlight'), findsOneWidget);
    expect(find.text('Retry'), findsWidgets);

    await tester.tap(find.text('Retry').first);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(discoveryRequests, 2);
    expect(find.text('Open Series'), findsOneWidget);
  });

  testWidgets('Home latest spotlight keeps an honest browse CTA label', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          homeContinueWatchingProvider.overrideWith(
            (ref) async => const <HomeContinueWatchingItem>[],
          ),
          homeDiscoveryProvider.overrideWith(
            (ref) async => HomeDiscoveryData(
              latestReleases: [_series(id: 'latest-1')],
              trendingSeries: const [],
              popularSeries: const [],
            ),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Open Browse'), findsOneWidget);
    expect(find.text('Browse latest'), findsNothing);
  });
}

HomeContinueWatchingItem _homeContinueWatchingItem() {
  return const HomeContinueWatchingItem(
    seriesTitle: 'Frieren',
    episodeTitle: 'Phantoms of the Dead',
    episodeLabel: 'Episode 5',
    progressLabel: '8m / 24m watched',
    progressFraction: 0.33,
    playerContext: PlayerScreenContext(
      seriesId: 'series-1',
      seriesTitle: 'Frieren',
      episodeId: 'episode-5',
      episodeNumberLabel: '5',
      episodeTitle: 'Phantoms of the Dead',
    ),
  );
}

Series _series({required String id}) {
  return Series(
    id: id,
    slug: id,
    title: 'Frieren',
    availability: const AvailabilityState(),
  );
}
