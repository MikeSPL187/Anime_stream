import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_router.dart';
import '../../app/watchlist/watchlist_providers.dart';
import '../../domain/models/watchlist_entry.dart';
import '../../domain/models/watchlist_snapshot.dart';
import '../../shared/widgets/anime_cached_artwork.dart';

class WatchlistScreen extends ConsumerWidget {
  const WatchlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchlist = ref.watch(watchlistProvider);

    Future<void> refreshWatchlist() async {
      ref.invalidate(watchlistProvider);
      try {
        await ref.read(watchlistProvider.future);
      } catch (_) {
        return;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Watchlist')),
      body: RefreshIndicator(
        onRefresh: refreshWatchlist,
        child: watchlist.when(
          loading: () => const _CenteredState(
            icon: Icons.bookmark_rounded,
            title: 'Loading Watchlist',
            message: 'Saved titles are being loaded.',
          ),
          error: (error, stackTrace) => _CenteredState(
            icon: Icons.error_outline_rounded,
            title: 'Watchlist unavailable',
            message:
                'Saved titles could not be loaded right now. Pull to refresh or retry.',
            action: FilledButton.icon(
              onPressed: refreshWatchlist,
              icon: Icon(Icons.refresh_rounded),
              label: Text('Retry'),
            ),
          ),
          data: (snapshot) => _WatchlistBody(snapshot: snapshot),
        ),
      ),
    );
  }
}

class _WatchlistBody extends StatelessWidget {
  const _WatchlistBody({required this.snapshot});

  final WatchlistSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    if (snapshot.isEmpty) {
      return const _CenteredState(
        icon: Icons.bookmark_add_outlined,
        title: 'No saved titles yet',
        message: 'Save a series from its page to keep it here for later.',
      );
    }

    final entries = snapshot.entries;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _SummaryStrip(snapshot: snapshot),
        const SizedBox(height: 20),
        if (snapshot.hasTemporarilyUnavailableEntries &&
            entries.isNotEmpty) ...[
          _UnavailableSavedTitlesNotice(snapshot: snapshot),
          const SizedBox(height: 16),
        ],
        if (entries.isEmpty)
          _SurfaceBlock(
            child: _UnavailableSavedTitlesNotice(
              snapshot: snapshot,
              compact: true,
            ),
          )
        else
          _SurfaceBlock(
            child: Column(
              children: [
                for (var index = 0; index < entries.length; index++) ...[
                  if (index > 0) const Divider(height: 20),
                  _WatchlistRow(entry: entries[index]),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.snapshot});

  final WatchlistSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _CountBadge(
          label: '${snapshot.totalSavedCount} saved',
          color: colorScheme.primary,
        ),
        if (snapshot.hasTemporarilyUnavailableEntries)
          _CountBadge(
            label: '${snapshot.temporarilyUnavailableCount} unavailable',
            color: colorScheme.secondary,
          ),
      ],
    );
  }
}

class _UnavailableSavedTitlesNotice extends StatelessWidget {
  const _UnavailableSavedTitlesNotice({
    required this.snapshot,
    this.compact = false,
  });

  final WatchlistSnapshot snapshot;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unavailableLabel = snapshot.temporarilyUnavailableCount == 1
        ? '1 saved title is temporarily unavailable.'
        : '${snapshot.temporarilyUnavailableCount} saved titles are temporarily unavailable.';

    final message = snapshot.entries.isEmpty
        ? '$unavailableLabel Pull to refresh and try restoring them later.'
        : '$unavailableLabel Visible titles stay available below, and the missing ones remain saved until the source comes back or the series is confirmed gone.';

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Some saved titles are unavailable',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 6),
        Text(
          message,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );

    if (compact) {
      return content;
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: content),
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
      'Saved ${_formatSavedDate(entry.addedAt)}',
    ].join(' • ');

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
              fallbackLabel: entry.series.title,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.series.title,
                      style: theme.textTheme.titleMedium,
                    ),
                    if ((entry.series.originalTitle ?? '').trim().isNotEmpty &&
                        entry.series.originalTitle != entry.series.title) ...[
                      const SizedBox(height: 4),
                      Text(
                        entry.series.originalTitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (metadata.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        metadata,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
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
                  : Icon(
                      Icons.bookmark_remove_outlined,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenteredState extends StatelessWidget {
  const _CenteredState({
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

class _Poster extends StatelessWidget {
  const _Poster({required this.imageUrl, required this.fallbackLabel});

  final String? imageUrl;
  final String fallbackLabel;

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
            label: fallbackLabel,
            icon: Icons.movie_creation_outlined,
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
