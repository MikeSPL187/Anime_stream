import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/history_entry.dart';
import '../di/watch_system_repository_provider.dart';

final watchHistoryProvider = FutureProvider.autoDispose<List<HistoryEntry>>((
  ref,
) async {
  final repository = ref.watch(watchSystemRepositoryProvider);
  return repository.getWatchHistory(limit: 50);
});
