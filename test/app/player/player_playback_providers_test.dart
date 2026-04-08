import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:anime_stream_app/app/di/downloads_repository_provider.dart';
import 'package:anime_stream_app/app/di/episode_playback_repository_provider.dart';
import 'package:anime_stream_app/app/di/series_repository_provider.dart';
import 'package:anime_stream_app/app/player/player_playback_providers.dart';
import 'package:anime_stream_app/domain/models/availability_state.dart';
import 'package:anime_stream_app/domain/models/download_entry.dart';
import 'package:anime_stream_app/domain/models/episode.dart';
import 'package:anime_stream_app/domain/models/episode_playback_variant.dart';
import 'package:anime_stream_app/domain/models/episode_selector.dart';
import 'package:anime_stream_app/domain/models/series.dart';
import 'package:anime_stream_app/domain/models/series_catalog_page.dart';
import 'package:anime_stream_app/domain/repositories/downloads_repository.dart';
import 'package:anime_stream_app/domain/repositories/episode_playback_repository.dart';
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
      'reuses the same playback source provider key when only display copy changes',
      () async {
        final playbackRepository = _FakeEpisodePlaybackRepository(
          variants: const [
            EpisodePlaybackVariant(
              sourceUri: 'https://cdn.example.com/episode-7-1080.m3u8',
              qualityLabel: '1080p',
            ),
          ],
        );
        final firstContext = const PlayerScreenContext(
          seriesId: 'series-501',
          seriesTitle: 'Pluto',
          episodeId: 'episode-7',
          episodeNumberLabel: '7',
          episodeTitle: 'The Real Thing',
        );
        final renamedContext = const PlayerScreenContext(
          seriesId: 'series-501',
          seriesTitle: 'Pluto Remastered',
          episodeId: 'episode-7',
          episodeNumberLabel: '07',
          episodeTitle: 'The Real Thing - Director Cut',
        );
        final container = ProviderContainer(
          overrides: [
            episodePlaybackRepositoryProvider.overrideWithValue(
              playbackRepository,
            ),
            downloadsRepositoryProvider.overrideWithValue(
              const _NoOpDownloadsRepository(),
            ),
          ],
        );
        addTearDown(container.dispose);

        expect(firstContext, renamedContext);

        final subscription = container.listen(
          playerPlaybackSourceProvider(firstContext),
          (_, _) {},
        );
        addTearDown(subscription.close);

        await container.read(playerPlaybackSourceProvider(firstContext).future);
        await container.read(
          playerPlaybackSourceProvider(renamedContext).future,
        );

        expect(playbackRepository.requestedSeriesIds, ['series-501']);
        expect(playbackRepository.requestedSelectors, [
          const EpisodeSelector(
            episodeId: 'episode-7',
            episodeNumberLabel: '7',
            episodeTitle: 'The Real Thing',
          ),
        ]);
      },
    );

    test(
      'treats different episode ids as different playback source keys',
      () async {
        final playbackRepository = _FakeEpisodePlaybackRepository(
          variants: const [
            EpisodePlaybackVariant(
              sourceUri: 'https://cdn.example.com/episode-7-1080.m3u8',
              qualityLabel: '1080p',
            ),
          ],
        );
        final firstContext = const PlayerScreenContext(
          seriesId: 'series-501',
          seriesTitle: 'Pluto',
          episodeId: 'episode-7',
          episodeNumberLabel: '7',
          episodeTitle: 'The Real Thing',
        );
        final nextEpisodeContext = const PlayerScreenContext(
          seriesId: 'series-501',
          seriesTitle: 'Pluto',
          episodeId: 'episode-8',
          episodeNumberLabel: '8',
          episodeTitle: 'Another Episode',
        );
        final container = ProviderContainer(
          overrides: [
            episodePlaybackRepositoryProvider.overrideWithValue(
              playbackRepository,
            ),
            downloadsRepositoryProvider.overrideWithValue(
              const _NoOpDownloadsRepository(),
            ),
          ],
        );
        addTearDown(container.dispose);

        expect(firstContext == nextEpisodeContext, isFalse);

        final subscription = container.listen(
          playerPlaybackSourceProvider(firstContext),
          (_, _) {},
        );
        addTearDown(subscription.close);

        await container.read(playerPlaybackSourceProvider(firstContext).future);
        await container.read(
          playerPlaybackSourceProvider(nextEpisodeContext).future,
        );

        expect(playbackRepository.requestedSeriesIds, [
          'series-501',
          'series-501',
        ]);
        expect(playbackRepository.requestedSelectors, [
          const EpisodeSelector(
            episodeId: 'episode-7',
            episodeNumberLabel: '7',
            episodeTitle: 'The Real Thing',
          ),
          const EpisodeSelector(
            episodeId: 'episode-8',
            episodeNumberLabel: '8',
            episodeTitle: 'Another Episode',
          ),
        ]);
      },
    );

    test(
      'resolves playback from the product-facing episode playback repository',
      () async {
        final playbackRepository = _FakeEpisodePlaybackRepository(
          variants: const [
            EpisodePlaybackVariant(
              sourceUri: 'https://cdn.example.com/episode-7-1080.m3u8',
              qualityLabel: '1080p',
            ),
            EpisodePlaybackVariant(
              sourceUri: 'https://cdn.example.com/episode-7-720.m3u8',
              qualityLabel: '720p',
            ),
          ],
        );
        final resolver = PlayerPlaybackResolver(
          episodePlaybackRepository: playbackRepository,
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

        expect(playbackRepository.requestedSeriesIds, ['series-501']);
        expect(source.qualityLabel, '1080p');
        expect(source.streamUri, 'https://cdn.example.com/episode-7-1080.m3u8');
        expect(
          source.variants.map((variant) => variant.qualityLabel).toList(),
          ['1080p', '720p'],
        );
      },
    );

    test(
      'rewraps repository lookup errors into player resolution errors',
      () async {
        final resolver = PlayerPlaybackResolver(
          episodePlaybackRepository: _ThrowingEpisodePlaybackRepository(
            const EpisodePlaybackLookupException(
              'No supported remote playback variants are available for Episode 1.',
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
      },
    );
  });
}

class _FakeEpisodePlaybackRepository implements EpisodePlaybackRepository {
  _FakeEpisodePlaybackRepository({required this.variants});

  final List<EpisodePlaybackVariant> variants;
  final List<String> requestedSeriesIds = [];
  final List<EpisodeSelector> requestedSelectors = [];

  @override
  Future<List<EpisodePlaybackVariant>> getRemotePlaybackVariants({
    required String seriesId,
    required EpisodeSelector episodeSelector,
  }) async {
    requestedSeriesIds.add(seriesId);
    requestedSelectors.add(episodeSelector);
    return variants;
  }
}

class _ThrowingEpisodePlaybackRepository implements EpisodePlaybackRepository {
  const _ThrowingEpisodePlaybackRepository(this.error);

  final EpisodePlaybackLookupException error;

  @override
  Future<List<EpisodePlaybackVariant>> getRemotePlaybackVariants({
    required String seriesId,
    required EpisodeSelector episodeSelector,
  }) async {
    throw error;
  }
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
    String? seriesTitle,
    String? episodeNumberLabel,
    String? episodeTitle,
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
