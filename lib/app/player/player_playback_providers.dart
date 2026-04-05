import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/adapters/anilibria/anilibria_remote_data_source.dart';
import '../../data/dto/anilibria/anilibria_episode_dto.dart';
import '../../features/player/player_screen_context.dart';
import '../di/series_repository_provider.dart';
import 'player_playback_source.dart';

final playerPlaybackResolverProvider = Provider<PlayerPlaybackResolver>((ref) {
  return PlayerPlaybackResolver(
    remoteDataSource: ref.watch(anilibriaRemoteDataSourceProvider),
  );
});

final playerPlaybackSourceProvider = FutureProvider.autoDispose
    .family<PlayerPlaybackSource, PlayerScreenContext>((ref, sessionContext) {
      final resolver = ref.watch(playerPlaybackResolverProvider);
      return resolver.resolve(sessionContext);
    });

class PlayerPlaybackResolver {
  PlayerPlaybackResolver({required AnilibriaRemoteDataSource remoteDataSource})
    : _remoteDataSource = remoteDataSource;

  final AnilibriaRemoteDataSource _remoteDataSource;

  Future<PlayerPlaybackSource> resolve(PlayerScreenContext context) async {
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

      final stream = _pickPreferredStream(episode);
      if (stream == null) {
        throw PlayerPlaybackResolutionException(
          'No supported HLS stream is available for ${context.episodeDisplayLabel}.',
        );
      }

      return PlayerPlaybackSource(
        streamUri: stream.streamUri,
        qualityLabel: stream.qualityLabel,
      );
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

  _ResolvedStreamCandidate? _pickPreferredStream(AnilibriaEpisodeDto episode) {
    const streamCandidates = [
      ('1080p', 'hls1080Url'),
      ('720p', 'hls720Url'),
      ('480p', 'hls480Url'),
    ];

    for (final (qualityLabel, key) in streamCandidates) {
      final streamUri = switch (key) {
        'hls1080Url' => episode.hls1080Url,
        'hls720Url' => episode.hls720Url,
        'hls480Url' => episode.hls480Url,
        _ => null,
      };
      if (streamUri != null && streamUri.isNotEmpty) {
        return _ResolvedStreamCandidate(
          qualityLabel: qualityLabel,
          streamUri: streamUri,
        );
      }
    }

    return null;
  }
}

class PlayerPlaybackResolutionException implements Exception {
  const PlayerPlaybackResolutionException(this.message);

  final String message;

  @override
  String toString() => message;
}

@immutable
class _ResolvedStreamCandidate {
  const _ResolvedStreamCandidate({
    required this.qualityLabel,
    required this.streamUri,
  });

  final String qualityLabel;
  final String streamUri;
}
