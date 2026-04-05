import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/series.dart';
import '../di/series_repository_provider.dart';

const minimumSearchQueryLength = 2;

String normalizeSearchQuery(String rawQuery) {
  return rawQuery.trim();
}

bool canExecuteSearchQuery(String rawQuery) {
  return normalizeSearchQuery(rawQuery).length >= minimumSearchQueryLength;
}

final searchSeriesProvider = FutureProvider.autoDispose
    .family<List<Series>, String>((ref, rawQuery) async {
      final query = normalizeSearchQuery(rawQuery);
      if (query.length < minimumSearchQueryLength) {
        return const [];
      }

      final repository = ref.watch(seriesRepositoryProvider);
      return repository.searchSeries(query, limit: 20);
    });
