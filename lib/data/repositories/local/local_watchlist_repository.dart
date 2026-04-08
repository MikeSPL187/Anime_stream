import '../../../domain/models/watchlist_entry.dart';
import '../../../domain/models/watchlist_snapshot.dart';
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
  Future<WatchlistSnapshot> getWatchlist() async {
    final normalizedStore = await _readNormalizedStore();
    if (normalizedStore.entries.isEmpty) {
      await _persistNormalizedStoreIfNeeded(normalizedStore);
      return const WatchlistSnapshot();
    }

    final watchlist = <WatchlistEntry>[];
    var temporarilyUnavailableCount = 0;
    for (final storedEntry in normalizedStore.entries) {
      try {
        final series = await _seriesRepository.getSeriesById(
          storedEntry.seriesId,
        );
        watchlist.add(
          WatchlistEntry(series: series, addedAt: storedEntry.addedAt),
        );
      } on StateError {
        normalizedStore.storedEntries.remove(storedEntry.seriesId);
        normalizedStore.didMutateStore = true;
        continue;
      } catch (_) {
        temporarilyUnavailableCount += 1;
        continue;
      }
    }

    await _persistNormalizedStoreIfNeeded(normalizedStore);
    return WatchlistSnapshot(
      entries: List.unmodifiable(watchlist),
      temporarilyUnavailableCount: temporarilyUnavailableCount,
    );
  }

  @override
  Future<bool> isInWatchlist(String seriesId) async {
    final normalizedStore = await _readNormalizedStore();
    final storedEntry = normalizedStore.entryById(seriesId);
    if (storedEntry == null) {
      await _persistNormalizedStoreIfNeeded(normalizedStore);
      return false;
    }

    try {
      await _seriesRepository.getSeriesById(seriesId);
      await _persistNormalizedStoreIfNeeded(normalizedStore);
      return true;
    } on StateError {
      normalizedStore.storedEntries.remove(seriesId);
      normalizedStore.didMutateStore = true;
      await _persistNormalizedStoreIfNeeded(normalizedStore);
      return false;
    } catch (_) {
      await _persistNormalizedStoreIfNeeded(normalizedStore);
      return true;
    }
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

  Future<_NormalizedWatchlistStore> _readNormalizedStore() async {
    final storedEntries = Map<String, dynamic>.from(
      await _watchlistStore.readAll(),
    );
    final parsedEntries = <_StoredWatchlistEntry>[];
    var didMutateStore = false;

    for (final MapEntry(key: seriesId, value: payload)
        in storedEntries.entries.toList(growable: false)) {
      if (payload is! Map) {
        storedEntries.remove(seriesId);
        didMutateStore = true;
        continue;
      }

      final entry = _StoredWatchlistEntry.tryParse(
        Map<String, dynamic>.from(payload),
      );
      if (entry == null || entry.seriesId != seriesId) {
        storedEntries.remove(seriesId);
        didMutateStore = true;
        continue;
      }

      parsedEntries.add(entry);
    }

    parsedEntries.sort((left, right) => right.addedAt.compareTo(left.addedAt));
    return _NormalizedWatchlistStore(
      entries: parsedEntries,
      storedEntries: storedEntries,
      didMutateStore: didMutateStore,
    );
  }

  Future<void> _persistNormalizedStoreIfNeeded(
    _NormalizedWatchlistStore normalizedStore,
  ) async {
    if (!normalizedStore.didMutateStore) {
      return;
    }

    await _watchlistStore.writeAll(normalizedStore.storedEntries);
  }
}

class _NormalizedWatchlistStore {
  _NormalizedWatchlistStore({
    required this.entries,
    required this.storedEntries,
    required this.didMutateStore,
  });

  final List<_StoredWatchlistEntry> entries;
  final Map<String, dynamic> storedEntries;
  bool didMutateStore;

  _StoredWatchlistEntry? entryById(String seriesId) {
    for (final entry in entries) {
      if (entry.seriesId == seriesId) {
        return entry;
      }
    }

    return null;
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
