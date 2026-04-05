import 'package:flutter_test/flutter_test.dart';

import 'package:anime_stream_app/app/series/series_details_data.dart';
import 'package:anime_stream_app/domain/models/episode.dart';
import 'package:anime_stream_app/domain/models/episode_progress.dart';
import 'package:anime_stream_app/domain/models/series.dart';

void main() {
  group('SeriesDetailsData.primaryWatchAction', () {
    test('resumes the latest in-progress episode when it is available', () {
      final details = SeriesDetailsData(
        series: _series(),
        episodes: _episodes(),
        episodeProgressById: {
          'episode-2': EpisodeProgress(
            seriesId: 'series-1',
            episodeId: 'episode-2',
            position: const Duration(minutes: 11),
            updatedAt: DateTime.parse('2026-04-05T10:30:00Z'),
          ),
        },
      );

      final action = details.primaryWatchAction;

      expect(action.kind, SeriesPrimaryWatchActionKind.resumeEpisode);
      expect(action.label, 'Resume Episode 2');
      expect(action.targetEpisode?.id, 'episode-2');
    });

    test('starts from the first episode when no saved progress exists', () {
      final details = SeriesDetailsData(
        series: _series(),
        episodes: _episodes(),
      );

      final action = details.primaryWatchAction;

      expect(action.kind, SeriesPrimaryWatchActionKind.startWatching);
      expect(action.label, 'Start Watching');
      expect(action.targetEpisode?.id, 'episode-1');
    });

    test('continues to the next episode when latest progress is completed', () {
      final details = SeriesDetailsData(
        series: _series(),
        episodes: _episodes(),
        episodeProgressById: {
          'episode-1': EpisodeProgress(
            seriesId: 'series-1',
            episodeId: 'episode-1',
            position: const Duration(minutes: 24),
            totalDuration: const Duration(minutes: 24),
            isCompleted: true,
            updatedAt: DateTime.parse('2026-04-05T10:30:00Z'),
          ),
        },
      );

      final action = details.primaryWatchAction;

      expect(action.kind, SeriesPrimaryWatchActionKind.continueEpisode);
      expect(action.label, 'Continue Episode 2');
      expect(action.targetEpisode?.id, 'episode-2');
    });

    test(
      'returns end-of-available-content when completed progress has no next episode',
      () {
        final details = SeriesDetailsData(
          series: _series(),
          episodes: _episodes(),
          episodeProgressById: {
            'episode-2': EpisodeProgress(
              seriesId: 'series-1',
              episodeId: 'episode-2',
              position: const Duration(minutes: 24),
              totalDuration: const Duration(minutes: 24),
              isCompleted: true,
              updatedAt: DateTime.parse('2026-04-05T10:30:00Z'),
            ),
          },
        );

        final action = details.primaryWatchAction;

        expect(action.kind, SeriesPrimaryWatchActionKind.endOfAvailableContent);
        expect(action.label, 'Up to Date');
        expect(action.targetEpisode, isNull);
      },
    );

    test(
      'falls back to start watching when latest progress cannot be matched',
      () {
        final details = SeriesDetailsData(
          series: _series(),
          episodes: _episodes(),
          episodeProgressById: {
            'missing-episode': EpisodeProgress(
              seriesId: 'series-1',
              episodeId: 'missing-episode',
              position: const Duration(minutes: 8),
              updatedAt: DateTime.parse('2026-04-05T10:30:00Z'),
            ),
          },
        );

        final action = details.primaryWatchAction;

        expect(action.kind, SeriesPrimaryWatchActionKind.startWatching);
        expect(action.targetEpisode?.id, 'episode-1');
      },
    );
  });
}

Series _series() {
  return const Series(id: 'series-1', slug: 'frieren', title: 'Frieren');
}

List<Episode> _episodes() {
  return const [
    Episode(
      id: 'episode-2',
      seriesId: 'series-1',
      sortOrder: 2,
      numberLabel: '2',
      title: 'Second Episode',
    ),
    Episode(
      id: 'episode-1',
      seriesId: 'series-1',
      sortOrder: 1,
      numberLabel: '1',
      title: 'First Episode',
    ),
  ];
}
