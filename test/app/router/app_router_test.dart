import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anime_stream_app/app/browse/browse_providers.dart';
import 'package:anime_stream_app/app/home/home_continue_watching.dart';
import 'package:anime_stream_app/app/router/app_router.dart';
import 'package:anime_stream_app/app/series/series_providers.dart';

void main() {
  testWidgets('AppRouter redirects invalid player entry back to Home', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: [
        featuredSeriesProvider.overrideWith((ref) async => const []),
        homeContinueWatchingProvider.overrideWith((ref) async => const []),
        browseCatalogProvider.overrideWith(
          (ref) async => const BrowseCatalogData(
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
}
