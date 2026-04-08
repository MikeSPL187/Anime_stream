import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anime_stream_app/app/browse/browse_providers.dart';
import 'package:anime_stream_app/app/di/series_repository_provider.dart';
import 'package:anime_stream_app/domain/models/availability_state.dart';
import 'package:anime_stream_app/domain/models/episode.dart';
import 'package:anime_stream_app/domain/models/series.dart';
import 'package:anime_stream_app/domain/models/series_catalog_page.dart';
import 'package:anime_stream_app/domain/repositories/series_repository.dart';

void main() {
  group('browseCatalogProvider', () {
    test('hydrates latest, trending, and popular catalog slices', () async {
      final repository = _FakeSeriesRepository();
      final container = ProviderContainer(
        overrides: [seriesRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final catalog = await container.read(browseCatalogProvider.future);

      expect(catalog.latestReleases.map((series) => series.id), ['latest-1']);
      expect(catalog.trendingSeries.map((series) => series.id), ['trending-1']);
      expect(catalog.popularSeries.map((series) => series.id), ['popular-1']);
      expect(repository.latestLimit, 8);
      expect(repository.trendingLimit, 8);
      expect(repository.popularLimit, 8);
      expect(catalog.hasAnyContent, isTrue);
    });

    test('keeps available slices when one browse source fails', () async {
      final repository = _FakeSeriesRepository(
        trendingError: StateError('Trending unavailable'),
      );
      final container = ProviderContainer(
        overrides: [seriesRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final catalog = await container.read(browseCatalogProvider.future);

      expect(catalog.latestReleases.map((series) => series.id), ['latest-1']);
      expect(catalog.trendingSeries, isEmpty);
      expect(
        catalog.trendingError,
        'This discovery slice could not be loaded right now.',
      );
      expect(catalog.popularSeries.map((series) => series.id), ['popular-1']);
      expect(catalog.hasAnyContent, isTrue);
      expect(catalog.hasAnyUnavailableSlice, isTrue);
    });
  });
}

class _FakeSeriesRepository implements SeriesRepository {
  _FakeSeriesRepository({this.trendingError});

  int? latestLimit;
  int? trendingLimit;
  int? popularLimit;
  final Object? trendingError;

  @override
  Future<List<Series>> getLatestSeries({int limit = 20}) async {
    latestLimit = limit;
    return const [
      Series(
        id: 'latest-1',
        slug: 'latest-1',
        title: 'Latest One',
        availability: AvailabilityState(),
      ),
    ];
  }

  @override
  Future<List<Episode>> getEpisodes(String seriesId) async {
    throw UnimplementedError();
  }

  @override
  Future<SeriesCatalogPage> getCatalogPage({
    int page = 1,
    int pageSize = 20,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<Series>> getPopularSeries({int limit = 20}) async {
    popularLimit = limit;
    return const [
      Series(
        id: 'popular-1',
        slug: 'popular-1',
        title: 'Popular One',
        availability: AvailabilityState(),
      ),
    ];
  }

  @override
  Future<Series> getSeriesById(String seriesId) async {
    throw UnimplementedError();
  }

  @override
  Future<List<Series>> getTrendingSeries({int limit = 20}) async {
    trendingLimit = limit;
    if (trendingError != null) {
      throw trendingError!;
    }
    return const [
      Series(
        id: 'trending-1',
        slug: 'trending-1',
        title: 'Trending One',
        availability: AvailabilityState(),
      ),
    ];
  }

  @override
  Future<List<Series>> searchSeries(String query, {int limit = 20}) async {
    throw UnimplementedError();
  }
}
