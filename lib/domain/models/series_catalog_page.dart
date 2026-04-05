import 'series.dart';

class SeriesCatalogPage {
  /// Plain page-based catalog listing without semantic grouping guarantees.
  const SeriesCatalogPage({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalItems,
    required this.totalPages,
  }) : assert(page > 0, 'Catalog page index must be positive.'),
       assert(pageSize > 0, 'Catalog page size must be positive.'),
       assert(totalItems >= 0, 'Catalog total item count cannot be negative.'),
       assert(totalPages >= 0, 'Catalog total page count cannot be negative.');

  final List<Series> items;
  final int page;
  final int pageSize;
  final int totalItems;
  final int totalPages;

  bool get hasPreviousPage => page > 1;
  bool get hasNextPage => page < totalPages;
}
