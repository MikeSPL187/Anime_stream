import '../../../domain/models/watchlist_entry.dart';
import '../../../domain/repositories/series_repository.dart';
import '../../../domain/repositories/watchlist_repository.dart';
import '../../local/json_watchlist_store.dart';

class LocalWatchlistRepository implements WatchlistRepository {
  LocalWatchlistRepository({
    required JsonWatchlistStore watchlistStore,
    required SeriesRepository seriesRepository,
  }) : _watchlistStore = watchlistStore,
       _seriesRepository = seriesRepository;

  final JsonWatchlistStore _watchlistStore;
  final SeriesRepository _seriesRepository;

  @override
  Future<void> addToWatchlist(String seriesId) async {
    final storedEntries = Map<String, dynamic>.from(
      await _watchlistStore.readAll(),
    );
    if (storedEntries.containsKey(seriesId)) {
      return;
    }

    storedEntries[seriesId] = _StoredWatchlistEntry(
      seriesId: seriesId,
      addedAt: DateTime.now().toUtc(),
    ).toJson();
    await _watchlistStore.writeAll(storedEntries);
  }

  @override
  Future<List<WatchlistEntry>> getWatchlist() async {
    final storedEntries = await _readStoredEntries();
    if (storedEntries.isEmpty) {
      return const [];
    }

    final watchlist = <WatchlistEntry>[];
    for (final storedEntry in storedEntries) {
      try {
        final series = await _seriesRepository.getSeriesById(
          storedEntry.seriesId,
        );
        watchlist.add(
          WatchlistEntry(series: series, addedAt: storedEntry.addedAt),
        );
      } catch (_) {
        continue;
      }
    }

    return List.unmodifiable(watchlist);
  }

  @override
  Future<bool> isInWatchlist(String seriesId) async {
    final storedEntries = await _watchlistStore.readAll();
    return storedEntries.containsKey(seriesId);
  }

  @override
  Future<void> removeFromWatchlist(String seriesId) async {
    final storedEntries = Map<String, dynamic>.from(
      await _watchlistStore.readAll(),
    );
    if (!storedEntries.containsKey(seriesId)) {
      return;
    }

    storedEntries.remove(seriesId);
    await _watchlistStore.writeAll(storedEntries);
  }

  Future<List<_StoredWatchlistEntry>> _readStoredEntries() async {
    final storedEntries = await _watchlistStore.readAll();
    final parsedEntries = <_StoredWatchlistEntry>[];

    for (final payload in storedEntries.values) {
      if (payload is! Map) {
        continue;
      }

      final entry = _StoredWatchlistEntry.tryParse(
        Map<String, dynamic>.from(payload),
      );
      if (entry != null) {
        parsedEntries.add(entry);
      }
    }

    parsedEntries.sort((left, right) => right.addedAt.compareTo(left.addedAt));
    return List.unmodifiable(parsedEntries);
  }
}

class _StoredWatchlistEntry {
  const _StoredWatchlistEntry({required this.seriesId, required this.addedAt});

  final String seriesId;
  final DateTime addedAt;

  Map<String, dynamic> toJson() {
    return {'seriesId': seriesId, 'addedAt': addedAt.toIso8601String()};
  }

  static _StoredWatchlistEntry? tryParse(Map<String, dynamic> json) {
    final seriesId = json['seriesId'];
    final addedAtRaw = json['addedAt'];
    if (seriesId is! String ||
        seriesId.trim().isEmpty ||
        addedAtRaw is! String) {
      return null;
    }

    final addedAt = DateTime.tryParse(addedAtRaw);
    if (addedAt == null) {
      return null;
    }

    return _StoredWatchlistEntry(seriesId: seriesId, addedAt: addedAt);
  }
}
