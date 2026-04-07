import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/downloads/downloads_providers.dart';
import '../../app/history/history_providers.dart';
import '../../app/router/app_router.dart';
import '../../app/series/series_providers.dart';
import '../../app/watchlist/watchlist_providers.dart';
import '../../domain/models/download_entry.dart';
import '../../domain/models/episode.dart';
import '../../domain/models/history_entry.dart';
import '../../domain/models/watchlist_entry.dart';
import '../../shared/widgets/anime_cached_artwork.dart';

class MyListsScreen extends ConsumerWidget {
  const MyListsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchlist = ref.watch(watchlistProvider);
    final history = ref.watch(watchHistoryProvider);
    final downloads = ref.watch(downloadsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Lists'),
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
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _SummaryStrip(
            watchlistCount: watchlist.asData?.value.length,
            downloadsCount: downloads.asData?.value.length,
            historyCount: history.asData?.value.length,
          ),
          const SizedBox(height: 20),
          _WatchlistSection(watchlist: watchlist),
          const SizedBox(height: 28),
          _DownloadsSection(downloads: downloads),
          const SizedBox(height: 28),
          _HistorySection(history: history),
        ],
      ),
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({
    required this.watchlistCount,
    required this.downloadsCount,
    required this.historyCount,
  });

  final int? watchlistCount;
  final int? downloadsCount;
  final int? historyCount;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _CountBadge(
          label: watchlistCount == null
              ? 'Watchlist…'
              : '${watchlistCount!} saved',
          color: colorScheme.primary,
        ),
        _CountBadge(
          label: downloadsCount == null
              ? 'Downloads…'
              : '${downloadsCount!} offline',
          color: colorScheme.secondary,
        ),
        _CountBadge(
          label: historyCount == null ? 'History…' : '${historyCount!} watched',
          color: colorScheme.tertiary,
        ),
      ],
    );
  }
}

class _WatchlistSection extends StatelessWidget {
  const _WatchlistSection({required this.watchlist});

  final AsyncValue<List<WatchlistEntry>> watchlist;

  @override
  Widget build(BuildContext context) {
    return watchlist.when(
      loading: () => const _SectionLoading(
        title: 'Watchlist',
        message: 'Loading saved titles...',
      ),
      error: (error, stackTrace) => _SectionMessage(
        title: 'Watchlist',
        message: 'Saved titles could not be loaded.\n$error',
      ),
      data: (entries) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Watchlist',
            subtitle: 'Saved-for-later series outside active playback.',
            trailing: entries.isEmpty
                ? null
                : TextButton(
                    onPressed: () => context.push(AppRoutePaths.watchlist),
                    child: const Text('Open all'),
                  ),
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            const _SectionMessage(
              title: 'Nothing saved yet',
              message:
                  'Add titles from a series page to keep them here for later.',
            )
          else
            _SurfaceBlock(
              child: Column(
                children: [
                  for (
                    var index = 0;
                    index < entries.take(4).length;
                    index++
                  ) ...[
                    if (index > 0) const Divider(height: 20),
                    _WatchlistRow(entry: entries[index]),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DownloadsSection extends StatelessWidget {
  const _DownloadsSection({required this.downloads});

  final AsyncValue<List<DownloadEntry>> downloads;

  @override
  Widget build(BuildContext context) {
    return downloads.when(
      loading: () => const _SectionLoading(
        title: 'Downloads',
        message: 'Loading offline library...',
      ),
      error: (error, stackTrace) => _SectionMessage(
        title: 'Downloads',
        message: 'Offline entries could not be loaded.\n$error',
      ),
      data: (entries) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Downloads',
            subtitle: 'Offline-ready and active download entries.',
            trailing: entries.isEmpty
                ? null
                : TextButton(
                    onPressed: () => context.push(AppRoutePaths.downloads),
                    child: const Text('Open all'),
                  ),
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            const _SectionMessage(
              title: 'No downloads yet',
              message:
                  'Download episodes from a series page to build an offline library.',
            )
          else
            _SurfaceBlock(
              child: Column(
                children: [
                  for (
                    var index = 0;
                    index < entries.take(4).length;
                    index++
                  ) ...[
                    if (index > 0) const Divider(height: 20),
                    _DownloadPreviewRow(entry: entries[index]),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({required this.history});

  final AsyncValue<List<HistoryEntry>> history;

  @override
  Widget build(BuildContext context) {
    return history.when(
      loading: () => const _SectionLoading(
        title: 'History',
        message: 'Loading completed episodes...',
      ),
      error: (error, stackTrace) => _SectionMessage(
        title: 'History',
        message: 'Watch history could not be loaded.\n$error',
      ),
      data: (entries) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'History',
            subtitle: 'Completed episode activity separate from re-entry.',
            trailing: entries.isEmpty
                ? null
                : TextButton(
                    onPressed: () => context.push(AppRoutePaths.history),
                    child: const Text('Open all'),
                  ),
          ),
          const SizedBox(height: 12),
          if (entries.isEmpty)
            const _SectionMessage(
              title: 'Nothing completed yet',
              message:
                  'Finished episodes will appear here after watch completion.',
            )
          else
            _SurfaceBlock(
              child: Column(
                children: [
                  for (
                    var index = 0;
                    index < entries.take(4).length;
                    index++
                  ) ...[
                    if (index > 0) const Divider(height: 20),
                    _HistoryRow(entry: entries[index]),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _WatchlistRow extends StatelessWidget {
  const _WatchlistRow({required this.entry});

  final WatchlistEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push(AppRoutePaths.seriesDetails(entry.series.id)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Poster(
              imageUrl: entry.series.posterImageUrl,
              label: entry.series.title,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.series.title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Saved for later',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final episodeTitle = entry.episode.title.trim().isEmpty
        ? 'Episode ${entry.episode.numberLabel}'
        : entry.episode.title;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.push(AppRoutePaths.seriesDetails(entry.series.id)),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Poster(
              imageUrl: entry.series.posterImageUrl,
              label: entry.series.title,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.series.title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    '$episodeTitle • Episode ${entry.episode.numberLabel}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _DownloadPreviewRow extends ConsumerWidget {
  const _DownloadPreviewRow({required this.entry});

  final DownloadEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = ref.watch(seriesDetailsProvider(entry.seriesId));
    return details.when(
      loading: () => _DownloadPreviewFallback(entry: entry),
      error: (error, stackTrace) => _DownloadPreviewFallback(entry: entry),
      data: (details) {
        final series = details.series;
        final episode = _findEpisode(details.episodes, entry.episodeId);
        final episodeLabel = episode == null
            ? 'Episode ${entry.episodeId}'
            : 'Episode ${episode.numberLabel}';

        return Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => context.push(AppRoutePaths.downloads),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Poster(imageUrl: series.posterImageUrl, label: series.title),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        series.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$episodeLabel • ${entry.selectedQuality} • ${_downloadStatusLabel(entry)}',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  entry.isPlayableOffline
                      ? Icons.offline_pin_rounded
                      : Icons.chevron_right_rounded,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DownloadPreviewFallback extends StatelessWidget {
  const _DownloadPreviewFallback({required this.entry});

  final DownloadEntry entry;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Poster(imageUrl: null, label: entry.seriesId),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                entry.seriesId,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Episode ${entry.episodeId} • ${entry.selectedQuality} • ${_downloadStatusLabel(entry)}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

Episode? _findEpisode(List<Episode> episodes, String episodeId) {
  for (final episode in episodes) {
    if (episode.id == episodeId) {
      return episode;
    }
  }
  return null;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
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
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}

class _SectionLoading extends StatelessWidget {
  const _SectionLoading({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: title, subtitle: message),
        const SizedBox(height: 12),
        const SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }
}

class _SectionMessage extends StatelessWidget {
  const _SectionMessage({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 72,
        child: AspectRatio(
          aspectRatio: 2 / 3,
          child: AnimeCachedArtwork(
            imageUrl: imageUrl,
            label: label,
            icon: Icons.movie_creation_outlined,
          ),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.label, required this.color});

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
