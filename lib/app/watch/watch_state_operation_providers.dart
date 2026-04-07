import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/watch_system_repository_provider.dart';
import '../history/history_providers.dart';
import '../home/home_continue_watching.dart';
import '../series/series_providers.dart';

final seriesWatchStateOperationsControllerProvider =
    AutoDisposeAsyncNotifierProviderFamily<
      SeriesWatchStateOperationsController,
      void,
      String
    >(SeriesWatchStateOperationsController.new);

class SeriesWatchStateOperationsController
    extends AutoDisposeFamilyAsyncNotifier<void, String> {
  late final String _seriesId;

  @override
  Future<void> build(String seriesId) async {
    _seriesId = seriesId;
  }

  Future<void> markEpisodeWatched(String episodeId) async {
    await _runOperation(() {
      return ref.read(watchSystemRepositoryProvider).markEpisodeWatched(
        seriesId: _seriesId,
        episodeId: episodeId,
      );
    });
  }

  Future<void> markEpisodeUnwatched(String episodeId) async {
    await _runOperation(() {
      return ref.read(watchSystemRepositoryProvider).markEpisodeUnwatched(
        seriesId: _seriesId,
        episodeId: episodeId,
      );
    });
  }

  Future<void> _runOperation(Future<void> Function() operation) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await operation();
      _invalidateWatchState();
    });
  }

  void _invalidateWatchState() {
    ref.invalidate(seriesDetailsProvider(_seriesId));
    ref.invalidate(homeContinueWatchingProvider);
    ref.invalidate(watchHistoryProvider);
  }
}
