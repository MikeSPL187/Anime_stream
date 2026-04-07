import 'package:flutter_test/flutter_test.dart';

import 'package:anime_stream_app/app/player/player_progress_providers.dart';
import 'package:anime_stream_app/domain/models/continue_watching_entry.dart';
import 'package:anime_stream_app/domain/models/episode_progress.dart';
import 'package:anime_stream_app/domain/models/history_entry.dart';
import 'package:anime_stream_app/domain/repositories/watch_system_repository.dart';
import 'package:anime_stream_app/features/player/player_screen_context.dart';

void main() {
  group('PlayerProgressController', () {
    test(
      'loads episode progress through the watch-system repository seam',
      () async {
        final repository = _FakeWatchSystemRepository(
          progress: EpisodeProgress(
            seriesId: 'series-10',
            episodeId: 'episode-4',
            position: const Duration(minutes: 6),
            updatedAt: DateTime.parse('2026-04-05T11:00:00Z'),
          ),
        );
        final controller = PlayerProgressController(
          watchSystemRepository: repository,
        );

        final restored = await controller.loadEpisodeProgress(
          const PlayerScreenContext(
            seriesId: 'series-10',
            seriesTitle: 'Frieren',
            episodeId: 'episode-4',
            episodeNumberLabel: '4',
            episodeTitle: 'Departure',
          ),
        );

        expect(restored?.position, const Duration(minutes: 6));
        expect(repository.lastReadSeriesId, 'series-10');
        expect(repository.lastReadEpisodeId, 'episode-4');
      },
    );

    test(
      'skips trivial in-playback writes below the minimum threshold',
      () async {
        final repository = _FakeWatchSystemRepository();
        final controller = PlayerProgressController(
          watchSystemRepository: repository,
        );

        await controller.savePlaybackSnapshot(
          const PlayerScreenContext(
            seriesId: 'series-11',
            seriesTitle: 'Monster',
            episodeId: 'episode-1',
            episodeNumberLabel: '1',
            episodeTitle: 'Herr Dr. Tenma',
          ),
          position: const Duration(seconds: 3),
          totalDuration: const Duration(minutes: 24),
          isCompleted: false,
        );

        expect(repository.savedProgress, isNull);
      },
    );

    test(
      'persists a completed playback snapshot with total duration',
      () async {
        final repository = _FakeWatchSystemRepository();
        final controller = PlayerProgressController(
          watchSystemRepository: repository,
        );

        await controller.savePlaybackSnapshot(
          const PlayerScreenContext(
            seriesId: 'series-12',
            seriesTitle: 'Pluto',
            episodeId: 'episode-8',
            episodeNumberLabel: '8',
            episodeTitle: 'Inheritance',
          ),
          position: const Duration(minutes: 18),
          totalDuration: const Duration(minutes: 24),
          isCompleted: true,
        );

        expect(repository.savedProgress, isNotNull);
        expect(repository.savedProgress?.seriesId, 'series-12');
        expect(repository.savedProgress?.episodeId, 'episode-8');
        expect(repository.savedProgress?.position, const Duration(minutes: 24));
        expect(
          repository.savedProgress?.totalDuration,
          const Duration(minutes: 24),
        );
        expect(repository.savedProgress?.isCompleted, isTrue);
      },
    );
  });
}

class _FakeWatchSystemRepository implements WatchSystemRepository {
  _FakeWatchSystemRepository({this.progress});

  final EpisodeProgress? progress;
  String? lastReadSeriesId;
  String? lastReadEpisodeId;
  EpisodeProgress? savedProgress;

  @override
  Future<List<ContinueWatchingEntry>> getContinueWatching({
    int limit = 20,
  }) async {
    return const [];
  }

  @override
  Future<List<HistoryEntry>> getWatchHistory({int limit = 50}) async {
    return const [];
  }

  @override
  Future<List<EpisodeProgress>> getSeriesEpisodeProgress({
    required String seriesId,
  }) async {
    return progress == null || progress?.seriesId != seriesId
        ? const []
        : [progress!];
  }

  @override
  Future<EpisodeProgress?> getEpisodeProgress({
    required String seriesId,
    required String episodeId,
  }) async {
    lastReadSeriesId = seriesId;
    lastReadEpisodeId = episodeId;
    return progress;
  }

  @override
  Future<void> saveEpisodeProgress(EpisodeProgress progress) async {
    savedProgress = progress;
  }

  @override
  Future<void> markEpisodeWatched({
    required String seriesId,
    required String episodeId,
  }) async {}

  @override
  Future<void> markEpisodeUnwatched({
    required String seriesId,
    required String episodeId,
  }) async {}
}
