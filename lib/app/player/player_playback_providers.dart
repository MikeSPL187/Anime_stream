import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/adapters/anilibria/anilibria_remote_data_source.dart';
import '../../data/dto/anilibria/anilibria_episode_dto.dart';
import '../../domain/models/download_entry.dart';
import '../../domain/repositories/downloads_repository.dart';
import '../../features/player/player_screen_context.dart';
import '../di/downloads_repository_provider.dart';
import '../di/series_repository_provider.dart';
import 'player_playback_source.dart';

final playerPlaybackResolverProvider = Provider<PlayerPlaybackResolver>((ref) {
  return PlayerPlaybackResolver(
    remoteDataSource: ref.watch(anilibriaRemoteDataSourceProvider),
    downloadsRepository: ref.watch(downloadsRepositoryProvider),
    dio: ref.watch(anilibriaDioProvider),
  );
});

final playerPlaybackSourceProvider = FutureProvider.autoDispose
    .family<PlayerPlaybackSource, PlayerScreenContext>((ref, sessionContext) {
      final resolver = ref.watch(playerPlaybackResolverProvider);
      return resolver.resolve(sessionContext);
    });

class PlayerPlaybackResolver {
  PlayerPlaybackResolver({
    required AnilibriaRemoteDataSource remoteDataSource,
    required DownloadsRepository downloadsRepository,
    Dio? dio,
  }) : _remoteDataSource = remoteDataSource,
       _downloadsRepository = downloadsRepository,
       _dio = dio;

  static const _remotePlaybackPreflightTimeout = Duration(seconds: 3);

  final AnilibriaRemoteDataSource _remoteDataSource;
  final DownloadsRepository _downloadsRepository;
  final Dio? _dio;

  Future<PlayerPlaybackSource> resolve(PlayerScreenContext context) async {
    final localDownload = await _downloadsRepository.getPlayableDownload(
      seriesId: context.seriesId,
      episodeId: context.episodeId,
    );
    if (localDownload != null) {
      final localAssetUri = localDownload.localAssetUri;
      if (localAssetUri != null && localAssetUri.trim().isNotEmpty) {
        return PlayerPlaybackSource(
          variants: [
            PlayerPlaybackVariant(
              sourceUri: localAssetUri,
              qualityLabel: '${localDownload.selectedQuality} offline',
              kind: _mapDownloadSourceKind(localDownload.sourceKind),
            ),
          ],
        );
      }
    }

    try {
      final release = await _remoteDataSource.fetchReleaseDetails(
        context.seriesId,
      );
      final episode = _findEpisode(release.episodes, context);
      if (episode == null) {
        throw PlayerPlaybackResolutionException(
          'Episode ${context.episodeDisplayLabel} could not be resolved for playback.',
        );
      }

      final remoteVariants = _buildRemoteVariants(episode);
      if (remoteVariants.isEmpty) {
        throw PlayerPlaybackResolutionException(
          'No supported remote playback variants are available for ${context.episodeDisplayLabel}.',
        );
      }

      final orderedVariants = await _preflightRemoteVariants(remoteVariants);
      return PlayerPlaybackSource(variants: orderedVariants);
    } on DioException catch (error) {
      throw PlayerPlaybackResolutionException(
        'Failed to load release data for playback.'
        '${error.response?.statusCode == null ? '' : ' HTTP ${error.response!.statusCode}.'}',
      );
    } on FormatException catch (error) {
      throw PlayerPlaybackResolutionException(
        'Release data for playback could not be parsed: ${error.message}',
      );
    }
  }

  PlayerPlaybackSourceKind _mapDownloadSourceKind(
    DownloadSourceKind sourceKind,
  ) {
    return switch (sourceKind) {
      DownloadSourceKind.localFile => PlayerPlaybackSourceKind.localFile,
      DownloadSourceKind.localHlsManifest =>
        PlayerPlaybackSourceKind.localHlsManifest,
    };
  }

  AnilibriaEpisodeDto? _findEpisode(
    List<AnilibriaEpisodeDto> episodes,
    PlayerScreenContext context,
  ) {
    if (episodes.isEmpty) {
      return null;
    }

    for (final episode in episodes) {
      if (episode.id == context.episodeId) {
        return episode;
      }
    }

    final selectedNumberLabel = context.episodeNumberLabel.trim();
    for (final episode in episodes) {
      final episodeNumberLabel = episode.numberLabel?.trim();
      if (episodeNumberLabel == selectedNumberLabel) {
        return episode;
      }
    }

    final selectedOrdinal = context.episodeOrdinal;
    if (selectedOrdinal != null) {
      for (final episode in episodes) {
        final episodeOrdinal = num.tryParse(episode.numberLabel?.trim() ?? '');
        if (episodeOrdinal == selectedOrdinal) {
          return episode;
        }
      }
    }

    for (final episode in episodes) {
      if (episode.title == context.episodeTitle) {
        return episode;
      }
    }

    return null;
  }

  List<PlayerPlaybackVariant> _buildRemoteVariants(
    AnilibriaEpisodeDto episode,
  ) {
    const streamCandidates = [
      ('1080p', 'hls1080Url'),
      ('720p', 'hls720Url'),
      ('480p', 'hls480Url'),
    ];

    final variants = <PlayerPlaybackVariant>[];
    for (final (qualityLabel, key) in streamCandidates) {
      final streamUri = switch (key) {
        'hls1080Url' => episode.hls1080Url,
        'hls720Url' => episode.hls720Url,
        'hls480Url' => episode.hls480Url,
        _ => null,
      };

      final trimmedStreamUri = streamUri?.trim();
      if (trimmedStreamUri == null || trimmedStreamUri.isEmpty) {
        continue;
      }

      variants.add(
        PlayerPlaybackVariant(
          sourceUri: trimmedStreamUri,
          qualityLabel: qualityLabel,
          kind: PlayerPlaybackSourceKind.remoteHls,
        ),
      );
    }

    return variants;
  }

  Future<List<PlayerPlaybackVariant>> _preflightRemoteVariants(
    List<PlayerPlaybackVariant> variants,
  ) async {
    if (_dio == null) {
      return variants;
    }

    final successfulVariants = <PlayerPlaybackVariant>[];
    for (final variant in variants) {
      if (variant.kind != PlayerPlaybackSourceKind.remoteHls) {
        continue;
      }

      final preflightSucceeded = await _preflightRemoteVariant(variant);
      if (preflightSucceeded) {
        successfulVariants.add(variant);
      }
    }

    if (successfulVariants.isNotEmpty) {
      return successfulVariants;
    }

    return variants;
  }

  Future<bool> _preflightRemoteVariant(PlayerPlaybackVariant variant) async {
    try {
      final response = await _dio!.getUri<String>(
        Uri.parse(variant.sourceUri),
        options: Options(
          responseType: ResponseType.plain,
          sendTimeout: _remotePlaybackPreflightTimeout,
          receiveTimeout: _remotePlaybackPreflightTimeout,
        ),
      );
      final body = response.data;
      return body != null && body.trim().isNotEmpty;
    } on DioException {
      return false;
    } on FormatException {
      return false;
    }
  }
}

class PlayerPlaybackResolutionException implements Exception {
  const PlayerPlaybackResolutionException(this.message);

  final String message;

  @override
  String toString() => message;
}
