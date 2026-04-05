import 'watchlist_entry.dart';

class CustomList {
  const CustomList({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.entries = const [],
  });

  final String id;
  final String name;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<WatchlistEntry> entries;
}
