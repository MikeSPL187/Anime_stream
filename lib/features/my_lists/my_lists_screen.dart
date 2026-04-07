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
          const _LeadHeader(),
          const SizedBox(height: 20),
          _SummaryStrip(
            watchlistCount: watchlist.asData?.value.length,
            historyCount: history.asData?.value.length,
            downloadsCount: downloads.asData?.value.length,
          ),
          const SizedBox(height: 24),
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

class _LeadHeader extends StatelessWidget {
  const _LeadHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Lists'.toUpperCase(),
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Saved, offline, and watched',
          style: theme.textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          'Keep saved intent, offline-ready episodes, and completed watch history in one place.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({
    required this.watchlistCount,
    required this.historyCount,
    required this.downloadsCount,
  });

  final int? watchlistCount;
  final int? historyCount;
  final int? downloadsCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Badge(
          label: watchlistCount == null
              ? 'Watchlist loading'
              : '${watchlistCount!} saved',
          color: theme.colorScheme.primary,
        ),
        _Badge(
          label: downloadsCount == null
              ? 'Downloads loading'
              : '${downloadsCount!} offline',
          color: theme.colorScheme.secondary,
        ),
        _Badge(
          label: historyCount == null
              ? 'History loading'
              : '${historyCount!} watched',
          color: theme.colorScheme.tertiary,
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
    final theme = Theme.of(context);

    return watchlist.when(
      loading: () => const _SurfaceCard(
        child: _LoadingRow(label: 'Loading saved titles...'),
      ),
      error: (error, stackTrace) =>
          _SurfaceCard(child: Text('Watchlist unavailable.\n$error')),
      data: (entries) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Watchlist', style: theme.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Titles you saved to revisit later outside active playback.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          if (entries.isEmpty)
            const _SurfaceCard(
              child: Text(
                'No saved anime yet. Add titles from their series pages.',
              ),
            )
          else
            _SurfaceCard(
              child: Column(
                children: [
                  for (
                    var index = 0;
                    index < entries.take(3).length;
                    index++
                  ) ...[
                    if (index > 0) const Divider(height: 20),
                    _WatchlistRow(entry: entries[index]),
                  ],
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: () => context.push(AppRoutePaths.watchlist),
                      icon: const Icon(Icons.bookmarks_outlined),
                      label: Text(
                        entries.length > 3
                            ? 'Open full watchlist (${entries.length})'
                            : 'Open watchlist',
                      ),
                    ),
                  ),
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
    final theme = Theme.of(context);

    return downloads.when(
      loading: () => const _SurfaceCard(
        child: _LoadingRow(label: 'Loading offline downloads...'),
      ),
      error: (error, stackTrace) =>
          _SurfaceCard(child: Text('Downloads unavailable.\n$error')),
      data: (entries) {
        final previewEntries = entries.take(3).toList(growable: false);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Downloads', style: theme.textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              'Offline-ready episodes and active download states live here as a real product surface.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            if (entries.isEmpty)
              const _SurfaceCard(
                child: Text(
                  'No offline downloads yet. Download episodes from a series page.',
                ),
              )
            else
              _SurfaceCard(
                child: Column(
                  children: [
                    for (
                      var index = 0;
                      index < previewEntries.length;
                      index++
                    ) ...[
                      if (index > 0) const Divider(height: 20),
                      _DownloadPreviewRow(entry: previewEntries[index]),
                    ],
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonalIcon(
                        onPressed: () => context.push(AppRoutePaths.downloads),
                        icon: const Icon(Icons.download_rounded),
                        label: Text(
                          entries.length > 3
                              ? 'Open full downloads (${entries.length})'
                              : 'Open downloads',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

class _HistorySection extends StatelessWidget {
  const _HistorySection({required this.history});

  final AsyncValue<List<HistoryEntry>> history;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return history.when(
      loading: () => const _SurfaceCard(
        child: _LoadingRow(label: 'Loading watch history...'),
      ),
      error: (error, stackTrace) =>
          _SurfaceCard(child: Text('History unavailable.\n$error')),
      data: (entries) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Watch History', style: theme.textTheme.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Completed episode activity kept separate from active re-entry.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          if (entries.isEmpty)
            const _SurfaceCard(
              child: Text(
                'No completed episodes yet. Finished anime will appear here.',
              ),
            )
          else
            _SurfaceCard(
              child: Column(
                children: [
                  for (
                    var index = 0;
                    index < entries.take(3).length;
                    index++
                  ) ...[
                    if (index > 0) const Divider(height: 20),
                    _HistoryRow(entry: entries[index]),
                  ],
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonalIcon(
                      onPressed: () => context.push(AppRoutePaths.history),
                      icon: const Icon(Icons.history_rounded),
                      label: Text(
                        entries.length > 3
                            ? 'Open full history (${entries.length})'
                            : 'Open history',
                      ),
                    ),
                  ),
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
        borderRadius: BorderRadius.circular(16),
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
                  _Badge(label: 'Saved', color: theme.colorScheme.primary),
                  const SizedBox(height: 10),
                  Text(entry.series.title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    'Open series',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
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
        borderRadius: BorderRadius.circular(16),
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
                  _Badge(label: 'Completed', color: theme.colorScheme.tertiary),
                  const SizedBox(height: 10),
                  Text(entry.series.title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(
                    episodeTitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Episode ${entry.episode.numberLabel}',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
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
            borderRadius: BorderRadius.circular(16),
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
                      _Badge(
                        label: _downloadStatusLabel(entry),
                        color: _downloadStatusColor(context, entry.status),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        series.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$episodeLabel • ${entry.selectedQuality}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
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
              _Badge(
                label: _downloadStatusLabel(entry),
                color: _downloadStatusColor(context, entry.status),
              ),
              const SizedBox(height: 10),
              Text(
                entry.seriesId,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                'Episode ${entry.episodeId} • ${entry.selectedQuality}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

class _Poster extends StatelessWidget {
  const _Poster({required this.imageUrl, required this.label});

  final String? imageUrl;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trimmedUrl = imageUrl?.trim();

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 84,
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
                    errorBuilder: (context, error, stackTrace) {
                      return _PosterFallback(label: label);
                    },
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

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

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

class _LoadingRow extends StatelessWidget {
  const _LoadingRow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text(label)),
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

Color _downloadStatusColor(BuildContext context, DownloadStatus status) {
  final colorScheme = Theme.of(context).colorScheme;
  return switch (status) {
    DownloadStatus.completed => colorScheme.primary,
    DownloadStatus.downloading ||
    DownloadStatus.queued => colorScheme.secondary,
    DownloadStatus.paused => colorScheme.tertiary,
    DownloadStatus.failed => colorScheme.error,
  };
}
