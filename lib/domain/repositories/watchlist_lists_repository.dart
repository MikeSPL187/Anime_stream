import '../models/custom_list.dart';
import '../models/watchlist_entry.dart';

abstract interface class WatchlistListsRepository {
  Future<List<WatchlistEntry>> getWatchlist();

  Future<void> addToWatchlist(String seriesId);

  Future<void> removeFromWatchlist(String seriesId);

  Future<List<CustomList>> getCustomLists();

  Future<CustomList> createCustomList({
    required String name,
    String? description,
  });

  Future<void> addSeriesToCustomList({
    required String customListId,
    required String seriesId,
  });

  Future<void> removeSeriesFromCustomList({
    required String customListId,
    required String seriesId,
  });
}
