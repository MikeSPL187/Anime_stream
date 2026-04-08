import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anime_stream_app/app/downloads/downloads_providers.dart';
import 'package:anime_stream_app/domain/models/download_entry.dart';
import 'package:anime_stream_app/features/downloads/downloads_screen.dart';

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
}
