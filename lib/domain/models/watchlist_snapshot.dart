import 'watchlist_entry.dart';

class WatchlistSnapshot {
  const WatchlistSnapshot({
    this.entries = const <WatchlistEntry>[],
    this.temporarilyUnavailableCount = 0,
  });

  final List<WatchlistEntry> entries;
  final int temporarilyUnavailableCount;

  int get visibleCount => entries.length;

  int get totalSavedCount => visibleCount + temporarilyUnavailableCount;

  bool get hasTemporarilyUnavailableEntries => temporarilyUnavailableCount > 0;

  bool get isEmpty => totalSavedCount == 0;
}
