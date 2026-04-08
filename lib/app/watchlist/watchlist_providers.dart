import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/watchlist_snapshot.dart';
import '../di/watchlist_repository_provider.dart';

final watchlistProvider = FutureProvider.autoDispose<WatchlistSnapshot>((
  ref,
) async {
  final repository = ref.watch(watchlistRepositoryProvider);
  return repository.getWatchlist();
});

final watchlistMembershipControllerProvider =
    AutoDisposeAsyncNotifierProviderFamily<
      WatchlistMembershipController,
      bool,
      String
    >(WatchlistMembershipController.new);

class WatchlistMembershipController
    extends AutoDisposeFamilyAsyncNotifier<bool, String> {
  late final String _seriesId;

  @override
  Future<bool> build(String seriesId) async {
    _seriesId = seriesId;
    return ref.watch(watchlistRepositoryProvider).isInWatchlist(seriesId);
  }

  Future<void> addToWatchlist() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(watchlistRepositoryProvider).addToWatchlist(_seriesId);
      _invalidateWatchlist();
      return true;
    });
  }

  Future<void> removeFromWatchlist() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(watchlistRepositoryProvider)
          .removeFromWatchlist(_seriesId);
      _invalidateWatchlist();
      return false;
    });
  }

  void _invalidateWatchlist() {
    ref.invalidate(watchlistProvider);
  }
}
