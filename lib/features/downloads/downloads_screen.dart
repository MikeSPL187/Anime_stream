import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/downloads/downloads_providers.dart';
import '../../app/router/app_router.dart';
import '../../app/series/series_providers.dart';
import '../../domain/models/download_entry.dart';
import '../player/player_screen_context.dart';

class DownloadsScreen extends ConsumerWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final downloads = ref.watch(downloadsListProvider);

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
      body: downloads.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _DownloadsState(
          icon: Icons.error_outline_rounded,
          title: 'Downloads unavailable',
          message: 'Offline downloads could not be loaded right now.\n$error',
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
              .where(
                (e) =>
                    e.status == DownloadStatus.downloading ||
                    e.status == DownloadStatus.queued ||
                    e.status == DownloadStatus.paused,
              )
              .toList(growable: false);
          final failed = entries
              .where((e) => e.status == DownloadStatus.failed)
              .toList(growable: false);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              _SummaryStrip(
                totalCount: entries.length,
                offlineCount: offlineReady.length,
                activeCount: active.length,
                failedCount: failed.length,
              ),
              const SizedBox(height: 20),
              if (offlineReady.isNotEmpty) ...[
                _DownloadsSection(
                  title: 'Available offline',
                  subtitle: 'Ready to open directly in the player.',
                  entries: offlineReady,
                ),
                const SizedBox(height: 28),
              ],
              if (active.isNotEmpty) ...[
                _DownloadsSection(
                  title: 'Active downloads',
                  subtitle: 'Queued, downloading, and paused transfers.',
                  entries: active,
                ),
                const SizedBox(height: 28),
              ],
              if (failed.isNotEmpty)
                _DownloadsSection(
                  title: 'Needs attention',
                  subtitle: 'Retry or remove failed offline entries.',
                  entries: failed,
                ),
            ],
          );
        },
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
  });

  final int totalCount;
  final int offlineCount;
  final int activeCount;
  final int failedCount;

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
        _SurfaceBlock(
          child: Column(
            children: [
              for (var index = 0; index < entries.length; index++) ...[
                if (index > 0) const Divider(height: 20),
                _DownloadRow(entry: entries[index]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _DownloadRow extends ConsumerWidget {
  const _DownloadRow({required this.entry});

  final DownloadEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailsAsync = ref.watch(seriesDetailsProvider(entry.seriesId));
    final actionState = ref.watch(
      episodeDownloadActionControllerProvider(
        EpisodeDownloadKey(
          seriesId: entry.seriesId,
          episodeId: entry.episodeId,
        ),
      ),
    );

    return detailsAsync.when(
      loading: () =>
          _DownloadRowFallback(entry: entry, isBusy: actionState.isLoading),
      error: (error, stackTrace) =>
          _DownloadRowFallback(entry: entry, isBusy: actionState.isLoading),
      data: (details) {
        final episode = _episodeForEntry(details.episodes, entry.episodeId);
        final episodeLabel = episode == null
            ? 'Episode ${entry.episodeId}'
            : 'Episode ${episode.numberLabel}';
        final episodeTitle = episode == null || episode.title.trim().isEmpty
            ? episodeLabel
            : episode.title;
        final playerContext = PlayerScreenContext(
          seriesId: details.series.id,
          seriesTitle: details.series.title,
          episodeId: entry.episodeId,
          episodeNumberLabel: episode?.numberLabel ?? entry.episodeId,
          episodeTitle: episodeTitle,
        );

        return _DownloadRowScaffold(
          entry: entry,
          isBusy: actionState.isLoading,
          seriesTitle: details.series.title,
          posterUrl: details.series.posterImageUrl,
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

  EpisodeSummary? _episodeForEntry(List<dynamic> episodes, String episodeId) {
    for (final episode in episodes) {
      if (episode.id == episodeId) {
        return EpisodeSummary(
          numberLabel: episode.numberLabel,
          title: episode.title,
        );
      }
    }
    return null;
  }
}

class EpisodeSummary {
  const EpisodeSummary({required this.numberLabel, required this.title});

  final String numberLabel;
  final String title;
}

class _DownloadRowFallback extends StatelessWidget {
  const _DownloadRowFallback({required this.entry, required this.isBusy});

  final DownloadEntry entry;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return _DownloadRowScaffold(
      entry: entry,
      isBusy: isBusy,
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
    );
  }
}

class _DownloadRowScaffold extends ConsumerWidget {
  const _DownloadRowScaffold({
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

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Poster(imageUrl: posterUrl, label: seriesTitle),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(seriesTitle, style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text(
                '$episodeLabel • ${entry.selectedQuality} • ${_downloadStatusLabel(entry)}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                episodeTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if ((entry.lastError ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  entry.lastError!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 10),
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
                      entry.status == DownloadStatus.paused)
                    FilledButton.tonalIcon(
                      onPressed: isBusy ? null : () => handleRetry(),
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                    ),
                  TextButton(
                    onPressed: isBusy ? null : onOpenSeries,
                    child: const Text('Open series'),
                  ),
                  TextButton(
                    onPressed: isBusy ? null : () => handleRemove(),
                    child: const Text('Remove'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
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

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
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
    );
  }
}

class _SurfaceBlock extends StatelessWidget {
  const _SurfaceBlock({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}

class _Poster extends StatelessWidget {
  const _Poster({required this.imageUrl, required this.label});

  final String? imageUrl;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trimmedUrl = imageUrl?.trim();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 72,
        child: AspectRatio(
          aspectRatio: 2 / 3,
          child: trimmedUrl == null || trimmedUrl.isEmpty
              ? _PosterFallback(label: label)
              : DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                  ),
                  child: Image.network(
                    trimmedUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          _PosterFallback(label: label),
                          const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ],
                      );
                    },
                    errorBuilder: (context, error, stackTrace) =>
                        _PosterFallback(label: label),
                  ),
                ),
        ),
      ),
    );
  }
}

class _PosterFallback extends StatelessWidget {
  const _PosterFallback({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.surfaceContainerHighest,
            theme.colorScheme.surfaceContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.movie_creation_outlined,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
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

String _downloadStatusLabel(DownloadEntry entry) {
  return switch (entry.status) {
    DownloadStatus.completed when entry.isPlayableOffline =>
      'Available offline',
    DownloadStatus.completed => 'Downloaded',
    DownloadStatus.downloading => 'Downloading',
    DownloadStatus.queued => 'Queued',
    DownloadStatus.paused => 'Paused',
    DownloadStatus.failed => 'Failed',
  };
}
