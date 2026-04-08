import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anime_stream_app/app/home/home_continue_watching.dart';
import 'package:anime_stream_app/app/home/home_discovery.dart';
import 'package:anime_stream_app/app/router/app_router.dart';

void main() {
  testWidgets('AppRouter redirects invalid player entry back to Home', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        homeContinueWatchingProvider.overrideWith((ref) async => const []),
        homeDiscoveryProvider.overrideWith(
          (ref) async => const HomeDiscoveryData(
            latestReleases: [],
            trendingSeries: [],
            popularSeries: [],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(appRouterProvider);
    addTearDown(router.dispose);

    router.go(AppRoutePaths.player);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, AppRoutePaths.home);
  });

  testWidgets('AppRouter surfaces recovery state for an unknown route', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        homeContinueWatchingProvider.overrideWith((ref) async => const []),
        homeDiscoveryProvider.overrideWith(
          (ref) async => const HomeDiscoveryData(
            latestReleases: [],
            trendingSeries: [],
            popularSeries: [],
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(appRouterProvider);
    addTearDown(router.dispose);

    router.go('/missing-route');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('This screen is unavailable'), findsOneWidget);
    expect(find.text('/missing-route'), findsOneWidget);
    expect(find.text('Open Home'), findsOneWidget);

    await tester.tap(find.text('Open Home'));
    await tester.pumpAndSettle();

    expect(router.routeInformationProvider.value.uri.path, AppRoutePaths.home);
  });
}
