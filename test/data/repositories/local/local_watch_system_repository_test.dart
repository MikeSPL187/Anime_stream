import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:anime_stream_app/data/local/json_episode_progress_store.dart';
import 'package:anime_stream_app/data/repositories/local/local_watch_system_repository.dart';
import 'package:anime_stream_app/domain/models/availability_state.dart';
import 'package:anime_stream_app/domain/models/episode.dart';
import 'package:anime_stream_app/domain/models/episode_progress.dart';
import 'package:anime_stream_app/domain/models/series.dart';
import 'package:anime_stream_app/domain/models/series_catalog_page.dart';
import 'package:anime_stream_app/domain/repositories/series_repository.dart';

void main() {
  group('LocalWatchSystemRepository.getContinueWatching', () {
    test(
      'hydrates valid resumable entries and skips completed, trivial, missing, and unavailable progress',
      () async {
        final tempDirectory = await Directory.systemTemp.createTemp(
          'continue-watching-test',
        );
        addTearDown(() async {
          if (await tempDirectory.exists()) {
            await tempDirectory.delete(recursive: true);
          }
        });

        final progressStore = JsonEpisodeProgressStore(
          directoryProvider: () async => tempDirectory,
          relativeFilePath: 'episode_progress.json',
        );
        await progressStore.writeAll({
          'series-1::episode-3': EpisodeProgress(
            seriesId: 'series-1',
            episodeId: 'episode-3',
            position: const Duration(minutes: 12),
            totalDuration: const Duration(minutes: 24),
            updatedAt: DateTime(2026, 4, 5, 12, 0),
          ).toJson(),
          'series-2::episode-1': EpisodeProgress(
            seriesId: 'series-2',
            episodeId: 'episode-1',
            position: const Duration(minutes: 18),
            totalDuration: const Duration(minutes: 24),
            updatedAt: DateTime(2026, 4, 5, 13, 0),
          ).toJson(),
          'series-3::episode-5': EpisodeProgress(
            seriesId: 'series-3',
            episodeId: 'episode-5',
            position: const Duration(minutes: 9),
            updatedAt: DateTime(2026, 4, 5, 11, 30),
          ).toJson(),
          'series-1::episode-4': EpisodeProgress(
            seriesId: 'series-1',
            episodeId: 'episode-4',
            position: const Duration(seconds: 3),
            updatedAt: DateTime(2026, 4, 5, 14, 0),
          ).toJson(),
          'series-1::episode-5': EpisodeProgress(
            seriesId: 'series-1',
            episodeId: 'episode-5',
            position: const Duration(minutes: 24),
            totalDuration: const Duration(minutes: 24),
            isCompleted: true,
            updatedAt: DateTime(2026, 4, 5, 10, 0),
          ).toJson(),
          'missing::episode-1': EpisodeProgress(
            seriesId: 'missing',
            episodeId: 'episode-1',
            position: const Duration(minutes: 7),
            updatedAt: DateTime(2026, 4, 5, 9, 0),
          ).toJson(),
        });

        final repository = LocalWatchSystemRepository(
          episodeProgressStore: progressStore,
          seriesRepository: _FakeSeriesRepository(
            seriesById: {
              'series-1': const Series(
                id: 'series-1',
                slug: 'frieren',
                title: 'Frieren',
                availability: AvailabilityState(),
              ),
              'series-2': const Series(
                id: 'series-2',
                slug: 'monster',
                title: 'Monster',
                availability: AvailabilityState(),
              ),
              'series-3': const Series(
                id: 'series-3',
                slug: 'pluto',
                title: 'Pluto',
                availability: AvailabilityState(),
              ),
            },
            episodesBySeriesId: {
              'series-1': const [
                Episode(
                  id: 'episode-3',
                  seriesId: 'series-1',
                  sortOrder: 3,
                  numberLabel: '3',
                  title: 'Killing Magic',
                ),
                Episode(
                  id: 'episode-4',
                  seriesId: 'series-1',
                  sortOrder: 4,
                  numberLabel: '4',
                  title: 'The Land Where Souls Rest',
                ),
                Episode(
                  id: 'episode-5',
                  seriesId: 'series-1',
                  sortOrder: 5,
                  numberLabel: '5',
                  title: 'Phantoms of the Dead',
                ),
              ],
              'series-2': const [
                Episode(
                  id: 'episode-1',
                  seriesId: 'series-2',
                  sortOrder: 1,
                  numberLabel: '1',
                  title: 'Herr Dr. Tenma',
                  availability: AvailabilityState(
                    status: AvailabilityStatus.scheduled,
                  ),
                ),
              ],
              'series-3': const [
                Episode(
                  id: 'episode-5',
                  seriesId: 'series-3',
                  sortOrder: 5,
                  numberLabel: '5',
                  title: 'Memory of a Fragment',
                ),
              ],
            },
          ),
        );

        final entries = await repository.getContinueWatching(limit: 5);

        expect(entries, hasLength(2));
        expect(entries.first.series.title, 'Frieren');
        expect(entries.first.episode.id, 'episode-3');
        expect(entries.first.progress.position, const Duration(minutes: 12));
        expect(entries.last.series.title, 'Pluto');
        expect(entries.last.episode.id, 'episode-5');
      },
    );
  });

  group('LocalWatchSystemRepository.getWatchHistory', () {
    test(
      'hydrates completed watch activity and skips unfinished or missing entries',
      () async {
        final tempDirectory = await Directory.systemTemp.createTemp(
          'watch-history-test',
        );
        addTearDown(() async {
          if (await tempDirectory.exists()) {
            await tempDirectory.delete(recursive: true);
          }
        });

        final progressStore = JsonEpisodeProgressStore(
          directoryProvider: () async => tempDirectory,
          relativeFilePath: 'episode_progress.json',
        );
        await progressStore.writeAll({
          'series-1::episode-3': EpisodeProgress(
            seriesId: 'series-1',
            episodeId: 'episode-3',
            position: const Duration(minutes: 24),
            totalDuration: const Duration(minutes: 24),
            isCompleted: true,
            updatedAt: DateTime(2026, 4, 5, 12, 0),
          ).toJson(),
          'series-2::episode-1': EpisodeProgress(
            seriesId: 'series-2',
            episodeId: 'episode-1',
            position: const Duration(minutes: 18),
            totalDuration: const Duration(minutes: 24),
            updatedAt: DateTime(2026, 4, 5, 13, 0),
          ).toJson(),
          'series-3::episode-5': EpisodeProgress(
            seriesId: 'series-3',
            episodeId: 'episode-5',
            position: const Duration(minutes: 23),
            totalDuration: const Duration(minutes: 23),
            isCompleted: true,
            updatedAt: DateTime(2026, 4, 5, 11, 30),
          ).toJson(),
          'missing::episode-1': EpisodeProgress(
            seriesId: 'missing',
            episodeId: 'episode-1',
            position: const Duration(minutes: 20),
            totalDuration: const Duration(minutes: 20),
            isCompleted: true,
            updatedAt: DateTime(2026, 4, 5, 10, 0),
          ).toJson(),
        });

        final repository = LocalWatchSystemRepository(
          episodeProgressStore: progressStore,
          seriesRepository: _FakeSeriesRepository(
            seriesById: {
              'series-1': const Series(
                id: 'series-1',
                slug: 'frieren',
                title: 'Frieren',
                availability: AvailabilityState(),
              ),
              'series-3': const Series(
                id: 'series-3',
                slug: 'pluto',
                title: 'Pluto',
                availability: AvailabilityState(),
              ),
            },
            episodesBySeriesId: {
              'series-1': const [
                Episode(
                  id: 'episode-3',
                  seriesId: 'series-1',
                  sortOrder: 3,
                  numberLabel: '3',
                  title: 'Killing Magic',
                ),
              ],
              'series-3': const [
                Episode(
                  id: 'episode-5',
                  seriesId: 'series-3',
                  sortOrder: 5,
                  numberLabel: '5',
                  title: 'Memory of a Fragment',
                ),
              ],
            },
          ),
        );

        final entries = await repository.getWatchHistory(limit: 5);

        expect(entries, hasLength(2));
        expect(entries.first.series.title, 'Frieren');
        expect(entries.first.episode.id, 'episode-3');
        expect(entries.first.progress.isCompleted, isTrue);
        expect(entries.last.series.title, 'Pluto');
        expect(entries.last.episode.id, 'episode-5');
      },
    );
  });

  group('LocalWatchSystemRepository watched state operations', () {
    test(
      'markEpisodeWatched persists completed progress for the requested episode',
      () async {
        final tempDirectory = await Directory.systemTemp.createTemp(
          'watch-state-operations-test',
        );
        addTearDown(() async {
          if (await tempDirectory.exists()) {
            await tempDirectory.delete(recursive: true);
          }
        });

        final progressStore = JsonEpisodeProgressStore(
          directoryProvider: () async => tempDirectory,
          relativeFilePath: 'episode_progress.json',
        );
        final repository = LocalWatchSystemRepository(
          episodeProgressStore: progressStore,
          seriesRepository: _FakeSeriesRepository(
            seriesById: {
              'series-1': const Series(
                id: 'series-1',
                slug: 'frieren',
                title: 'Frieren',
                availability: AvailabilityState(),
              ),
            },
            episodesBySeriesId: {
              'series-1': const [
                Episode(
                  id: 'episode-2',
                  seriesId: 'series-1',
                  sortOrder: 2,
                  numberLabel: '2',
                  title: 'A New Journey',
                  duration: Duration(minutes: 24),
                ),
              ],
            },
          ),
        );

        await repository.markEpisodeWatched(
          seriesId: 'series-1',
          episodeId: 'episode-2',
        );

        final progress = await repository.getEpisodeProgress(
          seriesId: 'series-1',
          episodeId: 'episode-2',
        );

        expect(progress, isNotNull);
        expect(progress!.isCompleted, isTrue);
        expect(progress.position, const Duration(minutes: 24));
        expect(progress.totalDuration, const Duration(minutes: 24));
      },
    );

    test('markEpisodeUnwatched removes stored watched state', () async {
      final tempDirectory = await Directory.systemTemp.createTemp(
        'watch-state-reset-test',
      );
      addTearDown(() async {
        if (await tempDirectory.exists()) {
          await tempDirectory.delete(recursive: true);
        }
      });

      final progressStore = JsonEpisodeProgressStore(
        directoryProvider: () async => tempDirectory,
        relativeFilePath: 'episode_progress.json',
      );
      await progressStore.writeAll({
        'series-1::episode-2': EpisodeProgress(
          seriesId: 'series-1',
          episodeId: 'episode-2',
          position: const Duration(minutes: 24),
          totalDuration: const Duration(minutes: 24),
          isCompleted: true,
          updatedAt: DateTime(2026, 4, 7, 14, 0),
        ).toJson(),
      });

      final repository = LocalWatchSystemRepository(
        episodeProgressStore: progressStore,
        seriesRepository: _FakeSeriesRepository(
          seriesById: {
            'series-1': const Series(
              id: 'series-1',
              slug: 'frieren',
              title: 'Frieren',
              availability: AvailabilityState(),
            ),
          },
          episodesBySeriesId: {
            'series-1': const [
              Episode(
                id: 'episode-2',
                seriesId: 'series-1',
                sortOrder: 2,
                numberLabel: '2',
                title: 'A New Journey',
                duration: Duration(minutes: 24),
              ),
            ],
          },
        ),
      );

      await repository.markEpisodeUnwatched(
        seriesId: 'series-1',
        episodeId: 'episode-2',
      );

      final progress = await repository.getEpisodeProgress(
        seriesId: 'series-1',
        episodeId: 'episode-2',
      );

      expect(progress, isNull);
    });
  });
}

class _FakeSeriesRepository implements SeriesRepository {
  const _FakeSeriesRepository({
    required this.seriesById,
    required this.episodesBySeriesId,
  });

  final Map<String, Series> seriesById;
  final Map<String, List<Episode>> episodesBySeriesId;

  @override
  Future<List<Series>> getLatestSeries({int limit = 20}) async {
    throw UnimplementedError();
  }

  @override
  Future<List<Episode>> getEpisodes(String seriesId) async {
    return episodesBySeriesId[seriesId] ?? const [];
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
    final series = seriesById[seriesId];
    if (series == null) {
      throw StateError('Missing series $seriesId');
    }

    return series;
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
