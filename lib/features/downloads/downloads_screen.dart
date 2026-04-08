import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/downloads/downloads_providers.dart';
import '../../app/router/app_router.dart';
import '../../app/series/series_providers.dart';
import '../../domain/models/download_entry.dart';
import '../../shared/widgets/anime_cached_artwork.dart';
import '../player/player_screen_context.dart';

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloads = ref.watch(downloadsListProvider);
    Future<void> refreshDownloads() async {
      ref.invalidate(downloadsListProvider);
      try {
        await ref.read(downloadsListProvider.future);
      } catch (_) {
        return;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloads'),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutePaths.search),
            icon: const Icon(Icons.search_rounded),
            tooltip: 'Search',
          ),
          IconButton(
            onPressed: () => context.push(AppRoutePaths.settings),
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refreshDownloads,
        child: downloads.when(
          loading: () => const _DownloadsState(
            icon: Icons.download_rounded,
            title: 'Loading downloads',
            message: 'Offline library is being prepared.',
          ),
          error: (error, stackTrace) => _DownloadsState(
            icon: Icons.error_outline_rounded,
            title: 'Downloads unavailable',
            message: 'Offline downloads could not be loaded right now.\n$error',
            action: FilledButton.icon(
              onPressed: refreshDownloads,
              icon: Icon(Icons.refresh_rounded),
              label: Text('Retry'),
            ),
          ),
          data: (entries) {
            if (entries.isEmpty) {
              return _DownloadsState(
                icon: Icons.download_outlined,
                title: 'No downloads yet',
                message:
                    'Download episodes from a series page to build an offline library.',
                action: TextButton.icon(
                  onPressed: () => context.go(AppRoutePaths.myLists),
                  icon: const Icon(Icons.bookmarks_outlined),
                  label: const Text('Back to My Lists'),
                ),
              );
            }

            final offlineReady = entries
                .where((e) => e.isPlayableOffline)
                .toList(growable: false);
            final active = entries
                .where((e) => e.hasActiveTransfer)
                .toList(growable: false);
            final failed = entries
                .where((e) => e.status == DownloadStatus.failed)
                .toList(growable: false);
            final integrityFailures = failed
                .where((e) => e.requiresOfflineRestore)
                .length;

            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              children: [
                _SummaryStrip(
                  totalCount: entries.length,
                  offlineCount: offlineReady.length,
                  activeCount: active.length,
                  failedCount: failed.length,
                  integrityFailureCount: integrityFailures,
                ),
                const SizedBox(height: 22),
                if (offlineReady.isNotEmpty) ...[
                  _DownloadsSection(
                    title: 'Available offline',
                    subtitle:
                        'Verified on this device and ready for offline playback.',
                    entries: offlineReady,
                  ),
                  const SizedBox(height: 26),
                ],
                if (active.isNotEmpty) ...[
                  _DownloadsSection(
                    title: 'Active downloads',
                    subtitle:
                        'Transfers currently being packaged for offline playback.',
                    entries: active,
                  ),
                  const SizedBox(height: 26),
                ],
                if (failed.isNotEmpty)
                  _DownloadsSection(
                    title: 'Needs attention',
                    subtitle: integrityFailures > 0
                        ? 'Retry failed transfers or restore missing offline copies.'
                        : 'Retry or remove failed offline entries.',
                    entries: failed,
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({
    required this.totalCount,
    required this.offlineCount,
    required this.activeCount,
    required this.failedCount,
    required this.integrityFailureCount,
  });

  final int totalCount;
  final int offlineCount;
  final int activeCount;
  final int failedCount;
  final int integrityFailureCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Badge(label: '$totalCount total', color: colorScheme.primary),
        _Badge(label: '$offlineCount offline', color: colorScheme.secondary),
        _Badge(label: '$activeCount active', color: colorScheme.tertiary),
        if (failedCount > 0)
          _Badge(label: '$failedCount failed', color: colorScheme.error),
        if (integrityFailureCount > 0)
          _Badge(
            label: '$integrityFailureCount need restore',
            color: colorScheme.error,
          ),
      ],
    );
  }
}

class _DownloadsSection extends StatelessWidget {
  const _DownloadsSection({
    required this.title,
    required this.subtitle,
    required this.entries,
  });

  final String title;
  final String subtitle;
  final List<DownloadEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: [
            for (var index = 0; index < entries.length; index++) ...[
              if (index > 0) const SizedBox(height: 14),
              _DownloadCard(entry: entries[index]),
            ],
          ],
        ),
      ],
    );
  }
}

class _DownloadCard extends ConsumerWidget {
  const _DownloadCard({required this.entry});

  final DownloadEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contentAsync = ref.watch(seriesContentProvider(entry.seriesId));
    final actionState = ref.watch(
      episodeDownloadActionControllerProvider(
        EpisodeDownloadKey(
          seriesId: entry.seriesId,
          episodeId: entry.episodeId,
        ),
      ),
    );

    return contentAsync.when(
      loading: () => _DownloadCardScaffold(
        entry: entry,
        isBusy: actionState.isLoading,
        seriesTitle: entry.seriesId,
        posterUrl: null,
        episodeLabel: 'Episode ${entry.episodeId}',
        episodeTitle: entry.selectedQuality,
        onOpenSeries: () =>
            context.push(AppRoutePaths.seriesDetails(entry.seriesId)),
        onPlayOffline: entry.isPlayableOffline
            ? () => context.push(
                AppRoutePaths.player,
                extra: PlayerScreenContext(
                  seriesId: entry.seriesId,
                  seriesTitle: entry.seriesId,
                  episodeId: entry.episodeId,
                  episodeNumberLabel: entry.episodeId,
                  episodeTitle: 'Episode ${entry.episodeId}',
                ),
              )
            : null,
      ),
      error: (error, stackTrace) => _DownloadCardScaffold(
        entry: entry,
        isBusy: actionState.isLoading,
        seriesTitle: entry.seriesId,
        posterUrl: null,
        episodeLabel: 'Episode ${entry.episodeId}',
        episodeTitle: entry.selectedQuality,
        onOpenSeries: () =>
            context.push(AppRoutePaths.seriesDetails(entry.seriesId)),
        onPlayOffline: entry.isPlayableOffline
            ? () => context.push(
                AppRoutePaths.player,
                extra: PlayerScreenContext(
                  seriesId: entry.seriesId,
                  seriesTitle: entry.seriesId,
                  episodeId: entry.episodeId,
                  episodeNumberLabel: entry.episodeId,
                  episodeTitle: 'Episode ${entry.episodeId}',
                ),
              )
            : null,
      ),
      data: (content) {
        final episode = content.episodeById(entry.episodeId);
        final episodeLabel = episode == null
            ? 'Episode ${entry.episodeId}'
            : 'Episode ${episode.numberLabel}';
        final episodeTitle = episode == null || episode.title.trim().isEmpty
            ? episodeLabel
            : episode.title;
        final playerContext = PlayerScreenContext(
          seriesId: content.series.id,
          seriesTitle: content.series.title,
          episodeId: entry.episodeId,
          episodeNumberLabel: episode?.numberLabel ?? entry.episodeId,
          episodeTitle: episodeTitle,
        );

        return _DownloadCardScaffold(
          entry: entry,
          isBusy: actionState.isLoading,
          seriesTitle: content.series.title,
          posterUrl: content.series.posterImageUrl,
          episodeLabel: episodeLabel,
          episodeTitle: episodeTitle,
          onOpenSeries: () =>
              context.push(AppRoutePaths.seriesDetails(entry.seriesId)),
          onPlayOffline: entry.isPlayableOffline
              ? () => context.push(AppRoutePaths.player, extra: playerContext)
              : null,
        );
      },
    );
  }
}

class _DownloadCardScaffold extends ConsumerWidget {
  const _DownloadCardScaffold({
    required this.entry,
    required this.isBusy,
    required this.seriesTitle,
    required this.posterUrl,
    required this.episodeLabel,
    required this.episodeTitle,
    required this.onOpenSeries,
    required this.onPlayOffline,
  });

  final DownloadEntry entry;
  final bool isBusy;
  final String seriesTitle;
  final String? posterUrl;
  final String episodeLabel;
  final String episodeTitle;
  final VoidCallback onOpenSeries;
  final VoidCallback? onPlayOffline;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final controller = ref.read(
      episodeDownloadActionControllerProvider(
        EpisodeDownloadKey(
          seriesId: entry.seriesId,
          episodeId: entry.episodeId,
        ),
      ).notifier,
    );

    Future<void> handleRemove() async {
      await controller.removeDownload(entry.id);
    }

    Future<void> handleRetry() async {
      await controller.startDownload(selectedQuality: entry.selectedQuality);
    }

    final integrityFailure = entry.requiresOfflineRestore;
    final restartRequired = _downloadNeedsRestart(entry);
    final pillLabel = switch (entry.status) {
      DownloadStatus.completed when entry.isPlayableOffline => 'Offline ready',
      DownloadStatus.completed => 'Downloaded',
      DownloadStatus.downloading => 'Downloading',
      DownloadStatus.queued || DownloadStatus.paused => 'Restart needed',
      DownloadStatus.failed when integrityFailure => 'Restore needed',
      DownloadStatus.failed when restartRequired => 'Restart needed',
      DownloadStatus.failed => 'Retry needed',
    };
    final pillIcon = switch (entry.status) {
      DownloadStatus.completed when entry.isPlayableOffline =>
        Icons.offline_pin_rounded,
      DownloadStatus.completed => Icons.check_circle_outline_rounded,
      DownloadStatus.downloading => Icons.download_rounded,
      DownloadStatus.queued ||
      DownloadStatus.paused => Icons.restart_alt_rounded,
      DownloadStatus.failed when integrityFailure =>
        Icons.warning_amber_rounded,
      DownloadStatus.failed when restartRequired => Icons.restart_alt_rounded,
      DownloadStatus.failed => Icons.error_outline_rounded,
    };

    final primaryRecoveryLabel = integrityFailure ? 'Download again' : 'Retry';
    final primaryRecoveryIcon = integrityFailure
        ? Icons.download_rounded
        : Icons.refresh_rounded;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPlayOffline ?? onOpenSeries,
        borderRadius: BorderRadius.circular(20),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 244,
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimeCachedArtwork(
                  imageUrl: posterUrl,
                  label: seriesTitle,
                  icon: Icons.movie_creation_outlined,
                  alignment: Alignment.topCenter,
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.04),
                          Colors.black.withValues(alpha: 0.14),
                          Colors.black.withValues(alpha: 0.92),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: _OverlayPill(label: pillLabel, icon: pillIcon),
                ),
                if (isBusy)
                  Positioned(
                    right: 12,
                    top: 12,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.46),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        seriesTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          height: 1.05,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        episodeLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: Colors.white.withValues(alpha: 0.84),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        episodeTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${entry.selectedQuality} • ${_downloadStatusLabel(entry)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.78),
                        ),
                      ),
                      if ((entry.lastError ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          _friendlyDownloadError(entry),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (onPlayOffline != null)
                            FilledButton.tonalIcon(
                              onPressed: isBusy ? null : onPlayOffline,
                              icon: const Icon(Icons.offline_pin_rounded),
                              label: const Text('Play offline'),
                            )
                          else if (entry.status == DownloadStatus.failed ||
                              entry.status == DownloadStatus.queued ||
                              entry.status == DownloadStatus.paused)
                            FilledButton.tonalIcon(
                              onPressed: isBusy ? null : () => handleRetry(),
                              icon: Icon(primaryRecoveryIcon),
                              label: Text(primaryRecoveryLabel),
                            ),
                          TextButton(
                            onPressed: isBusy ? null : onOpenSeries,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Open series'),
                          ),
                          TextButton(
                            onPressed: isBusy ? null : () => handleRemove(),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Remove'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DownloadsState extends StatelessWidget {
  const _DownloadsState({
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 420),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 40, color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    title,
                    style: theme.textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (action != null) ...[const SizedBox(height: 16), action!],
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
      ),
    );
  }
}

class _OverlayPill extends StatelessWidget {
  const _OverlayPill({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _friendlyDownloadError(DownloadEntry entry) {
  final lastError = entry.lastError ?? '';
  if (entry.failureKind == DownloadFailureKind.transferInterrupted) {
    return 'Download was interrupted before completion. Start it again to save this episode offline.';
  }
  if (entry.failureKind == DownloadFailureKind.transferFailed) {
    return 'Download did not complete. Retry it to save this episode offline.';
  }

  if (!entry.requiresOfflineRestore) {
    return lastError;
  }

  return switch (entry.failureKind) {
    DownloadFailureKind.offlineAssetMissing ||
    DownloadFailureKind.offlinePackageMissing =>
      'Offline copy is missing on this device. Download it again to restore playback.',
    DownloadFailureKind.offlineAssetInvalid ||
    DownloadFailureKind.offlineAssetCorrupted ||
    DownloadFailureKind.offlinePackageCorrupted =>
      'Offline package is damaged and needs to be downloaded again.',
    _ => lastError,
  };
}

String _downloadStatusLabel(DownloadEntry entry) {
  return switch (entry.status) {
    DownloadStatus.completed when entry.isPlayableOffline =>
      'Available offline',
    DownloadStatus.completed => 'Downloaded',
    DownloadStatus.downloading => 'Downloading',
    DownloadStatus.queued || DownloadStatus.paused => 'Restart needed',
    DownloadStatus.failed when entry.requiresOfflineRestore =>
      'Unavailable offline',
    DownloadStatus.failed when _downloadNeedsRestart(entry) => 'Restart needed',
    DownloadStatus.failed => 'Retry needed',
  };
}

bool _downloadNeedsRestart(DownloadEntry entry) {
  return entry.failureKind == DownloadFailureKind.transferInterrupted ||
      entry.status == DownloadStatus.queued ||
      entry.status == DownloadStatus.paused;
}
