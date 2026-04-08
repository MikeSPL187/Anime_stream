import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anime_stream_app/app/catalog/catalog_providers.dart';
import 'package:anime_stream_app/app/di/series_repository_provider.dart';
import 'package:anime_stream_app/domain/models/availability_state.dart';
import 'package:anime_stream_app/domain/models/episode.dart';
import 'package:anime_stream_app/domain/models/series.dart';
import 'package:anime_stream_app/domain/models/series_catalog_page.dart';
import 'package:anime_stream_app/domain/repositories/series_repository.dart';

void main() {
  group('catalogPageProvider', () {
    test(
      'hydrates a paged catalog listing from the series repository',
      () async {
        final repository = _FakeSeriesRepository();
        final container = ProviderContainer(
          overrides: [seriesRepositoryProvider.overrideWithValue(repository)],
        );
        addTearDown(container.dispose);

        final page = await container.read(catalogPageProvider(2).future);

        expect(repository.lastPage, 2);
        expect(repository.lastPageSize, catalogPageSize);
        expect(page.items.map((series) => series.id), ['catalog-2-1']);
        expect(page.page, 2);
        expect(page.totalPages, 5);
      },
    );
  });
}

class _FakeSeriesRepository implements SeriesRepository {
  int? lastPage;
  int? lastPageSize;

  @override
  Future<SeriesCatalogPage> getCatalogPage({
    int page = 1,
    int pageSize = 20,
  }) async {
    lastPage = page;
    lastPageSize = pageSize;

    return SeriesCatalogPage(
      items: [
        Series(
          id: 'catalog-$page-1',
          slug: 'catalog-$page-1',
          title: 'Catalog $page',
          availability: const AvailabilityState(),
        ),
      ],
      page: page,
      pageSize: pageSize,
      totalItems: 100,
      totalPages: 5,
    );
  }

  @override
  Future<List<Series>> getLatestSeries({int limit = 20}) async {
    throw UnimplementedError();
  }

  @override
  Future<List<Episode>> getEpisodes(String seriesId) async {
    throw UnimplementedError();
  }

  @override
  Future<List<Series>> getPopularSeries({int limit = 20}) async {
    throw UnimplementedError();
  }

  @override
  Future<Series> getSeriesById(String seriesId) async {
    throw UnimplementedError();
  }

  @override
  Future<List<Series>> getTrendingSeries({int limit = 20}) async {
    throw UnimplementedError();
  }

  @override
  Future<List<Series>> searchSeries(String query, {int limit = 20}) async {
    throw UnimplementedError();
  }
}
