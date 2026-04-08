import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anime_stream_app/app/catalog/catalog_providers.dart';
import 'package:anime_stream_app/domain/models/series_catalog_page.dart';
import 'package:anime_stream_app/features/catalog/catalog_screen.dart';

void main() {
  testWidgets('CatalogScreen retries a failed load from the error state', (
    tester,
  ) async {
    var requests = 0;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogPageProvider.overrideWith((ref, page) async {
            requests += 1;
            if (requests == 1) {
              throw StateError('catalog failed');
            }
            return SeriesCatalogPage(
              items: const [],
              page: page,
              pageSize: catalogPageSize,
              totalItems: 0,
              totalPages: 1,
            );
          }),
        ],
        child: const MaterialApp(home: CatalogScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Catalog unavailable'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(requests, 2);
    expect(find.text('No titles on this page'), findsOneWidget);
  });
}
