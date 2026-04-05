import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/browse/browse_providers.dart';
import '../../app/router/app_router.dart';
import '../../domain/models/series.dart';

class BrowseScreen extends ConsumerWidget {
  const BrowseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final browseCatalog = ref.watch(browseCatalogProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Browse')),
      body: browseCatalog.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Catalog browse data could not be loaded.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (catalog) => _BrowseCatalogView(catalog: catalog),
      ),
    );
  }
}

class _BrowseCatalogView extends StatelessWidget {
  const _BrowseCatalogView({required this.catalog});

  final BrowseCatalogData catalog;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const _BrowseIntroCard(),
        const SizedBox(height: 16),
        if (!catalog.hasAnyContent)
          const _BrowseEmptyState()
        else ...[
          if (catalog.latestReleases.isNotEmpty) ...[
            _BrowseSection(
              title: 'Latest Releases',
              description:
                  'Most recently surfaced releases from the current catalog feed.',
              seriesList: catalog.latestReleases,
            ),
            const SizedBox(height: 24),
          ],
          if (catalog.trendingSeries.isNotEmpty) ...[
            _BrowseSection(
              title: 'Trending Ongoing',
              description:
                  'Ongoing titles currently ordered by fresh release activity.',
              seriesList: catalog.trendingSeries,
            ),
            const SizedBox(height: 24),
          ],
          if (catalog.popularSeries.isNotEmpty)
            _BrowseSection(
              title: 'Popular Catalog',
              description:
                  'Titles currently surfaced from rating-sorted catalog discovery.',
              seriesList: catalog.popularSeries,
            ),
        ],
      ],
    );
  }
}

class _BrowseIntroCard extends StatelessWidget {
  const _BrowseIntroCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Browse the Catalog', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Use real catalog slices to explore when you do not have a specific title in mind.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _BrowseHintChip(
                  label: 'Latest releases',
                  color: theme.colorScheme.primary,
                ),
                _BrowseHintChip(
                  label: 'Trending ongoing',
                  color: theme.colorScheme.secondary,
                ),
                _BrowseHintChip(
                  label: 'Rating-based popular',
                  color: theme.colorScheme.tertiary,
                ),
              ],
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => context.push(AppRoutePaths.catalog),
              icon: const Icon(Icons.view_list_rounded),
              label: const Text('Open Full Catalog'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrowseSection extends StatelessWidget {
  const _BrowseSection({
    required this.title,
    required this.description,
    required this.seriesList,
  });

  final String title;
  final String description;
  final List<Series> seriesList;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
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
                ],
              ),
            ),
            const SizedBox(width: 12),
            _BrowseHintChip(
              label: '${seriesList.length}',
              color: theme.colorScheme.primary,
            ),
          ],
        ),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              for (var index = 0; index < seriesList.length; index++) ...[
                if (index > 0) const Divider(height: 1),
                _BrowseSeriesRow(series: seriesList[index]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _BrowseSeriesRow extends StatelessWidget {
  const _BrowseSeriesRow({required this.series});

  final Series series;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metadata = <String>[
      if (series.releaseYear != null) '${series.releaseYear}',
      if (series.genres.isNotEmpty) series.genres.take(2).join(' • '),
    ].join('  •  ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(AppRoutePaths.seriesDetails(series.id)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _BrowsePoster(
                imageUrl: series.posterImageUrl,
                label: series.title,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(series.title, style: theme.textTheme.titleMedium),
                    if ((series.originalTitle ?? '').trim().isNotEmpty &&
                        series.originalTitle != series.title) ...[
                      const SizedBox(height: 4),
                      Text(
                        series.originalTitle!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (metadata.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        metadata,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if ((series.synopsis ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        series.synopsis!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                    const SizedBox(height: 10),
                    Text(
                      'Open series',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
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
      ),
    );
  }
}

class _BrowsePoster extends StatelessWidget {
  const _BrowsePoster({required this.imageUrl, required this.label});

  final String? imageUrl;
  final String label;

  @override
  Widget build(BuildContext context) {
    final trimmedUrl = imageUrl?.trim();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 72,
        child: AspectRatio(
          aspectRatio: 2 / 3,
          child: trimmedUrl == null || trimmedUrl.isEmpty
              ? _BrowsePosterFallback(label: label)
              : Image.network(
                  trimmedUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    }

                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        _BrowsePosterFallback(label: label),
                        const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ],
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return _BrowsePosterFallback(label: label);
                  },
                ),
        ),
      ),
    );
  }
}

class _BrowsePosterFallback extends StatelessWidget {
  const _BrowsePosterFallback({required this.label});

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
        padding: const EdgeInsets.all(8),
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
              maxLines: 3,
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

class _BrowseEmptyState extends StatelessWidget {
  const _BrowseEmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.travel_explore_rounded,
                size: 32,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text('Browse Is Unavailable', style: theme.textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                'No catalog groups are available right now.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrowseHintChip extends StatelessWidget {
  const _BrowseHintChip({required this.label, required this.color});

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
