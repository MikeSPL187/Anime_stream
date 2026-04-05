import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/series_catalog_page.dart';
import '../di/series_repository_provider.dart';

const catalogPageSize = 20;

final catalogPageProvider = FutureProvider.autoDispose
    .family<SeriesCatalogPage, int>((ref, page) async {
      final repository = ref.watch(seriesRepositoryProvider);
      final safePage = page < 1 ? 1 : page;

      return repository.getCatalogPage(
        page: safePage,
        pageSize: catalogPageSize,
      );
    });
