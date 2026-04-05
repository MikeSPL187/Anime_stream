import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/local/json_watchlist_store.dart';
import '../../data/repositories/local/local_watchlist_repository.dart';
import '../../domain/repositories/watchlist_repository.dart';
import 'series_repository_provider.dart';

final watchlistStoreProvider = Provider<JsonWatchlistStore>((ref) {
  return JsonWatchlistStore(
    directoryProvider: getApplicationDocumentsDirectory,
  );
});

final watchlistRepositoryProvider = Provider<WatchlistRepository>((ref) {
  return LocalWatchlistRepository(
    watchlistStore: ref.watch(watchlistStoreProvider),
    seriesRepository: ref.watch(seriesRepositoryProvider),
  );
});
