import 'series.dart';

enum WatchlistEntryStatus {
  queued,
  watching,
  completed,
  paused,
  dropped,
}

class WatchlistEntry {
  const WatchlistEntry({
    required this.series,
    required this.addedAt,
    this.status = WatchlistEntryStatus.queued,
  });

  final Series series;
  final DateTime addedAt;
  final WatchlistEntryStatus status;
}
