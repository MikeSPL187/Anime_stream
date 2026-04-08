import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/download_entry.dart';
import '../../domain/models/episode_selector.dart';
import '../di/downloads_repository_provider.dart';
import '../di/episode_playback_repository_provider.dart';

@immutable
class EpisodeDownloadKey {
  const EpisodeDownloadKey({required this.seriesId, required this.episodeId});

  final String seriesId;
  final String episodeId;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is EpisodeDownloadKey &&
        other.seriesId == seriesId &&
        other.episodeId == episodeId;
  }

  @override
  int get hashCode => Object.hash(seriesId, episodeId);
}

@immutable
class EpisodeDownloadQualityRequest {
  const EpisodeDownloadQualityRequest({
    required this.seriesId,
    required this.episodeSelector,
  });

  final String seriesId;
  final EpisodeSelector episodeSelector;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is EpisodeDownloadQualityRequest &&
        other.seriesId == seriesId &&
        other.episodeSelector == episodeSelector;
  }

  @override
  int get hashCode => Object.hash(seriesId, episodeSelector);
}

final downloadsListProvider = FutureProvider.autoDispose<List<DownloadEntry>>((
  ref,
) async {
  return ref.watch(downloadsRepositoryProvider).getDownloads();
});

final episodeDownloadEntryProvider = FutureProvider.autoDispose
    .family<DownloadEntry?, EpisodeDownloadKey>((ref, key) async {
      final entries = await ref.watch(downloadsListProvider.future);
      final matches = entries
          .where(
            (entry) =>
                entry.seriesId == key.seriesId &&
                entry.episodeId == key.episodeId,
          )
          .toList(growable: false);

      if (matches.isEmpty) {
        return null;
      }

      matches.sort((left, right) {
        final leftTimestamp =
            left.completedAt ??
            left.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        final rightTimestamp =
            right.completedAt ??
            right.createdAt ??
            DateTime.fromMillisecondsSinceEpoch(0);
        return rightTimestamp.compareTo(leftTimestamp);
      });

      return matches.first;
    });

final episodeDownloadQualityOptionsProvider = FutureProvider.autoDispose
    .family<List<String>, EpisodeDownloadQualityRequest>((ref, request) async {
      final variants = await ref
          .watch(episodePlaybackRepositoryProvider)
          .getRemotePlaybackVariants(
            seriesId: request.seriesId,
            episodeSelector: request.episodeSelector,
          );

      final labels = <String>{};
      final orderedQualities = <String>[];
      for (final variant in variants) {
        final qualityLabel = variant.qualityLabel.trim();
        if (qualityLabel.isEmpty || !labels.add(qualityLabel)) {
          continue;
        }

        orderedQualities.add(qualityLabel);
      }

      return List.unmodifiable(orderedQualities);
    });

final episodeDownloadActionControllerProvider =
    AutoDisposeAsyncNotifierProviderFamily<
      EpisodeDownloadActionController,
      void,
      EpisodeDownloadKey
    >(EpisodeDownloadActionController.new);

class EpisodeDownloadActionController
    extends AutoDisposeFamilyAsyncNotifier<void, EpisodeDownloadKey> {
  late final EpisodeDownloadKey _key;

  @override
  Future<void> build(EpisodeDownloadKey key) async {
    _key = key;
  }

  Future<void> startDownload({
    String selectedQuality = '1080p',
    String? seriesTitle,
    String? episodeNumberLabel,
    String? episodeTitle,
  }) async {
    await _runOperation(() {
      return ref
          .read(downloadsRepositoryProvider)
          .startEpisodeDownload(
            seriesId: _key.seriesId,
            episodeId: _key.episodeId,
            selectedQuality: selectedQuality,
            seriesTitle: seriesTitle,
            episodeNumberLabel: episodeNumberLabel,
            episodeTitle: episodeTitle,
          );
    });
  }

  Future<void> removeDownload(String downloadId) async {
    await _runOperation(() {
      return ref.read(downloadsRepositoryProvider).removeDownload(downloadId);
    });
  }

  Future<void> _runOperation(Future<void> Function() operation) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await operation();
      _invalidateDownloads();
    });
  }

  void _invalidateDownloads() {
    ref.invalidate(downloadsListProvider);
    ref.invalidate(episodeDownloadEntryProvider(_key));
  }
}
