import 'package:flutter_test/flutter_test.dart';

import 'package:anime_stream_app/app/player/player_playback_providers.dart';
import 'package:anime_stream_app/app/player/player_playback_source.dart';
import 'package:anime_stream_app/data/adapters/anilibria/anilibria_remote_data_source.dart';
import 'package:anime_stream_app/data/dto/anilibria/anilibria_episode_dto.dart';
import 'package:anime_stream_app/data/dto/anilibria/anilibria_release_dto.dart';
import 'package:anime_stream_app/data/dto/anilibria/anilibria_release_page_dto.dart';
import 'package:anime_stream_app/domain/models/download_entry.dart';
import 'package:anime_stream_app/domain/repositories/downloads_repository.dart';
import 'package:anime_stream_app/features/player/player_screen_context.dart';

void main() {
  group('PlayerPlaybackResolver', () {
    test('prefers completed offline asset before remote AniLibria HLS resolution', () async {
      final resolver = PlayerPlaybackResolver(
        remoteDataSource: _FailingRemoteDataSource(),
        downloadsRepository: _FakeDownloadsRepository(
          playableEntry: const DownloadEntry(
            id: 'series-4::episode-2::1080p',
            seriesId: 'series-4',
            episodeId: 'episode-2',
            selectedQuality: '1080p',
            status: DownloadStatus.completed,
            localAssetUri: 'file:///downloads/series-4/episode-2/1080p/index.m3u8',
            sourceKind: DownloadSourceKind.localHlsManifest,
          ),
        ),
      );

      final source = await resolver.resolve(
        const PlayerScreenContext(
          seriesId: 'series-4',
          seriesTitle: 'Pluto',
          episodeId: 'episode-2',
          episodeNumberLabel: '2',
          episodeTitle: 'Assassination Order',
        ),
      );

      expect(source.sourceUri, 'file:///downloads/series-4/episode-2/1080p/index.m3u8');
      expect(source.kind, PlayerPlaybackSourceKind.localHlsManifest);
      expect(source.isOffline, isTrue);
    });

    test('falls back to remote HLS resolution when no local asset exists', () async {
      final resolver = PlayerPlaybackResolver(
        remoteDataSource: _FakeRemoteDataSource(),
        downloadsRepository: const _FakeDownloadsRepository(playableEntry: null),
      );

      final source = await resolver.resolve(
        const PlayerScreenContext(
          seriesId: 'series-5',
          seriesTitle: 'Frieren',
          episodeId: 'episode-3',
          episodeNumberLabel: '3',
          episodeTitle: 'Killing Magic',
        ),
      );

      expect(source.sourceUri, 'https://cdn.example.com/frieren/episode-3.m3u8');
      expect(source.kind, PlayerPlaybackSourceKind.remoteHls);
      expect(source.isOffline, isFalse);
    });
  });
}

class _FakeDownloadsRepository implements DownloadsRepository {
  const _FakeDownloadsRepository({required this.playableEntry});

  final DownloadEntry? playableEntry;

  @override
  Future<List<DownloadEntry>> getDownloads() async =>
      playableEntry == null ? const [] : [playableEntry!];

  @override
  Future<DownloadEntry?> getPlayableDownload({
    required String seriesId,
    required String episodeId,
  }) async {
    if (playableEntry == null) {
      return null;
    }
    if (playableEntry!.seriesId != seriesId ||
        playableEntry!.episodeId != episodeId) {
      return null;
    }
    return playableEntry;
  }

  @override
  Future<void> pauseDownload(String downloadId) async {}

  @override
  Future<void> queueEpisodeDownload({
    required String seriesId,
    required String episodeId,
    String selectedQuality = '1080p',
  }) async {}

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

class _FailingRemoteDataSource implements AnilibriaRemoteDataSource {
  @override
  Future<List<AnilibriaReleaseDto>> fetchFeaturedReleases({int limit = 20}) {
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
  Future<AnilibriaReleaseDto> fetchReleaseDetails(String releaseId) {
    throw StateError('Remote resolution should not be used when offline asset exists.');
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

class _FakeRemoteDataSource implements AnilibriaRemoteDataSource {
  @override
  Future<List<AnilibriaReleaseDto>> fetchFeaturedReleases({int limit = 20}) {
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
  Future<AnilibriaReleaseDto> fetchReleaseDetails(String releaseId) async {
    return const AnilibriaReleaseDto(
      id: 'series-5',
      episodes: [
        AnilibriaEpisodeDto(
          id: 'episode-3',
          releaseId: 'series-5',
          ordinal: 3,
          numberLabel: '3',
          title: 'Killing Magic',
          hls720Url: 'https://cdn.example.com/frieren/episode-3.m3u8',
        ),
      ],
    );
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
