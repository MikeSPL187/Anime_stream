import 'package:flutter_test/flutter_test.dart';

import 'package:anime_stream_app/app/player/player_playback_providers.dart';
import 'package:anime_stream_app/data/adapters/anilibria/anilibria_remote_data_source.dart';
import 'package:anime_stream_app/data/dto/anilibria/anilibria_episode_dto.dart';
import 'package:anime_stream_app/data/dto/anilibria/anilibria_release_page_dto.dart';
import 'package:anime_stream_app/data/dto/anilibria/anilibria_release_dto.dart';
import 'package:anime_stream_app/features/player/player_screen_context.dart';

void main() {
  group('PlayerPlaybackResolver', () {
    test(
      'resolves playback from shared release details by episode id',
      () async {
        final remoteDataSource = _FakeAnilibriaRemoteDataSource(
          release: AnilibriaReleaseDto(
            id: 'series-501',
            episodes: const [
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
          release: AnilibriaReleaseDto(
            id: 'series-42',
            episodes: const [
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

    test(
      'throws when the matched episode has no supported HLS stream',
      () async {
        final resolver = PlayerPlaybackResolver(
          remoteDataSource: _FakeAnilibriaRemoteDataSource(
            release: AnilibriaReleaseDto(
              id: 'series-12',
              episodes: const [
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
              'No supported HLS stream is available for Episode 1.',
            ),
          ),
        );
      },
    );
  });
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
  Future<List<AnilibriaReleaseDto>> fetchFeaturedReleases({int limit = 20}) {
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
