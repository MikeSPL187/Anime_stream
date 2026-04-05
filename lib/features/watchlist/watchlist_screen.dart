import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_router.dart';
import '../../app/watchlist/watchlist_providers.dart';
import '../../domain/models/watchlist_entry.dart';

class WatchlistScreen extends ConsumerWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchlist = ref.watch(watchlistProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Watchlist')),
      body: watchlist.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Saved titles could not be loaded.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (entries) => _WatchlistView(entries: entries),
      ),
    );
  }
}

class _WatchlistView extends StatelessWidget {
  const _WatchlistView({required this.entries});

  final List<WatchlistEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _WatchlistIntroCard(count: entries.length),
        const SizedBox(height: 16),
        if (entries.isEmpty)
          const _WatchlistEmptyState()
        else
          _WatchlistSurfaceCard(
            child: Column(
              children: [
                for (var index = 0; index < entries.length; index++) ...[
                  if (index > 0) const Divider(height: 1),
                  _WatchlistRow(entry: entries[index]),
                ],
              ],
            ),
          ),
        if (entries.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            'Watchlist is for saved-for-later intent. Continue Watching remains the place for in-progress episodes.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}

class _WatchlistIntroCard extends StatelessWidget {
  const _WatchlistIntroCard({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _WatchlistSurfaceCard(
      backgroundColor: theme.colorScheme.primaryContainer.withValues(
        alpha: 0.16,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.bookmark_rounded,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Saved for Later', style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  'Keep titles here when you want to return later, even before starting playback.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _WatchlistCountBadge(label: '$count saved'),
        ],
      ),
    );
  }
}

class _WatchlistEmptyState extends StatelessWidget {
  const _WatchlistEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _WatchlistSurfaceCard(
      child: Column(
        children: [
          Icon(
            Icons.bookmark_add_outlined,
            size: 36,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: 12),
          Text('No Saved Titles Yet', style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            'Save a series from its page to keep it here for later. This is separate from Continue Watching.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _WatchlistRow extends ConsumerWidget {
  const _WatchlistRow({required this.entry});

  final WatchlistEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final membership = ref.watch(
      watchlistMembershipControllerProvider(entry.series.id),
    );
    final metadata = <String>[
      if (entry.series.releaseYear != null) '${entry.series.releaseYear}',
      if (entry.series.genres.isNotEmpty) entry.series.genres.first,
    ].join('  •  ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(AppRoutePaths.seriesDetails(entry.series.id)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _WatchlistPoster(
                imageUrl: entry.series.posterImageUrl,
                fallbackLabel: entry.series.title,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _WatchlistCountBadge(label: 'Saved for later'),
                    const SizedBox(height: 10),
                    Text(
                      entry.series.title,
                      style: theme.textTheme.titleMedium,
                    ),
                    if ((entry.series.originalTitle ?? '').trim().isNotEmpty &&
                        entry.series.originalTitle != entry.series.title) ...[
                      const SizedBox(height: 3),
                      Text(
                        entry.series.originalTitle!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Saved ${_formatSavedDate(entry.addedAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (metadata.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        metadata,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      'Opens the series page.',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: membership.isLoading
                    ? null
                    : () => ref
                          .read(
                            watchlistMembershipControllerProvider(
                              entry.series.id,
                            ).notifier,
                          )
                          .removeFromWatchlist(),
                tooltip: 'Remove from watchlist',
                icon: membership.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.bookmark_remove_outlined),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WatchlistPoster extends StatelessWidget {
  const _WatchlistPoster({required this.imageUrl, required this.fallbackLabel});

  final String? imageUrl;
  final String fallbackLabel;

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
              ? _WatchlistPosterFallback(fallbackLabel: fallbackLabel)
              : DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                  ),
                  child: Image.network(
                    trimmedUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) {
                        return child;
                      }

                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          _WatchlistPosterFallback(
                            fallbackLabel: fallbackLabel,
                          ),
                          const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ],
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return _WatchlistPosterFallback(
                        fallbackLabel: fallbackLabel,
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }
}

class _WatchlistPosterFallback extends StatelessWidget {
  const _WatchlistPosterFallback({required this.fallbackLabel});

  final String fallbackLabel;

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
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.movie_creation_outlined,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              fallbackLabel,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WatchlistSurfaceCard extends StatelessWidget {
  const _WatchlistSurfaceCard({required this.child, this.backgroundColor});

  final Widget child;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

class _WatchlistCountBadge extends StatelessWidget {
  const _WatchlistCountBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

String _formatSavedDate(DateTime addedAt) {
  final date = addedAt.toLocal();
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

  return '$month ${date.day}, ${date.year}';
}
