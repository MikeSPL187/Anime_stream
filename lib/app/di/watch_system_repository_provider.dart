import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/local/json_episode_progress_store.dart';
import '../../data/repositories/local/local_watch_system_repository.dart';
import '../../domain/repositories/watch_system_repository.dart';
import 'series_repository_provider.dart';

final episodeProgressStoreProvider = Provider<JsonEpisodeProgressStore>((ref) {
  return JsonEpisodeProgressStore(
    directoryProvider: getApplicationDocumentsDirectory,
  );
});

final watchSystemRepositoryProvider = Provider<WatchSystemRepository>((ref) {
  return LocalWatchSystemRepository(
    episodeProgressStore: ref.watch(episodeProgressStoreProvider),
    seriesRepository: ref.watch(seriesRepositoryProvider),
  );
});
