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
      appBar: AppBar(
        title: const Text('Browse'),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutePaths.catalog),
            icon: const Icon(Icons.grid_view_rounded),
            tooltip: 'Catalog',
          ),
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
      body: browseCatalog.when(
        loading: () => const _BrowseMessageState(
          title: 'Loading browse',
          message: 'Discovery slices are being prepared.',
          icon: Icons.explore_outlined,
        ),
        error: (error, stackTrace) => _BrowseMessageState(
          title: 'Browse unavailable',
          message: 'Catalog browse data could not be loaded.\n$error',
          icon: Icons.error_outline_rounded,
        ),
        data: (catalog) => _BrowseContent(catalog: catalog),
      ),
    );
  }
}

class _BrowseContent extends StatelessWidget {
  const _BrowseContent({required this.catalog});

  final BrowseCatalogData catalog;

  @override
  Widget build(BuildContext context) {
    final sections = _sections(catalog);
    final spotlight = sections.firstWhere(
      (section) => section.seriesList.isNotEmpty,
      orElse: () => sections.first,
    );

    if (!catalog.hasAnyContent) {
      return const _BrowseMessageState(
        title: 'Nothing surfaced yet',
        message: 'No browse slices are available right now.',
        icon: Icons.explore_outlined,
      );
    }

    return DefaultTabController(
      length: sections.length,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (spotlight.seriesList.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: _BrowseSpotlight(
                section: spotlight,
                series: spotlight.seriesList.first,
              ),
            ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [for (final section in sections) Tab(text: section.title)],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: TabBarView(
              children: [
                for (final section in sections)
                  _BrowseSectionView(section: section),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<_BrowseSection> _sections(BrowseCatalogData catalog) => [
    _BrowseSection(title: 'Latest', seriesList: catalog.latestReleases),
    _BrowseSection(title: 'Trending', seriesList: catalog.trendingSeries),
    _BrowseSection(title: 'Popular', seriesList: catalog.popularSeries),
  ];
}

class _BrowseSpotlight extends StatelessWidget {
  const _BrowseSpotlight({required this.section, required this.series});

  final _BrowseSection section;
  final Series series;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metadata = <String>[
      if (series.releaseYear != null) '${series.releaseYear}',
      if (series.genres.isNotEmpty) series.genres.take(2).join(' • '),
    ].join(' • ');

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        height: 196,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _Artwork(
              imageUrl: series.bannerImageUrl ?? series.posterImageUrl,
              label: series.title,
              icon: Icons.live_tv_rounded,
              alignment: Alignment.topCenter,
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.06),
                      Colors.black.withValues(alpha: 0.16),
                      Colors.black.withValues(alpha: 0.84),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    section.title.toUpperCase(),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    series.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (metadata.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      metadata,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () =>
                        context.push(AppRoutePaths.seriesDetails(series.id)),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      minimumSize: Size.zero,
                    ),
                    icon: const Icon(Icons.chevron_right_rounded, size: 18),
                    label: const Text('Open series'),
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

class _BrowseSectionView extends StatelessWidget {
  const _BrowseSectionView({required this.section});

  final _BrowseSection section;

  @override
  Widget build(BuildContext context) {
    if (section.seriesList.isEmpty) {
      return _BrowseMessageState(
        title: '${section.title} unavailable',
        message: 'No anime is currently available in this slice.',
        icon: Icons.explore_outlined,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 900
            ? 5
            : width >= 720
            ? 4
            : width >= 460
            ? 3
            : 2;

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          itemCount: section.seriesList.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 14,
            childAspectRatio: 0.60,
          ),
          itemBuilder: (context, index) {
            return _BrowsePosterTile(series: section.seriesList[index]);
          },
        );
      },
    );
  }
}

class _BrowsePosterTile extends StatelessWidget {
  const _BrowsePosterTile({required this.series});

  final Series series;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metadata = <String>[
      if (series.releaseYear != null) '${series.releaseYear}',
      if (series.genres.isNotEmpty) series.genres.first,
    ].join(' • ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(AppRoutePaths.seriesDetails(series.id)),
        borderRadius: BorderRadius.circular(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: AspectRatio(
                  aspectRatio: 2 / 3,
                  child: _Artwork(
                    imageUrl: series.posterImageUrl,
                    label: series.title,
                    icon: Icons.movie_creation_outlined,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              series.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium,
            ),
            if (metadata.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                metadata,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Artwork extends StatelessWidget {
  const _Artwork({
    required this.imageUrl,
    required this.label,
    required this.icon,
    this.alignment = Alignment.center,
  });

  final String? imageUrl;
  final String label;
  final IconData icon;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trimmedUrl = imageUrl?.trim();

    if (trimmedUrl == null || trimmedUrl.isEmpty) {
      return _ArtworkFallback(label: label, icon: icon);
    }

    return DecoratedBox(
      decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHigh),
      child: Image.network(
        trimmedUrl,
        fit: BoxFit.cover,
        alignment: alignment,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }

          return Stack(
            fit: StackFit.expand,
            children: [
              _ArtworkFallback(label: label, icon: icon),
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _ArtworkFallback(label: label, icon: icon);
        },
      ),
    );
  }
}

class _ArtworkFallback extends StatelessWidget {
  const _ArtworkFallback({required this.label, required this.icon});

  final String label;
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
              label,
              maxLines: 3,
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

class _BrowseMessageState extends StatelessWidget {
  const _BrowseMessageState({
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;

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
              Icon(icon, color: theme.colorScheme.primary, size: 36),
              const SizedBox(height: 16),
              Text(
                title,
                style: theme.textTheme.titleLarge,
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
            ],
          ),
        ),
      ),
    );
  }
}

class _BrowseSection {
  const _BrowseSection({required this.title, required this.seriesList});

  final String title;
  final List<Series> seriesList;
}
