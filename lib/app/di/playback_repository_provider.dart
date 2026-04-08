import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../data/local/json_playback_preferences_store.dart';
import '../../data/repositories/local/local_playback_repository.dart';
import '../../domain/repositories/playback_repository.dart';

final playbackPreferencesStoreProvider = Provider<JsonPlaybackPreferencesStore>(
  (ref) {
    return JsonPlaybackPreferencesStore(
      directoryProvider: getApplicationDocumentsDirectory,
    );
  },
);

final playbackRepositoryProvider = Provider<PlaybackRepository>((ref) {
  return LocalPlaybackRepository(
    playbackPreferencesStore: ref.watch(playbackPreferencesStoreProvider),
  );
});
