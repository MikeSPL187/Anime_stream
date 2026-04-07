import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/browse/browse_providers.dart';
import '../../app/router/app_router.dart';
import '../../domain/models/series.dart';
import '../../shared/widgets/anime_cached_artwork.dart';

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
              dividerColor: Colors.transparent,
              tabs: [for (final section in sections) Tab(text: section.title)],
            ),
          ),
          const SizedBox(height: 8),
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
      section.title,
      if (series.releaseYear != null) '${series.releaseYear}',
      if (series.genres.isNotEmpty) series.genres.take(2).join(' • '),
    ].join(' • ');

    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: SizedBox(
        height: 252,
        child: Stack(
          fit: StackFit.expand,
          children: [
            AnimeCachedArtwork(
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
                      Colors.black.withValues(alpha: 0.05),
                      Colors.black.withValues(alpha: 0.16),
                      Colors.black.withValues(alpha: 0.9),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 16,
              top: 16,
              child: _OverlayPill(
                label: section.title,
                icon: Icons.explore_rounded,
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (metadata.isNotEmpty)
                    Text(
                      metadata,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  if (metadata.isNotEmpty) const SizedBox(height: 8),
                  Text(
                    series.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      height: 1.03,
                    ),
                  ),
                  if ((series.originalTitle ?? '').trim().isNotEmpty &&
                      series.originalTitle != series.title) ...[
                    const SizedBox(height: 5),
                    Text(
                      series.originalTitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                  if ((series.synopsis ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      series.synopsis!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.92),
                        height: 1.24,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: () => context.push(
                          AppRoutePaths.seriesDetails(series.id),
                        ),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Open series'),
                      ),
                      TextButton(
                        onPressed: () => context.push(AppRoutePaths.catalog),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Open catalog'),
                      ),
                    ],
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
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
          itemCount: section.seriesList.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 14,
            childAspectRatio: 0.68,
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
        borderRadius: BorderRadius.circular(16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AnimeCachedArtwork(
                imageUrl: series.posterImageUrl,
                label: series.title,
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
                        Colors.black.withValues(alpha: 0.02),
                        Colors.black.withValues(alpha: 0.1),
                        Colors.black.withValues(alpha: 0.9),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      series.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        height: 1.08,
                      ),
                    ),
                    if (metadata.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        metadata,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.76),
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

class _OverlayPill extends StatelessWidget {
  const _OverlayPill({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
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
