import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anime_stream_app/app/di/series_repository_provider.dart';
import 'package:anime_stream_app/app/player/player_playback_providers.dart';
import 'package:anime_stream_app/data/adapters/anilibria/anilibria_remote_data_source.dart';
import 'package:anime_stream_app/data/dto/anilibria/anilibria_episode_dto.dart';
import 'package:anime_stream_app/data/dto/anilibria/anilibria_release_dto.dart';
import 'package:anime_stream_app/data/dto/anilibria/anilibria_release_page_dto.dart';
import 'package:anime_stream_app/domain/models/availability_state.dart';
import 'package:anime_stream_app/domain/models/download_entry.dart';
import 'package:anime_stream_app/domain/models/episode.dart';
import 'package:anime_stream_app/domain/models/series.dart';
import 'package:anime_stream_app/domain/models/series_catalog_page.dart';
import 'package:anime_stream_app/domain/repositories/downloads_repository.dart';
import 'package:anime_stream_app/domain/repositories/series_repository.dart';
import 'package:anime_stream_app/features/player/player_screen_context.dart';

void main() {
  group('playerPreviousEpisodeContextProvider', () {
    test(
      'resolves the previous episode context from the current player session',
      () async {
        final container = ProviderContainer(
          overrides: [
            seriesRepositoryProvider.overrideWithValue(
              _FakeSeriesRepository(
                series: const Series(
                  id: 'series-8',
                  slug: 'kaiju-no-8',
                  title: 'Kaiju No. 8',
                  availability: AvailabilityState(),
                ),
                episodes: const [
                  Episode(
                    id: 'episode-7',
                    seriesId: 'series-8',
                    sortOrder: 7,
                    numberLabel: '7',
                    title: 'Thunderstorm',
                  ),
                  Episode(
                    id: 'episode-8',
                    seriesId: 'series-8',
                    sortOrder: 8,
                    numberLabel: '8',
                    title: 'Welcome to the Defense Force',
                  ),
                ],
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        final previousContext = await container.read(
          playerPreviousEpisodeContextProvider(
            const PlayerScreenContext(
              seriesId: 'series-8',
              seriesTitle: 'Kaiju No. 8',
              episodeId: 'episode-8',
              episodeNumberLabel: '8',
              episodeTitle: 'Welcome to the Defense Force',
            ),
          ).future,
        );

        expect(previousContext, isNotNull);
        expect(previousContext?.episodeId, 'episode-7');
        expect(previousContext?.episodeNumberLabel, '7');
        expect(previousContext?.episodeTitle, 'Thunderstorm');
      },
    );

    test(
      'returns null when the current player session is already at the first episode',
      () async {
        final container = ProviderContainer(
          overrides: [
            seriesRepositoryProvider.overrideWithValue(
              _FakeSeriesRepository(
                series: const Series(
                  id: 'series-9',
                  slug: 'pluto',
                  title: 'Pluto',
                  availability: AvailabilityState(),
                ),
                episodes: const [
                  Episode(
                    id: 'episode-1',
                    seriesId: 'series-9',
                    sortOrder: 1,
                    numberLabel: '1',
                    title: 'Inheritance',
                  ),
                ],
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        final previousContext = await container.read(
          playerPreviousEpisodeContextProvider(
            const PlayerScreenContext(
              seriesId: 'series-9',
              seriesTitle: 'Pluto',
              episodeId: 'episode-1',
              episodeNumberLabel: '1',
              episodeTitle: 'Inheritance',
            ),
          ).future,
        );

        expect(previousContext, isNull);
      },
    );
  });

  group('playerNextEpisodeContextProvider', () {
    test(
      'resolves the next episode context from the current player session',
      () async {
        final container = ProviderContainer(
          overrides: [
            seriesRepositoryProvider.overrideWithValue(
              _FakeSeriesRepository(
                series: const Series(
                  id: 'series-8',
                  slug: 'kaiju-no-8',
                  title: 'Kaiju No. 8',
                  availability: AvailabilityState(),
                ),
                episodes: const [
                  Episode(
                    id: 'episode-7',
                    seriesId: 'series-8',
                    sortOrder: 7,
                    numberLabel: '7',
                    title: 'Thunderstorm',
                  ),
                  Episode(
                    id: 'episode-8',
                    seriesId: 'series-8',
                    sortOrder: 8,
                    numberLabel: '8',
                    title: 'Welcome to the Defense Force',
                  ),
                ],
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        final nextContext = await container.read(
          playerNextEpisodeContextProvider(
            const PlayerScreenContext(
              seriesId: 'series-8',
              seriesTitle: 'Kaiju No. 8',
              episodeId: 'episode-7',
              episodeNumberLabel: '7',
              episodeTitle: 'Thunderstorm',
            ),
          ).future,
        );

        expect(nextContext, isNotNull);
        expect(nextContext?.episodeId, 'episode-8');
        expect(nextContext?.episodeNumberLabel, '8');
        expect(nextContext?.episodeTitle, 'Welcome to the Defense Force');
      },
    );

    test(
      'returns null when the current player session is already at the last episode',
      () async {
        final container = ProviderContainer(
          overrides: [
            seriesRepositoryProvider.overrideWithValue(
              _FakeSeriesRepository(
                series: const Series(
                  id: 'series-9',
                  slug: 'pluto',
                  title: 'Pluto',
                  availability: AvailabilityState(),
                ),
                episodes: const [
                  Episode(
                    id: 'episode-8',
                    seriesId: 'series-9',
                    sortOrder: 8,
                    numberLabel: '8',
                    title: 'Inheritance',
                  ),
                ],
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        final nextContext = await container.read(
          playerNextEpisodeContextProvider(
            const PlayerScreenContext(
              seriesId: 'series-9',
              seriesTitle: 'Pluto',
              episodeId: 'episode-8',
              episodeNumberLabel: '8',
              episodeTitle: 'Inheritance',
            ),
          ).future,
        );

        expect(nextContext, isNull);
      },
    );
  });

  group('PlayerPlaybackResolver', () {
    test(
      'resolves playback from shared release details by episode id',
      () async {
        final remoteDataSource = _FakeAnilibriaRemoteDataSource(
          release: const AnilibriaReleaseDto(
            id: 'series-501',
            episodes: [
              AnilibriaEpisodeDto(
                id: 'episode-7',
                releaseId: 'series-501',
                ordinal: 7,
                numberLabel: '7',
                title: 'The Real Thing',
                hls720Url: 'https://cdn.example.com/episode-7-720.m3u8',
                hls1080Url: 'https://cdn.example.com/episode-7-1080.m3u8',
              ),
            ],
          ),
        );
        final resolver = PlayerPlaybackResolver(
          remoteDataSource: remoteDataSource,
          downloadsRepository: const _NoOpDownloadsRepository(),
        );

        final source = await resolver.resolve(
          const PlayerScreenContext(
            seriesId: 'series-501',
            seriesTitle: 'Pluto',
            episodeId: 'episode-7',
            episodeNumberLabel: '7',
            episodeTitle: 'The Real Thing',
          ),
        );

        expect(remoteDataSource.requestedReleaseIds, ['series-501']);
        expect(source.qualityLabel, '1080p');
        expect(source.streamUri, 'https://cdn.example.com/episode-7-1080.m3u8');
      },
    );

    test('matches by episode number label when ids differ', () async {
      final resolver = PlayerPlaybackResolver(
        remoteDataSource: _FakeAnilibriaRemoteDataSource(
          release: const AnilibriaReleaseDto(
            id: 'series-42',
            episodes: [
              AnilibriaEpisodeDto(
                id: 'provider-episode-2-5',
                releaseId: 'series-42',
                ordinal: 2500,
                numberLabel: '2.5',
                title: 'Bonus Episode',
                hls720Url: 'https://cdn.example.com/bonus-720.m3u8',
              ),
            ],
          ),
        ),
        downloadsRepository: const _NoOpDownloadsRepository(),
      );

      final source = await resolver.resolve(
        const PlayerScreenContext(
          seriesId: 'series-42',
          seriesTitle: 'Monster',
          episodeId: 'ui-episode-id',
          episodeNumberLabel: '2.5',
          episodeTitle: 'Untrusted UI Title',
        ),
      );

      expect(source.qualityLabel, '720p');
      expect(source.streamUri, 'https://cdn.example.com/bonus-720.m3u8');
    });

    test('throws when the matched episode has no supported HLS stream', () async {
      final resolver = PlayerPlaybackResolver(
        remoteDataSource: _FakeAnilibriaRemoteDataSource(
          release: const AnilibriaReleaseDto(
            id: 'series-12',
            episodes: [
              AnilibriaEpisodeDto(
                id: 'episode-1',
                releaseId: 'series-12',
                ordinal: 1,
                numberLabel: '1',
                title: 'Pilot',
              ),
            ],
          ),
        ),
        downloadsRepository: const _NoOpDownloadsRepository(),
      );

      await expectLater(
        () => resolver.resolve(
          const PlayerScreenContext(
            seriesId: 'series-12',
            seriesTitle: 'Serial Experiments Lain',
            episodeId: 'episode-1',
            episodeNumberLabel: '1',
            episodeTitle: 'Pilot',
          ),
        ),
        throwsA(
          isA<PlayerPlaybackResolutionException>().having(
            (error) => error.message,
            'message',
            'No supported remote playback variants are available for Episode 1.',
          ),
        ),
      );
    });
  });
}

class _NoOpDownloadsRepository implements DownloadsRepository {
  const _NoOpDownloadsRepository();

  @override
  Future<List<DownloadEntry>> getDownloads() async => const [];

  @override
  Future<DownloadEntry?> getPlayableDownload({
    required String seriesId,
    required String episodeId,
  }) async => null;

  @override
  Future<DownloadEntry> startEpisodeDownload({
    required String seriesId,
    required String episodeId,
    String selectedQuality = '1080p',
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<void> removeDownload(String downloadId) async {}
}

class _FakeSeriesRepository implements SeriesRepository {
  const _FakeSeriesRepository({required this.series, required this.episodes});

  final Series series;
  final List<Episode> episodes;

  @override
  Future<List<Series>> getLatestSeries({int limit = 20}) async {
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
  Future<List<Episode>> getEpisodes(String seriesId) async {
    return episodes;
  }

  @override
  Future<List<Series>> getPopularSeries({int limit = 20}) async {
    throw UnimplementedError();
  }

  @override
  Future<Series> getSeriesById(String seriesId) async {
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

class _FakeAnilibriaRemoteDataSource implements AnilibriaRemoteDataSource {
  _FakeAnilibriaRemoteDataSource({required this.release});

  final AnilibriaReleaseDto release;
  final List<String> requestedReleaseIds = [];

  @override
  Future<AnilibriaReleaseDto> fetchReleaseDetails(String releaseId) async {
    requestedReleaseIds.add(releaseId);
    return release;
  }

  @override
  Future<List<AnilibriaReleaseDto>> fetchLatestReleases({int limit = 20}) {
    throw UnimplementedError();
  }

  @override
  Future<List<AnilibriaReleaseDto>> fetchPopularReleases({int limit = 20}) {
    throw UnimplementedError();
  }

  @override
  Future<AnilibriaReleasePageDto> fetchCatalogPage({
    int page = 1,
    int limit = 20,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<AnilibriaEpisodeDto>> fetchReleaseEpisodes(String releaseId) {
    throw UnimplementedError();
  }

  @override
  Future<List<AnilibriaReleaseDto>> fetchSimulcastReleases({int limit = 20}) {
    throw UnimplementedError();
  }

  @override
  Future<List<AnilibriaReleaseDto>> fetchTrendingReleases({int limit = 20}) {
    throw UnimplementedError();
  }

  @override
  Future<List<AnilibriaReleaseDto>> searchReleases(
    String query, {
    int limit = 20,
  }) {
    throw UnimplementedError();
  }
}
