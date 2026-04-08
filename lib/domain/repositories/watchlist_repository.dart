import '../models/watchlist_snapshot.dart';

abstract interface class WatchlistRepository {
  Future<WatchlistSnapshot> getWatchlist();

  Future<bool> isInWatchlist(String seriesId);

  Future<void> addToWatchlist(String seriesId);

  Future<void> removeFromWatchlist(String seriesId);
}
