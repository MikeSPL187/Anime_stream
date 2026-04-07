import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/history/history_providers.dart';
import '../../app/router/app_router.dart';
import '../../app/watchlist/watchlist_providers.dart';
import '../../domain/models/history_entry.dart';
import '../../domain/models/watchlist_entry.dart';

class MyListsScreen extends ConsumerWidget {
  const MyListsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final watchlist = ref.watch(watchlistProvider);
    final history = ref.watch(watchHistoryProvider);
    final watchlistCount = watchlist.asData?.value.length;
    final historyCount = history.asData?.value.length;

    return Scaffold(
      appBar: AppBar(title: const Text('My Lists')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _MyListsIntroCard(
            watchlistCount: watchlistCount,
            historyCount: historyCount,
          ),
          const SizedBox(height: 16),
          _MyListsWatchlistSection(watchlist: watchlist),
          const SizedBox(height: 24),
          _MyListsHistorySection(history: history),
        ],
      ),
    );
  }
}

class _MyListsIntroCard extends StatelessWidget {
  const _MyListsIntroCard({
    required this.watchlistCount,
    required this.historyCount,
  });

  final int? watchlistCount;
  final int? historyCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final watchlistLabel = watchlistCount == null
        ? 'Watchlist loading'
        : '$watchlistCount saved';
    final historyLabel = historyCount == null
        ? 'History loading'
        : '$historyCount watched';

    return _MyListsSurfaceCard(
      backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Saved and Previously Watched', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'My Lists is the home for saved-for-later titles and completed viewing activity. Continue Watching stays on Home as the active re-entry surface.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MyListsBadge(
                label: watchlistLabel,
                color: theme.colorScheme.primary,
              ),
              _MyListsBadge(
                label: historyLabel,
                color: theme.colorScheme.tertiary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MyListsWatchlistSection extends StatelessWidget {
  const _MyListsWatchlistSection({required this.watchlist});

  final AsyncValue<List<WatchlistEntry>> watchlist;

  @override
  Widget build(BuildContext context) {
    return _MyListsSection(
      title: 'Watchlist',
      description: 'Titles you saved to revisit later without mixing them into in-progress playback.',
      child: watchlist.when(
        loading: () => const _MyListsLoadingState(
          label: 'Loading saved titles...',
        ),
        error: (error, stackTrace) => _MyListsMessageState(
          icon: Icons.error_outline_rounded,
          title: 'Watchlist unavailable',
          message: 'Saved titles could not be loaded.\n$error',
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return const _MyListsMessageState(
              icon: Icons.bookmark_add_outlined,
              title: 'Nothing saved yet',
              message: 'Save a series from its page to keep it here for later.',
            );
          }

          final previewEntries = entries.take(3).toList(growable: false);

          return _MyListsSurfaceCard(
            child: Column(
              children: [
                for (var index = 0; index < previewEntries.length; index++) ...[
                  if (index > 0) const Divider(height: 1),
                  _WatchlistPreviewRow(entry: previewEntries[index]),
                ],
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonalIcon(
                    onPressed: () => context.push(AppRoutePaths.watchlist),
                    icon: const Icon(Icons.bookmarks_outlined),
                    label: Text(
                      entries.length > previewEntries.length
                          ? 'Open full Watchlist (${entries.length})'
                          : 'Open Watchlist',
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MyListsHistorySection extends StatelessWidget {
  const _MyListsHistorySection({required this.history});

  final AsyncValue<List<HistoryEntry>> history;

  @override
  Widget build(BuildContext context) {
    return _MyListsSection(
      title: 'Watch History',
      description: 'Completed episode activity kept separate from saved intent and active resume flow.',
      child: history.when(
        loading: () => const _MyListsLoadingState(
          label: 'Loading watch history...',
        ),
        error: (error, stackTrace) => _MyListsMessageState(
          icon: Icons.error_outline_rounded,
          title: 'Watch history unavailable',
          message: 'Completed viewing activity could not be loaded.\n$error',
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return const _MyListsMessageState(
              icon: Icons.history_toggle_off_rounded,
              title: 'No completed episodes yet',
              message: 'Episodes appear here after they are fully watched.',
            );
          }

          final previewEntries = entries.take(3).toList(growable: false);

          return _MyListsSurfaceCard(
            child: Column(
              children: [
                for (var index = 0; index < previewEntries.length; index++) ...[
                  if (index > 0) const Divider(height: 1),
                  _HistoryPreviewRow(entry: previewEntries[index]),
                ],
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.tonalIcon(
                    onPressed: () => context.push(AppRoutePaths.history),
                    icon: const Icon(Icons.history_rounded),
                    label: Text(
                      entries.length > previewEntries.length
                          ? 'Open full History (${entries.length})'
                          : 'Open History',
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MyListsSection extends StatelessWidget {
  const _MyListsSection({
    required this.title,
    required this.description,
    required this.child,
  });

  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          description,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _WatchlistPreviewRow extends StatelessWidget {
  const _WatchlistPreviewRow({required this.entry});

  final WatchlistEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
              _MyListsPoster(
                imageUrl: entry.series.posterImageUrl,
                fallbackLabel: entry.series.title,
                icon: Icons.bookmark_outline_rounded,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MyListsBadge(
                      label: 'Saved for later',
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 10),
                    Text(entry.series.title, style: theme.textTheme.titleMedium),
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
                      'Saved ${_formatMonthDayYear(entry.addedAt)}',
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
      ),
    );
  }
}

class _HistoryPreviewRow extends StatelessWidget {
  const _HistoryPreviewRow({required this.entry});

  final HistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metadata = <String>[
      if (entry.series.releaseYear != null) '${entry.series.releaseYear}',
      if (entry.series.genres.isNotEmpty) entry.series.genres.first,
    ].join('  •  ');
    final episodeTitle = entry.episode.title.trim().isEmpty
        ? 'Episode ${entry.episode.numberLabel}'
        : entry.episode.title;

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
              _MyListsPoster(
                imageUrl: entry.series.posterImageUrl,
                fallbackLabel: entry.series.title,
                icon: Icons.history_rounded,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MyListsBadge(
                      label: 'Completed',
                      color: theme.colorScheme.tertiary,
                    ),
                    const SizedBox(height: 10),
                    Text(entry.series.title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 3),
                    Text(
                      episodeTitle,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Episode ${entry.episode.numberLabel} • Watched ${_formatMonthDayYear(entry.watchedAt)}',
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
      ),
    );
  }
}

class _MyListsLoadingState extends StatelessWidget {
  const _MyListsLoadingState({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return _MyListsSurfaceCard(
      child: Row(
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label),
          ),
        ],
      ),
    );
  }
}

class _MyListsMessageState extends StatelessWidget {
  const _MyListsMessageState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _MyListsSurfaceCard(
      child: Column(
        children: [
          Icon(icon, size: 32, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text(title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            message,
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

class _MyListsPoster extends StatelessWidget {
  const _MyListsPoster({
    required this.imageUrl,
    required this.fallbackLabel,
    required this.icon,
  });

  final String? imageUrl;
  final String fallbackLabel;
  final IconData icon;

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
              ? _MyListsPosterFallback(
                  fallbackLabel: fallbackLabel,
                  icon: icon,
                )
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
                          _MyListsPosterFallback(
                            fallbackLabel: fallbackLabel,
                            icon: icon,
                          ),
                          const Center(
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ],
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return _MyListsPosterFallback(
                        fallbackLabel: fallbackLabel,
                        icon: icon,
                      );
                    },
                  ),
                ),
        ),
      ),
    );
  }
}

class _MyListsPosterFallback extends StatelessWidget {
  const _MyListsPosterFallback({
    required this.fallbackLabel,
    required this.icon,
  });

  final String fallbackLabel;
  final IconData icon;

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
            Icon(icon, color: theme.colorScheme.onSurfaceVariant),
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

class _MyListsSurfaceCard extends StatelessWidget {
  const _MyListsSurfaceCard({required this.child, this.backgroundColor});

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

class _MyListsBadge extends StatelessWidget {
  const _MyListsBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
      ),
    );
  }
}

String _formatMonthDayYear(DateTime dateTime) {
  final date = dateTime.toLocal();
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
