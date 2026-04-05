import '../models/watchlist_entry.dart';

abstract interface class WatchlistRepository {
  Future<List<WatchlistEntry>> getWatchlist();

  Future<bool> isInWatchlist(String seriesId);

  Future<void> addToWatchlist(String seriesId);

  Future<void> removeFromWatchlist(String seriesId);
}
