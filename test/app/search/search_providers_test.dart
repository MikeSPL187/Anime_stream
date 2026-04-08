import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anime_stream_app/app/di/series_repository_provider.dart';
import 'package:anime_stream_app/app/search/search_providers.dart';
import 'package:anime_stream_app/domain/models/episode.dart';
import 'package:anime_stream_app/domain/models/series.dart';
import 'package:anime_stream_app/domain/models/series_catalog_page.dart';
import 'package:anime_stream_app/domain/repositories/series_repository.dart';

void main() {
  group('searchSeriesProvider', () {
    test(
      'trims the query before delegating to the series repository',
      () async {
        final repository = _FakeSeriesRepository(
          searchResults: const [
            Series(id: '42', slug: 'fate-apocrypha', title: 'Fate/Apocrypha'),
          ],
        );
        final container = ProviderContainer(
          overrides: [seriesRepositoryProvider.overrideWithValue(repository)],
        );
        addTearDown(container.dispose);

        final results = await container.read(
          searchSeriesProvider('  fate  ').future,
        );

        expect(results, hasLength(1));
        expect(repository.lastSearchQuery, 'fate');
        expect(repository.lastSearchLimit, 20);
      },
    );

    test(
      'returns no results and skips repository work for short queries',
      () async {
        final repository = _FakeSeriesRepository();
        final container = ProviderContainer(
          overrides: [seriesRepositoryProvider.overrideWithValue(repository)],
        );
        addTearDown(container.dispose);

        final results = await container.read(searchSeriesProvider('a').future);

        expect(results, isEmpty);
        expect(repository.lastSearchQuery, isNull);
      },
    );

    test(
      'ranks an exact title match ahead of looser provider ordering',
      () async {
        final repository = _FakeSeriesRepository(
          searchResults: const [
            Series(
              id: 'boruto',
              slug: 'boruto',
              title: 'Boruto: Naruto Next Generations',
            ),
            Series(id: 'naruto', slug: 'naruto', title: 'Naruto'),
          ],
        );
        final container = ProviderContainer(
          overrides: [seriesRepositoryProvider.overrideWithValue(repository)],
        );
        addTearDown(container.dispose);

        final results = await container.read(
          searchSeriesProvider('naruto').future,
        );

        expect(results, hasLength(2));
        expect(results.first.id, 'naruto');
      },
    );

    test('uses original title matches to improve result ordering', () async {
      final repository = _FakeSeriesRepository(
        searchResults: const [
          Series(
            id: 'spy-family-catalog',
            slug: 'spy-family-catalog',
            title: 'Catalog Special',
            originalTitle: 'Spy x Family',
          ),
          Series(
            id: 'family-comedy',
            slug: 'family-comedy',
            title: 'Family Comedy Hour',
          ),
        ],
      );
      final container = ProviderContainer(
        overrides: [seriesRepositoryProvider.overrideWithValue(repository)],
      );
      addTearDown(container.dispose);

      final results = await container.read(
        searchSeriesProvider('spy x family').future,
      );

      expect(results, hasLength(2));
      expect(results.first.id, 'spy-family-catalog');
    });
  });
}

class _FakeSeriesRepository implements SeriesRepository {
  _FakeSeriesRepository({this.searchResults = const []});

  final List<Series> searchResults;
  String? lastSearchQuery;
  int? lastSearchLimit;

  @override
  Future<List<Series>> getLatestSeries({int limit = 20}) async {
    throw UnimplementedError();
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
    lastSearchQuery = query;
    lastSearchLimit = limit;
    return searchResults;
  }
}
