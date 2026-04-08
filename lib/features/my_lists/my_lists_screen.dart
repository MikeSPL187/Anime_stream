import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/downloads/downloads_providers.dart';
import '../../app/history/history_providers.dart';
import '../../app/router/app_router.dart';
import '../../app/series/series_providers.dart';
import '../../app/watchlist/watchlist_providers.dart';
import '../../domain/models/download_entry.dart';
import '../../domain/models/history_entry.dart';
import '../../domain/models/watchlist_entry.dart';
import '../../domain/models/watchlist_snapshot.dart';
import '../../shared/widgets/anime_cached_artwork.dart';
import '../../shared/widgets/media_overlay_pill.dart';

class MyListsScreen extends ConsumerWidget {
  const MyListsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchlist = ref.watch(watchlistProvider);
    final history = ref.watch(watchHistoryProvider);
    final downloads = ref.watch(downloadsListProvider);
    Future<void> refreshMyLists() async {
      ref.invalidate(watchlistProvider);
      ref.invalidate(watchHistoryProvider);
      ref.invalidate(downloadsListProvider);
      await Future.wait<Object?>([
        () async {
          try {
            await ref.read(watchlistProvider.future);
          } catch (_) {
            return null;
          }
        }(),
        () async {
          try {
            await ref.read(watchHistoryProvider.future);
          } catch (_) {
            return null;
          }
        }(),
        () async {
          try {
            await ref.read(downloadsListProvider.future);
          } catch (_) {
            return null;
          }
        }(),
      ]);
    }

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
      body: RefreshIndicator(
        onRefresh: refreshMyLists,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          children: [
            _SummaryStrip(
              watchlistCount: watchlist.asData?.value.totalSavedCount,
              downloadsCount: downloads.asData?.value.length,
              historyCount: history.asData?.value.length,
            ),
            const SizedBox(height: 22),
            _WatchlistSection(watchlist: watchlist),
            const SizedBox(height: 26),
            _DownloadsSection(downloads: downloads),
            const SizedBox(height: 26),
            _HistorySection(history: history),
          ],
        ),
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
              : '${downloadsCount!} downloads',
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

  final AsyncValue<WatchlistSnapshot> watchlist;

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
      data: (snapshot) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionHeader(
            title: 'Watchlist',
            subtitle: 'Saved-for-later series outside active playback.',
            trailing: snapshot.totalSavedCount == 0
                ? null
                : TextButton(
                    onPressed: () => context.push(AppRoutePaths.watchlist),
                    child: const Text('Open all'),
                  ),
          ),
          const SizedBox(height: 12),
          if (snapshot.isEmpty)
            const _SectionMessage(
              title: 'Nothing saved yet',
              message:
                  'Add titles from a series page to keep them here for later.',
            )
          else if (snapshot.entries.isEmpty)
            _SectionMessage(
              title: 'Saved titles temporarily unavailable',
              message: snapshot.temporarilyUnavailableCount == 1
                  ? '1 saved title could not be loaded right now. It stays in Watchlist and can return after a refresh.'
                  : '${snapshot.temporarilyUnavailableCount} saved titles could not be loaded right now. They stay in Watchlist and can return after a refresh.',
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (snapshot.hasTemporarilyUnavailableEntries) ...[
                  _SectionMessage(
                    title: 'Some saved titles are unavailable',
                    message: snapshot.temporarilyUnavailableCount == 1
                        ? '1 saved title could not be loaded right now. The rest of Watchlist still stays available below.'
                        : '${snapshot.temporarilyUnavailableCount} saved titles could not be loaded right now. The rest of Watchlist still stays available below.',
                  ),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  height: 244,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: snapshot.entries.take(4).length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      return _WatchlistCard(entry: snapshot.entries[index]);
                    },
                  ),
                ),
              ],
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
            subtitle: 'Verified offline copies and active download entries.',
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
            SizedBox(
              height: 244,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: entries.take(4).length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return _DownloadPreviewCard(entry: entries[index]);
                },
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
            SizedBox(
              height: 244,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: entries.take(4).length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return _HistoryCard(entry: entries[index]);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _WatchlistCard extends StatelessWidget {
  const _WatchlistCard({required this.entry});

  final WatchlistEntry entry;

  @override
  Widget build(BuildContext context) {
    return _MediaShelfCard(
      imageUrl: entry.series.posterImageUrl,
      title: entry.series.title,
      subtitle: 'Saved for later',
      metadata: <String>[
        if (entry.series.releaseYear != null) '${entry.series.releaseYear}',
        if (entry.series.genres.isNotEmpty) entry.series.genres.first,
      ].join(' • '),
      pillLabel: 'Watchlist',
      pillIcon: Icons.bookmark_rounded,
      onTap: () => context.push(AppRoutePaths.seriesDetails(entry.series.id)),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final episodeTitle = entry.episode.title.trim().isEmpty
        ? 'Episode ${entry.episode.numberLabel}'
        : entry.episode.title;

    return _MediaShelfCard(
      imageUrl: entry.series.posterImageUrl,
      title: entry.series.title,
      subtitle: episodeTitle,
      metadata:
          'Episode ${entry.episode.numberLabel} • Watched ${_formatHistoryDate(entry.watchedAt)}',
      pillLabel: 'History',
      pillIcon: Icons.history_rounded,
      onTap: () => context.push(AppRoutePaths.seriesDetails(entry.series.id)),
    );
  }
}

class _DownloadPreviewCard extends ConsumerWidget {
  const _DownloadPreviewCard({required this.entry});

  final DownloadEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final content = ref.watch(seriesContentProvider(entry.seriesId));
    return content.when(
      loading: () => _MediaShelfCard(
        imageUrl: null,
        title: entry.seriesId,
        subtitle: 'Episode ${entry.episodeId}',
        metadata: '${entry.selectedQuality} • ${_downloadStatusLabel(entry)}',
        pillLabel: _downloadPillLabel(entry),
        pillIcon: _downloadPillIcon(entry),
        onTap: () => context.push(AppRoutePaths.downloads),
      ),
      error: (error, stackTrace) => _MediaShelfCard(
        imageUrl: null,
        title: entry.seriesId,
        subtitle: 'Episode ${entry.episodeId}',
        metadata: '${entry.selectedQuality} • ${_downloadStatusLabel(entry)}',
        pillLabel: _downloadPillLabel(entry),
        pillIcon: _downloadPillIcon(entry),
        onTap: () => context.push(AppRoutePaths.downloads),
      ),
      data: (content) {
        final episode = content.episodeById(entry.episodeId);
        final episodeLabel = episode == null
            ? 'Episode ${entry.episodeId}'
            : 'Episode ${episode.numberLabel}';
        return _MediaShelfCard(
          imageUrl: content.series.posterImageUrl,
          title: content.series.title,
          subtitle: episodeLabel,
          metadata: '${entry.selectedQuality} • ${_downloadStatusLabel(entry)}',
          pillLabel: _downloadPillLabel(entry),
          pillIcon: _downloadPillIcon(entry),
          onTap: () => context.push(AppRoutePaths.downloads),
        );
      },
    );
  }
}

class _MediaShelfCard extends StatelessWidget {
  const _MediaShelfCard({
    required this.imageUrl,
    required this.title,
    required this.subtitle,
    required this.metadata,
    required this.pillLabel,
    required this.pillIcon,
    required this.onTap,
  });

  final String? imageUrl;
  final String title;
  final String subtitle;
  final String metadata;
  final String pillLabel;
  final IconData pillIcon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 170,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              fit: StackFit.expand,
              children: [
                AnimeCachedArtwork(
                  imageUrl: imageUrl,
                  label: title,
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
                          Colors.black.withValues(alpha: 0.9),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: MediaOverlayPill(label: pillLabel, icon: pillIcon),
                ),
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          height: 1.08,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                      if (metadata.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          metadata,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.78),
                          ),
                        ),
                      ],
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
          height: 160,
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
    DownloadStatus.queued || DownloadStatus.paused => 'Restart needed',
    DownloadStatus.failed when entry.requiresOfflineRestore => 'Restore needed',
    DownloadStatus.failed when _downloadNeedsRestart(entry) => 'Restart needed',
    DownloadStatus.failed => 'Retry needed',
  };
}

String _downloadPillLabel(DownloadEntry entry) {
  return switch (entry.status) {
    DownloadStatus.completed when entry.isPlayableOffline => 'Offline ready',
    DownloadStatus.failed when entry.requiresOfflineRestore => 'Restore needed',
    DownloadStatus.downloading => 'Downloading',
    DownloadStatus.queued || DownloadStatus.paused => 'Restart needed',
    DownloadStatus.failed when _downloadNeedsRestart(entry) => 'Restart needed',
    _ => 'Downloads',
  };
}

IconData _downloadPillIcon(DownloadEntry entry) {
  return switch (entry.status) {
    DownloadStatus.completed when entry.isPlayableOffline =>
      Icons.offline_pin_rounded,
    DownloadStatus.failed when entry.requiresOfflineRestore =>
      Icons.warning_amber_rounded,
    DownloadStatus.downloading => Icons.download_rounded,
    DownloadStatus.queued || DownloadStatus.paused => Icons.restart_alt_rounded,
    DownloadStatus.failed when _downloadNeedsRestart(entry) =>
      Icons.restart_alt_rounded,
    _ => Icons.download_rounded,
  };
}

bool _downloadNeedsRestart(DownloadEntry entry) {
  return entry.failureKind == DownloadFailureKind.transferInterrupted ||
      entry.status == DownloadStatus.queued ||
      entry.status == DownloadStatus.paused;
}

String _formatHistoryDate(DateTime watchedAt) {
  final date = watchedAt.toLocal();
  final month = switch (date.month) {
    1 => 'Jan',
    2 => 'Feb',
    3 => 'Mar',
    4 => 'Apr',
    5 => 'May',
    6 => 'Jun',
    7 => 'Jul',
    8 => 'Aug',
    9 => 'Sep',
    10 => 'Oct',
    11 => 'Nov',
    12 => 'Dec',
    _ => '',
  };

  return '$month ${date.day}';
}
