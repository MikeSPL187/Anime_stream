import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anime_stream_app/app/downloads/downloads_providers.dart';
import 'package:anime_stream_app/app/history/history_providers.dart';
import 'package:anime_stream_app/app/watchlist/watchlist_providers.dart';
import 'package:anime_stream_app/domain/models/download_entry.dart';
import 'package:anime_stream_app/domain/models/history_entry.dart';
import 'package:anime_stream_app/domain/models/watchlist_snapshot.dart';
import 'package:anime_stream_app/features/my_lists/my_lists_screen.dart';

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
}
