import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anime_stream_app/app/di/series_repository_provider.dart';
import 'package:anime_stream_app/app/home/home_discovery.dart';
import 'package:anime_stream_app/domain/models/availability_state.dart';
import 'package:anime_stream_app/domain/models/episode.dart';
import 'package:anime_stream_app/domain/models/series.dart';
import 'package:anime_stream_app/domain/models/series_catalog_page.dart';
import 'package:anime_stream_app/domain/repositories/series_repository.dart';

void main() {
  group('homeDiscoveryProvider', () {
    test('hydrates home discovery slices with home-specific limits', () async {
      final repository = _FakeSeriesRepository();
      final container = ProviderContainer(
        overrides: [seriesRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final discovery = await container.read(homeDiscoveryProvider.future);

      expect(discovery.latestReleases.map((series) => series.id), ['latest-1']);
      expect(discovery.trendingSeries.map((series) => series.id), [
        'trending-1',
      ]);
      expect(discovery.popularSeries.map((series) => series.id), ['popular-1']);
      expect(repository.latestLimit, 20);
      expect(repository.trendingLimit, 8);
      expect(repository.popularLimit, 8);
      expect(discovery.hasAnyContent, isTrue);
      expect(discovery.hasAnyUnavailableSlice, isFalse);
    });

    test(
      'keeps other home slices available when latest releases fail',
      () async {
        final repository = _FakeSeriesRepository(
          latestError: StateError('Latest releases unavailable'),
        );
        final container = ProviderContainer(
          overrides: [seriesRepositoryProvider.overrideWithValue(repository)],
        );
        addTearDown(container.dispose);

        final discovery = await container.read(homeDiscoveryProvider.future);

        expect(discovery.latestReleases, isEmpty);
        expect(
          discovery.latestError,
          'This discovery section could not be loaded right now.',
        );
        expect(discovery.trendingSeries.map((series) => series.id), [
          'trending-1',
        ]);
        expect(discovery.popularSeries.map((series) => series.id), [
          'popular-1',
        ]);
        expect(discovery.hasAnyContent, isTrue);
        expect(discovery.hasAnyUnavailableSlice, isTrue);
      },
    );
  });
}

class _FakeSeriesRepository implements SeriesRepository {
  _FakeSeriesRepository({this.latestError});

  int? latestLimit;
  int? trendingLimit;
  int? popularLimit;
  final Object? latestError;

  @override
  Future<List<Series>> getLatestSeries({int limit = 20}) async {
    latestLimit = limit;
    if (latestError != null) {
      throw latestError!;
    }
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
