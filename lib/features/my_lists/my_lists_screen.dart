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

    return Scaffold(
      appBar: AppBar(title: const Text('My Lists')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
        children: [
          const _LeadHeader(),
          const SizedBox(height: 20),
          _SummaryStrip(
            watchlistCount: watchlist.asData?.value.length,
            historyCount: history.asData?.value.length,
          ),
          const SizedBox(height: 28),
          _WatchlistSection(watchlist: watchlist),
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
          'Saved anime'.toUpperCase(),
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text('My Lists', style: theme.textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(
          'Keep saved-for-later anime and completed viewing activity in one personal place.',
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
  });

  final int? watchlistCount;
  final int? historyCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Badge(
          label: watchlistCount == null ? 'Watchlist loading' : '${watchlistCount!} saved',
          color: theme.colorScheme.primary,
        ),
        _Badge(
          label: historyCount == null ? 'History loading' : '${historyCount!} watched',
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
      loading: () => const _PanelCard(child: _LoadingRow(label: 'Loading saved titles...')),
      error: (error, stackTrace) => _PanelCard(
        child: Text('Watchlist unavailable.\n$error'),
      ),
      data: (entries) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Watchlist', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            'Anime you saved to revisit later.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          if (entries.isEmpty)
            const _PanelCard(
              child: Text('No saved anime yet. Add titles from their series pages.'),
            )
          else
            _PanelCard(
              child: Column(
                children: [
                  for (var index = 0; index < entries.take(3).length; index++) ...[
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

class _HistorySection extends StatelessWidget {
  const _HistorySection({required this.history});

  final AsyncValue<List<HistoryEntry>> history;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return history.when(
      loading: () => const _PanelCard(child: _LoadingRow(label: 'Loading watch history...')),
      error: (error, stackTrace) => _PanelCard(
        child: Text('History unavailable.\n$error'),
      ),
      data: (entries) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Watch History', style: theme.textTheme.headlineSmall),
          const SizedBox(height: 6),
          Text(
            'Completed episode activity kept separate from active re-entry.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          if (entries.isEmpty)
            const _PanelCard(
              child: Text('No completed episodes yet. Finished anime will appear here.'),
            )
          else
            _PanelCard(
              child: Column(
                children: [
                  for (var index = 0; index < entries.take(3).length; index++) ...[
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
            _Poster(imageUrl: entry.series.posterImageUrl, label: entry.series.title),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Badge(
                    label: 'Saved',
                    color: theme.colorScheme.primary,
                  ),
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
            _Poster(imageUrl: entry.series.posterImageUrl, label: entry.series.title),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Badge(
                    label: 'Completed',
                    color: theme.colorScheme.tertiary,
                  ),
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
                  decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHigh),
                  child: Image.network(
                    trimmedUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          _PosterFallback(label: label),
                          const Center(child: CircularProgressIndicator(strokeWidth: 2)),
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
            Icon(Icons.movie_creation_outlined, color: theme.colorScheme.onSurfaceVariant),
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

class _PanelCard extends StatelessWidget {
  const _PanelCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(child: Padding(padding: const EdgeInsets.all(18), child: child));
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