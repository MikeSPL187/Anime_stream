import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:anime_stream_app/data/adapters/anilibria/anilibria_remote_data_source.dart';
import 'package:anime_stream_app/data/dto/anilibria/anilibria_episode_dto.dart';
import 'package:anime_stream_app/data/dto/anilibria/anilibria_release_dto.dart';
import 'package:anime_stream_app/data/dto/anilibria/anilibria_release_page_dto.dart';
import 'package:anime_stream_app/data/repositories/anilibria/anilibria_episode_playback_repository.dart';
import 'package:anime_stream_app/domain/models/episode_selector.dart';
import 'package:anime_stream_app/domain/repositories/episode_playback_repository.dart';

void main() {
  group('AnilibriaEpisodePlaybackRepository', () {
    test('maps remote playback variants from release details', () async {
      final remoteDataSource = _FakeRemoteDataSource(
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
      final repository = AnilibriaEpisodePlaybackRepository(
        remoteDataSource: remoteDataSource,
      );

      final variants = await repository.getRemotePlaybackVariants(
        seriesId: 'series-501',
        episodeSelector: const EpisodeSelector(
          episodeId: 'episode-7',
          episodeNumberLabel: '7',
          episodeTitle: 'The Real Thing',
        ),
      );

      expect(remoteDataSource.requestedReleaseIds, ['series-501']);
      expect(variants, hasLength(2));
      expect(variants.first.qualityLabel, '1080p');
      expect(
        variants.first.sourceUri,
        'https://cdn.example.com/episode-7-1080.m3u8',
      );
      expect(variants.last.qualityLabel, '720p');
    });

    test('matches episode by number label when ids differ', () async {
      final repository = AnilibriaEpisodePlaybackRepository(
        remoteDataSource: _FakeRemoteDataSource(
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
      );

      final variants = await repository.getRemotePlaybackVariants(
        seriesId: 'series-42',
        episodeSelector: const EpisodeSelector(
          episodeId: 'ui-episode-id',
          episodeNumberLabel: '2.5',
          episodeTitle: 'Untrusted UI Title',
        ),
      );

      expect(variants, hasLength(1));
      expect(variants.single.qualityLabel, '720p');
      expect(
        variants.single.sourceUri,
        'https://cdn.example.com/bonus-720.m3u8',
      );
    });

    test('throws when the matched episode has no supported HLS stream', () async {
      final repository = AnilibriaEpisodePlaybackRepository(
        remoteDataSource: _FakeRemoteDataSource(
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
      );

      await expectLater(
        () => repository.getRemotePlaybackVariants(
          seriesId: 'series-12',
          episodeSelector: const EpisodeSelector(
            episodeId: 'episode-1',
            episodeNumberLabel: '1',
            episodeTitle: 'Pilot',
          ),
        ),
        throwsA(
          isA<EpisodePlaybackLookupException>().having(
            (error) => error.message,
            'message',
            'No supported remote playback variants are available for Episode 1.',
          ),
        ),
      );
    });

    test('maps Dio failures into playback lookup errors', () async {
      final repository = AnilibriaEpisodePlaybackRepository(
        remoteDataSource: _ThrowingRemoteDataSource(
          DioException(
            requestOptions: RequestOptions(path: '/anime/releases/404'),
            response: Response<dynamic>(
              requestOptions: RequestOptions(path: '/anime/releases/404'),
              statusCode: 404,
            ),
            type: DioExceptionType.badResponse,
          ),
        ),
      );

      await expectLater(
        () => repository.getRemotePlaybackVariants(
          seriesId: '404',
          episodeSelector: const EpisodeSelector(
            episodeId: 'episode-1',
            episodeNumberLabel: '1',
            episodeTitle: 'Pilot',
          ),
        ),
        throwsA(
          isA<EpisodePlaybackLookupException>().having(
            (error) => error.message,
            'message',
            'Failed to load release data for playback. HTTP 404.',
          ),
        ),
      );
    });
  });
}

class _FakeRemoteDataSource implements AnilibriaRemoteDataSource {
  _FakeRemoteDataSource({required this.release});

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
  Future<AnilibriaReleasePageDto> fetchCatalogPage({
    int page = 1,
    int limit = 20,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<List<AnilibriaReleaseDto>> fetchPopularReleases({int limit = 20}) {
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

class _ThrowingRemoteDataSource implements AnilibriaRemoteDataSource {
  const _ThrowingRemoteDataSource(this.error);

  final Object error;

  @override
  Future<AnilibriaReleaseDto> fetchReleaseDetails(String releaseId) {
    throw error;
  }

  @override
  Future<List<AnilibriaReleaseDto>> fetchLatestReleases({int limit = 20}) {
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
  Future<List<AnilibriaReleaseDto>> fetchPopularReleases({int limit = 20}) {
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
