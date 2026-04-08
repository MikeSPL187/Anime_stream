import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anime_stream_app/app/di/series_repository_provider.dart';
import 'package:anime_stream_app/domain/models/episode.dart';
import 'package:anime_stream_app/domain/models/series.dart';
import 'package:anime_stream_app/domain/models/series_catalog_page.dart';
import 'package:anime_stream_app/domain/repositories/series_repository.dart';
import 'package:anime_stream_app/features/search/search_screen.dart';

void main() {
  testWidgets(
    'SearchScreen commits the query immediately when the keyboard search action is pressed',
    (tester) async {
      final repository = _FakeSeriesRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [seriesRepositoryProvider.overrideWithValue(repository)],
          child: const MaterialApp(home: SearchScreen()),
        ),
      );
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'frieren');
      await tester.pump();

      expect(repository.lastSearchQuery, isNull);
      expect(find.text('Ready to search'), findsOneWidget);

      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pump();

      expect(repository.lastSearchQuery, 'frieren');
    },
  );

  testWidgets('SearchScreen retries the submitted query from the error state', (
    tester,
  ) async {
    final repository = _FakeSeriesRepository(failFirstSearch: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [seriesRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: SearchScreen()),
      ),
    );
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'frieren');
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pump();
    await tester.pumpAndSettle();

    expect(repository.searchRequests, 1);
    expect(find.text('Search unavailable'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(repository.searchRequests, 2);
    expect(find.text('Top match'), findsWidgets);
    expect(find.text('Search unavailable'), findsNothing);
  });
}

class _FakeSeriesRepository implements SeriesRepository {
  _FakeSeriesRepository({this.failFirstSearch = false});

  final bool failFirstSearch;
  String? lastSearchQuery;
  int searchRequests = 0;

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
    searchRequests += 1;
    lastSearchQuery = query;
    if (failFirstSearch && searchRequests == 1) {
      throw StateError('search failed');
    }
    return const [Series(id: 'frieren', slug: 'frieren', title: 'Frieren')];
  }
}
