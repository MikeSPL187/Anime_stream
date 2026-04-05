import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anime_stream_app/app/di/watch_system_repository_provider.dart';
import 'package:anime_stream_app/app/home/home_continue_watching.dart';
import 'package:anime_stream_app/domain/models/availability_state.dart';
import 'package:anime_stream_app/domain/models/continue_watching_entry.dart';
import 'package:anime_stream_app/domain/models/episode.dart';
import 'package:anime_stream_app/domain/models/episode_progress.dart';
import 'package:anime_stream_app/domain/models/history_entry.dart';
import 'package:anime_stream_app/domain/models/series.dart';
import 'package:anime_stream_app/domain/repositories/watch_system_repository.dart';
import 'package:anime_stream_app/features/player/player_screen_context.dart';

void main() {
  group('homeContinueWatchingProvider', () {
    test(
      'maps continue-watching entries into resume-ready home items',
      () async {
        final container = ProviderContainer(
          overrides: [
            watchSystemRepositoryProvider.overrideWithValue(
              _FakeWatchSystemRepository(
                entries: [
                  ContinueWatchingEntry(
                    series: const Series(
                      id: 'series-1',
                      slug: 'frieren',
                      title: 'Frieren',
                      availability: AvailabilityState(),
                    ),
                    episode: const Episode(
                      id: 'episode-5',
                      seriesId: 'series-1',
                      sortOrder: 5,
                      numberLabel: '5',
                      title: 'Phantoms of the Dead',
                    ),
                    progress: EpisodeProgress(
                      seriesId: 'series-1',
                      episodeId: 'episode-5',
                      position: const Duration(minutes: 8),
                      totalDuration: const Duration(minutes: 24),
                      updatedAt: DateTime(2026, 4, 5, 11, 0),
                    ),
                    lastEngagedAt: DateTime(2026, 4, 5, 11, 0),
                  ),
                ],
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        final items = await container.read(homeContinueWatchingProvider.future);

        expect(items, hasLength(1));
        expect(items.single.seriesTitle, 'Frieren');
        expect(items.single.episodeTitle, 'Phantoms of the Dead');
        expect(items.single.episodeLabel, 'Episode 5');
        expect(items.single.progressLabel, '8m / 24m watched');
        expect(items.single.progressFraction, closeTo(0.3333, 0.001));
        expect(
          items.single.playerContext,
          const PlayerScreenContext(
            seriesId: 'series-1',
            seriesTitle: 'Frieren',
            episodeId: 'episode-5',
            episodeNumberLabel: '5',
            episodeTitle: 'Phantoms of the Dead',
          ),
        );
      },
    );
  });
}

class _FakeWatchSystemRepository implements WatchSystemRepository {
  const _FakeWatchSystemRepository({this.entries = const []});

  final List<ContinueWatchingEntry> entries;

  @override
  Future<List<ContinueWatchingEntry>> getContinueWatching({
    int limit = 20,
  }) async {
    return entries.take(limit).toList(growable: false);
  }

  @override
  Future<List<HistoryEntry>> getWatchHistory({int limit = 50}) async {
    return const [];
  }

  @override
  Future<EpisodeProgress?> getEpisodeProgress({
    required String seriesId,
    required String episodeId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<List<EpisodeProgress>> getSeriesEpisodeProgress({
    required String seriesId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> saveEpisodeProgress(EpisodeProgress progress) async {
    throw UnimplementedError();
  }
}
