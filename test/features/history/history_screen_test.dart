import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anime_stream_app/app/history/history_providers.dart';
import 'package:anime_stream_app/domain/models/history_entry.dart';
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
}
