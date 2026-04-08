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

    final hydrationResults = await Future.wait([
      for (final storedEntry in normalizedStore.entries)
        _hydrateWatchlistEntry(storedEntry),
    ]);

    final watchlist = <WatchlistEntry>[];
    var temporarilyUnavailableCount = 0;
    for (final result in hydrationResults) {
      switch (result.status) {
        case _WatchlistHydrationStatus.loaded:
          watchlist.add(result.entry!);
        case _WatchlistHydrationStatus.confirmedMissing:
          normalizedStore.storedEntries.remove(result.seriesId);
          normalizedStore.didMutateStore = true;
        case _WatchlistHydrationStatus.temporarilyUnavailable:
          temporarilyUnavailableCount += 1;
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

  Future<_WatchlistHydrationResult> _hydrateWatchlistEntry(
    _StoredWatchlistEntry storedEntry,
  ) async {
    try {
      final series = await _seriesRepository.getSeriesById(
        storedEntry.seriesId,
      );
      return _WatchlistHydrationResult.loaded(
        WatchlistEntry(series: series, addedAt: storedEntry.addedAt),
      );
    } on StateError {
      return _WatchlistHydrationResult.confirmedMissing(storedEntry.seriesId);
    } catch (_) {
      return const _WatchlistHydrationResult.temporarilyUnavailable();
    }
  }
}

enum _WatchlistHydrationStatus {
  loaded,
  confirmedMissing,
  temporarilyUnavailable,
}

class _WatchlistHydrationResult {
  const _WatchlistHydrationResult._({
    required this.status,
    this.entry,
    this.seriesId = '',
  });

  const _WatchlistHydrationResult.loaded(WatchlistEntry entry)
    : this._(status: _WatchlistHydrationStatus.loaded, entry: entry);

  const _WatchlistHydrationResult.confirmedMissing(String seriesId)
    : this._(
        status: _WatchlistHydrationStatus.confirmedMissing,
        seriesId: seriesId,
      );

  const _WatchlistHydrationResult.temporarilyUnavailable()
    : this._(status: _WatchlistHydrationStatus.temporarilyUnavailable);

  final _WatchlistHydrationStatus status;
  final WatchlistEntry? entry;
  final String seriesId;
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
