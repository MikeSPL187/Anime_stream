import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/browse/browse_providers.dart';
import '../../app/home/home_continue_watching.dart';
import '../../app/router/app_router.dart';
import '../../app/series/series_providers.dart';
import '../../domain/models/series.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final featuredSeries = ref.watch(featuredSeriesProvider);
    final continueWatching = ref.watch(homeContinueWatchingProvider);
    final browseCatalog = ref.watch(browseCatalogProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
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
      body: _HomeLaunchSurface(
        featuredSeries: featuredSeries,
        continueWatching: continueWatching,
        browseCatalog: browseCatalog,
      ),
    );
  }
}

class _HomeLaunchSurface extends StatelessWidget {
  const _HomeLaunchSurface({
    required this.featuredSeries,
    required this.continueWatching,
    required this.browseCatalog,
  });

  final AsyncValue<List<Series>> featuredSeries;
  final AsyncValue<List<HomeContinueWatchingItem>> continueWatching;
  final AsyncValue<BrowseCatalogData> browseCatalog;

  @override
  Widget build(BuildContext context) {
    final featuredData = featuredSeries.asData?.value;
    final browseData = browseCatalog.asData?.value;
    final isInitialLoading =
        featuredData == null &&
        browseData == null &&
        (featuredSeries.isLoading || browseCatalog.isLoading);

    if (isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async {
        // Route-level pull to refresh intentionally stays read-side only.
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          _ContinueWatchingSection(continueWatching: continueWatching),
          const SizedBox(height: 24),
          if (featuredData != null && featuredData.isNotEmpty)
            _FeaturedHeroSection(series: featuredData.first)
          else
            const _SurfaceCard(
              child: _SectionEmptyMessage(
                title: 'Featured discovery unavailable',
                message:
                    'Home is ready to spotlight a featured anime when the current feed returns one.',
              ),
            ),
          const SizedBox(height: 24),
          _DiscoveryLaunchSection(
            featuredSeries: featuredData ?? const <Series>[],
            browseCatalog: browseCatalog,
          ),
        ],
      ),
    );
  }
}

class _ContinueWatchingSection extends StatelessWidget {
  const _ContinueWatchingSection({required this.continueWatching});

  final AsyncValue<List<HomeContinueWatchingItem>> continueWatching;

  @override
  Widget build(BuildContext context) {
    return _SectionBlock(
      title: 'Continue Watching',
      description:
          'Resume directly from active episodes without stepping through a series page first.',
      trailing: _SectionCountPill(
        label: continueWatching.isLoading
            ? 'Loading'
            : '${continueWatching.asData?.value.length ?? 0} ready',
      ),
      child: continueWatching.when(
        loading: () => const _SurfaceCard(
          child: SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
        error: (error, stackTrace) => _SurfaceCard(
          child: _SectionEmptyMessage(
            title: 'Continue Watching unavailable',
            message: 'Saved watch progress could not be loaded.\n$error',
          ),
        ),
        data: (entries) {
          if (entries.isEmpty) {
            return const _SurfaceCard(
              child: _SectionEmptyMessage(
                title: 'Nothing to resume yet',
                message:
                    'Start an episode from a series page and Home will bring it back here as a resume card.',
              ),
            );
          }

          return SizedBox(
            height: 248,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: entries.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return _ContinueWatchingCard(item: entries[index]);
              },
            ),
          );
        },
      ),
    );
  }
}

class _ContinueWatchingCard extends StatelessWidget {
  const _ContinueWatchingCard({required this.item});

  final HomeContinueWatchingItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progressPercent = item.progressFraction == null
        ? null
        : '${(item.progressFraction! * 100).round()}%';

    return SizedBox(
      width: 228,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => _openContinueWatchingEntry(context, item),
          child: Ink(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: _ArtworkImage(
                        imageUrl: item.seriesPosterImageUrl,
                        fallbackLabel: item.seriesTitle,
                        icon: Icons.movie_creation_outlined,
                        alignment: Alignment.topCenter,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _LeadChip(
                        label: item.episodeLabel,
                        color: theme.colorScheme.secondary,
                      ),
                      if (progressPercent != null)
                        _LeadChip(
                          label: progressPercent,
                          color: theme.colorScheme.primary,
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.seriesTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.episodeTitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: item.progressFraction ?? 0,
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    item.progressLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeaturedHeroSection extends StatelessWidget {
  const _FeaturedHeroSection({required this.series});

  final Series series;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metadata = <String>[
      if (series.releaseYear != null) '${series.releaseYear}',
      if (series.genres.isNotEmpty) series.genres.take(2).join(' • '),
    ].join('  •  ');

    return _SectionBlock(
      title: 'Featured Right Now',
      description:
          'A highlighted anime to launch straight from Home when you want a faster entry than full browsing.',
      child: _SurfaceCard(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeroArtwork(
              imageUrl: series.bannerImageUrl ?? series.posterImageUrl,
              fallbackLabel: series.title,
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (metadata.isNotEmpty) ...[
                    _LeadChip(
                      label: metadata,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(series.title, style: theme.textTheme.headlineSmall),
                  if ((series.originalTitle ?? '').trim().isNotEmpty &&
                      series.originalTitle != series.title) ...[
                    const SizedBox(height: 4),
                    Text(
                      series.originalTitle!,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if ((series.synopsis ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      series.synopsis!,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilledButton.icon(
                        onPressed: () => _openSeriesDetails(context, series),
                        icon: const Icon(Icons.play_arrow_rounded),
                        label: const Text('Open Series'),
                      ),
                      FilledButton.tonalIcon(
                        onPressed: () => context.go(AppRoutePaths.browse),
                        icon: const Icon(Icons.explore_rounded),
                        label: const Text('Browse More'),
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

class _DiscoveryLaunchSection extends StatelessWidget {
  const _DiscoveryLaunchSection({
    required this.featuredSeries,
    required this.browseCatalog,
  });

  final List<Series> featuredSeries;
  final AsyncValue<BrowseCatalogData> browseCatalog;

  @override
  Widget build(BuildContext context) {
    final browseData = browseCatalog.asData?.value;
    final theme = Theme.of(context);

    return _SectionBlock(
      title: 'Explore from Home',
      description:
          'Home stays focused on launch and re-entry, but can still hand you into the real current discovery slices without inventing extra systems.',
      trailing: TextButton.icon(
        onPressed: () => context.go(AppRoutePaths.browse),
        icon: const Icon(Icons.arrow_forward_rounded),
        label: const Text('Open Browse'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (browseCatalog.isLoading && browseData == null)
            const _SurfaceCard(
              child: SizedBox(
                height: 160,
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (browseCatalog.hasError && browseData == null)
            const _SurfaceCard(
              child: _SectionEmptyMessage(
                title: 'Discovery slices unavailable',
                message:
                    'Browse data could not be loaded right now. Open Browse later to retry.',
              ),
            )
          else ...[
            if (browseData != null && browseData.latestReleases.isNotEmpty) ...[
              _PosterRailSection(
                title: 'Latest Releases',
                subtitle:
                    'Fresh titles surfaced from the current repository-backed latest slice.',
                seriesList: browseData.latestReleases,
              ),
              const SizedBox(height: 20),
            ],
            if (browseData != null && browseData.trendingSeries.isNotEmpty) ...[
              _PosterRailSection(
                title: 'Trending Ongoing',
                subtitle:
                    'Current ongoing anime ordered by fresh release activity.',
                seriesList: browseData.trendingSeries,
              ),
              const SizedBox(height: 20),
            ],
            if (browseData != null && browseData.popularSeries.isNotEmpty) ...[
              _PosterRailSection(
                title: 'Popular Catalog',
                subtitle:
                    'Higher-confidence catalog picks when you want broader discovery.',
                seriesList: browseData.popularSeries,
              ),
              const SizedBox(height: 20),
            ],
            if (featuredSeries.length > 1) ...[
              _PosterRailSection(
                title: 'More Featured Picks',
                subtitle:
                    'Additional featured anime surfaced directly on the Home launch screen.',
                seriesList: featuredSeries.skip(1).toList(growable: false),
              ),
            ],
            if ((browseData == null || !browseData.hasAnyContent) &&
                featuredSeries.length <= 1)
              _SurfaceCard(
                child: Text(
                  'Browse is connected, but there are no extra discovery rails to show yet.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _PosterRailSection extends StatelessWidget {
  const _PosterRailSection({
    required this.title,
    required this.subtitle,
    required this.seriesList,
  });

  final String title;
  final String subtitle;
  final List<Series> seriesList;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
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
        const SizedBox(height: 12),
        SizedBox(
          height: 250,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: seriesList.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return _PosterRailCard(series: seriesList[index]);
            },
          ),
        ),
      ],
    );
  }
}

class _PosterRailCard extends StatelessWidget {
  const _PosterRailCard({required this.series});

  final Series series;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metadata = <String>[
      if (series.releaseYear != null) '${series.releaseYear}',
      if (series.genres.isNotEmpty) series.genres.first,
    ].join('  •  ');

    return SizedBox(
      width: 168,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openSeriesDetails(context, series),
          child: Ink(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: AspectRatio(
                      aspectRatio: 2 / 3,
                      child: _ArtworkImage(
                        imageUrl: series.posterImageUrl,
                        fallbackLabel: series.title,
                        icon: Icons.movie_creation_outlined,
                        alignment: Alignment.topCenter,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    series.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  if (metadata.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      metadata,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    'Open series',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({
    required this.title,
    required this.description,
    required this.child,
    this.trailing,
  });

  final String title;
  final String description;
  final Widget child;
  final Widget? trailing;

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
            if (trailing != null) ...[const SizedBox(width: 12), trailing!],
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _SectionCountPill extends StatelessWidget {
  const _SectionCountPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return _LeadChip(
      label: label,
      color: Theme.of(context).colorScheme.primary,
    );
  }
}

class _LeadChip extends StatelessWidget {
  const _LeadChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
      ),
    );
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(24),
      ),
      child: child,
    );
  }
}

class _HeroArtwork extends StatelessWidget {
  const _HeroArtwork({required this.imageUrl, required this.fallbackLabel});

  final String? imageUrl;
  final String fallbackLabel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _ArtworkImage(
            imageUrl: imageUrl,
            fallbackLabel: fallbackLabel,
            icon: Icons.live_tv_rounded,
            alignment: Alignment.topCenter,
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x11000000), Color(0xAA000000)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ArtworkImage extends StatelessWidget {
  const _ArtworkImage({
    required this.imageUrl,
    required this.fallbackLabel,
    required this.icon,
    this.alignment = Alignment.center,
  });

  final String? imageUrl;
  final String fallbackLabel;
  final IconData icon;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trimmedUrl = imageUrl?.trim();

    if (trimmedUrl == null || trimmedUrl.isEmpty) {
      return _ArtworkFallback(fallbackLabel: fallbackLabel, icon: icon);
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
              _ArtworkFallback(fallbackLabel: fallbackLabel, icon: icon),
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _ArtworkFallback(fallbackLabel: fallbackLabel, icon: icon);
        },
      ),
    );
  }
}

class _ArtworkFallback extends StatelessWidget {
  const _ArtworkFallback({required this.fallbackLabel, required this.icon});

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

class _SectionEmptyMessage extends StatelessWidget {
  const _SectionEmptyMessage({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

void _openContinueWatchingEntry(
  BuildContext context,
  HomeContinueWatchingItem item,
) {
  context.push(AppRoutePaths.player, extra: item.playerContext);
}

void _openSeriesDetails(BuildContext context, Series series) {
  context.push(AppRoutePaths.seriesDetails(series.id));
}
