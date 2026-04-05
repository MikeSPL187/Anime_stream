import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/catalog/catalog_providers.dart';
import '../../app/router/app_router.dart';
import '../../domain/models/series.dart';
import '../../domain/models/series_catalog_page.dart';

class CatalogScreen extends ConsumerStatefulWidget {
  const CatalogScreen({super.key});

  @override
  ConsumerState<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends ConsumerState<CatalogScreen> {
  int _currentPage = 1;

  void _goToPage(int page) {
    if (page == _currentPage || page < 1) {
      return;
    }

    setState(() {
      _currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    final catalogPage = ref.watch(catalogPageProvider(_currentPage));

    return Scaffold(
      appBar: AppBar(title: const Text('Catalog')),
      body: catalogPage.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Catalog page could not be loaded.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (page) => _CatalogPageView(
          page: page,
          onOpenPreviousPage: page.hasPreviousPage
              ? () => _goToPage(page.page - 1)
              : null,
          onOpenNextPage: page.hasNextPage
              ? () => _goToPage(page.page + 1)
              : null,
        ),
      ),
    );
  }
}

class _CatalogPageView extends StatelessWidget {
  const _CatalogPageView({
    required this.page,
    required this.onOpenPreviousPage,
    required this.onOpenNextPage,
  });

  final SeriesCatalogPage page;
  final VoidCallback? onOpenPreviousPage;
  final VoidCallback? onOpenNextPage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        DecoratedBox(
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
                Text('Catalog Listing', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'Browse deeper than the current featured slices through a plain paged catalog listing.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _CatalogMetaChip(label: 'Page ${page.page}'),
                    _CatalogMetaChip(label: '${page.totalItems} total titles'),
                    _CatalogMetaChip(label: '${page.pageSize} per page'),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('All Catalog', style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  'A plain release listing without extra semantic grouping.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                if (page.items.isEmpty)
                  Text(
                    'No titles are available on this catalog page.',
                    style: theme.textTheme.bodyMedium,
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: page.items.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      return _CatalogSeriesRow(series: page.items[index]);
                    },
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: onOpenPreviousPage,
                      icon: const Icon(Icons.chevron_left_rounded),
                      label: const Text('Previous'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Page ${page.page} of ${page.totalPages}',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    FilledButton.icon(
                      onPressed: onOpenNextPage,
                      icon: const Icon(Icons.chevron_right_rounded),
                      label: const Text('Next'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CatalogSeriesRow extends StatelessWidget {
  const _CatalogSeriesRow({required this.series});

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
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CatalogPoster(
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

class _CatalogPoster extends StatelessWidget {
  const _CatalogPoster({required this.imageUrl, required this.label});

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
              ? _CatalogPosterFallback(label: label)
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
                        _CatalogPosterFallback(label: label),
                        const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ],
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return _CatalogPosterFallback(label: label);
                  },
                ),
        ),
      ),
    );
  }
}

class _CatalogPosterFallback extends StatelessWidget {
  const _CatalogPosterFallback({required this.label});

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

class _CatalogMetaChip extends StatelessWidget {
  const _CatalogMetaChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.24),
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
