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
      final results = await repository.searchSeries(query, limit: 20);
      return rankSearchSeriesResults(query: query, results: results);
    });

List<Series> rankSearchSeriesResults({
  required String query,
  required List<Series> results,
}) {
  final normalizedQuery = _normalizeSearchRankingValue(query);
  if (normalizedQuery.isEmpty || results.length < 2) {
    return results;
  }

  final ranked = results.toList(growable: false);
  ranked.sort((left, right) {
    final leftMatch = _rankSeriesSearchMatch(
      query: normalizedQuery,
      series: left,
    );
    final rightMatch = _rankSeriesSearchMatch(
      query: normalizedQuery,
      series: right,
    );

    final scoreComparison = rightMatch.score.compareTo(leftMatch.score);
    if (scoreComparison != 0) {
      return scoreComparison;
    }

    final distanceComparison = leftMatch.distance.compareTo(
      rightMatch.distance,
    );
    if (distanceComparison != 0) {
      return distanceComparison;
    }

    final updatedComparison = _compareDateDesc(
      left.lastUpdatedAt,
      right.lastUpdatedAt,
    );
    if (updatedComparison != 0) {
      return updatedComparison;
    }

    return left.title.toLowerCase().compareTo(right.title.toLowerCase());
  });

  return ranked;
}

_SearchSeriesMatch _rankSeriesSearchMatch({
  required String query,
  required Series series,
}) {
  final candidates = <_SearchSeriesCandidate>[
    _SearchSeriesCandidate(
      normalizedValue: _normalizeSearchRankingValue(series.title),
      bias: 24,
    ),
    if ((series.originalTitle ?? '').trim().isNotEmpty)
      _SearchSeriesCandidate(
        normalizedValue: _normalizeSearchRankingValue(series.originalTitle!),
        bias: 12,
      ),
    _SearchSeriesCandidate(
      normalizedValue: _normalizeSearchRankingValue(series.slug),
      bias: 0,
    ),
  ];

  var bestMatch = const _SearchSeriesMatch(score: 0, distance: 1 << 20);
  for (final candidate in candidates) {
    final match = _rankCandidateValue(
      query: query,
      normalizedCandidate: candidate.normalizedValue,
      bias: candidate.bias,
    );
    if (match.score > bestMatch.score ||
        (match.score == bestMatch.score &&
            match.distance < bestMatch.distance)) {
      bestMatch = match;
    }
  }

  return bestMatch;
}

_SearchSeriesMatch _rankCandidateValue({
  required String query,
  required String normalizedCandidate,
  required int bias,
}) {
  if (normalizedCandidate.isEmpty) {
    return const _SearchSeriesMatch(score: 0, distance: 1 << 20);
  }

  final distance = (normalizedCandidate.length - query.length).abs();
  if (normalizedCandidate == query) {
    return _SearchSeriesMatch(score: 600 + bias, distance: distance);
  }

  final candidateWords = normalizedCandidate.split(' ');
  if (candidateWords.any((word) => word == query)) {
    return _SearchSeriesMatch(score: 520 + bias, distance: distance);
  }
  if (normalizedCandidate.startsWith(query)) {
    return _SearchSeriesMatch(score: 460 + bias, distance: distance);
  }
  if (candidateWords.any((word) => word.startsWith(query))) {
    return _SearchSeriesMatch(score: 410 + bias, distance: distance);
  }
  if (normalizedCandidate.contains(query)) {
    return _SearchSeriesMatch(score: 320 + bias, distance: distance);
  }

  return _SearchSeriesMatch(score: 0, distance: distance);
}

int _compareDateDesc(DateTime? left, DateTime? right) {
  if (left == null && right == null) {
    return 0;
  }
  if (left == null) {
    return 1;
  }
  if (right == null) {
    return -1;
  }
  return right.compareTo(left);
}

String _normalizeSearchRankingValue(String rawValue) {
  return rawValue
      .trim()
      .toLowerCase()
      .replaceAll('-', ' ')
      .replaceAll(RegExp(r'[^a-z0-9а-яё ]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');
}

class _SearchSeriesCandidate {
  const _SearchSeriesCandidate({
    required this.normalizedValue,
    required this.bias,
  });

  final String normalizedValue;
  final int bias;
}

class _SearchSeriesMatch {
  const _SearchSeriesMatch({required this.score, required this.distance});

  final int score;
  final int distance;
}
