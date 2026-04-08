import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anime_stream_app/app/browse/browse_providers.dart';
import 'package:anime_stream_app/domain/models/availability_state.dart';
import 'package:anime_stream_app/domain/models/series.dart';
import 'package:anime_stream_app/features/browse/browse_screen.dart';

void main() {
  testWidgets('BrowseScreen retries a failed load from the error state', (
    tester,
  ) async {
    var requests = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          browseCatalogProvider.overrideWith((ref) async {
            requests += 1;
            if (requests == 1) {
              throw StateError('browse failed');
            }
            return const BrowseCatalogData(
              latestReleases: [
                Series(
                  id: 'frieren',
                  slug: 'frieren',
                  title: 'Frieren',
                  availability: AvailabilityState(),
                ),
              ],
              trendingSeries: [],
              popularSeries: [],
            );
          }),
        ],
        child: const MaterialApp(home: BrowseScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Browse unavailable'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(requests, 2);
    expect(find.text('Frieren'), findsWidgets);
  });
}
