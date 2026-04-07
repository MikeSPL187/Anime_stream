import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/browse/browse_providers.dart';
import '../../app/home/home_continue_watching.dart';
import '../../app/router/app_router.dart';
import '../../app/series/series_providers.dart';
import '../../domain/models/series.dart';
import '../../shared/widgets/anime_cached_artwork.dart';

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
    final featuredData = featuredSeries.asData?.value ?? const <Series>[];
    final browseData = browseCatalog.asData?.value;
    final hasInitialContent = featuredData.isNotEmpty || browseData != null;
    final isInitialLoading =
        !hasInitialContent &&
        (featuredSeries.isLoading || browseCatalog.isLoading);

    if (isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          _ContinueWatchingSection(continueWatching: continueWatching),
          const SizedBox(height: 20),
          if (featuredData.isNotEmpty)
            _FeaturedHero(series: featuredData.first)
          else
            const _InlineEmptyState(
              title: 'Featured anime unavailable',
              message:
                  'Home will spotlight a launch title when discovery resolves one.',
            ),
          const SizedBox(height: 24),
          _DiscoverySection(
            featuredSeries: featuredData.skip(1).toList(growable: false),
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
    return continueWatching.when(
      loading: () => const _SectionLoadingState(title: 'Continue Watching'),
      error: (error, stackTrace) => _SectionErrorState(
        title: 'Continue Watching',
        message: 'Saved watch progress could not be loaded.\n$error',
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return const _InlineEmptyState(
            title: 'Nothing to resume',
            message:
                'Start an episode from a series page and Home will bring it back here.',
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _SectionHeader(
              title: 'Continue Watching',
              trailing: Text(
                '${entries.length} active',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 228,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: entries.length,
                separatorBuilder: (context, index) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return _ContinueWatchingCard(item: entries[index]);
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ContinueWatchingCard extends StatelessWidget {
  const _ContinueWatchingCard({required this.item});

  final HomeContinueWatchingItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 168,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openContinueWatchingEntry(context, item),
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AnimeCachedArtwork(
                        imageUrl: item.seriesPosterImageUrl,
                        label: item.seriesTitle,
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
                                Colors.black.withValues(alpha: 0.04),
                                Colors.black.withValues(alpha: 0.08),
                                Colors.black.withValues(alpha: 0.82),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 10,
                        right: 10,
                        bottom: 10,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.episodeLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.seriesTitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(999),
                              child: LinearProgressIndicator(
                                value: item.progressFraction ?? 0,
                                minHeight: 5,
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.18,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.episodeTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 3),
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
    );
  }
}

class _FeaturedHero extends StatelessWidget {
  const _FeaturedHero({required this.series});

  final Series series;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metadata = <String>[
      if (series.releaseYear != null) '${series.releaseYear}',
      if (series.genres.isNotEmpty) series.genres.take(2).join(' • '),
    ].join(' • ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Featured'),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            height: 286,
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
                          Colors.black.withValues(alpha: 0.08),
                          Colors.black.withValues(alpha: 0.18),
                          Colors.black.withValues(alpha: 0.88),
                        ],
                      ),
                    ),
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
                            color: Colors.white.withValues(alpha: 0.78),
                          ),
                        ),
                      if (metadata.isNotEmpty) const SizedBox(height: 6),
                      Text(
                        series.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          height: 1.05,
                        ),
                      ),
                      if ((series.originalTitle ?? '').trim().isNotEmpty &&
                          series.originalTitle != series.title) ...[
                        const SizedBox(height: 4),
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
                            color: Colors.white.withValues(alpha: 0.9),
                            height: 1.25,
                          ),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          FilledButton.icon(
                            onPressed: () =>
                                _openSeriesDetails(context, series),
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: const Text('Open Series'),
                          ),
                          TextButton(
                            onPressed: () => context.go(AppRoutePaths.browse),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Browse More'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DiscoverySection extends StatelessWidget {
  const _DiscoverySection({
    required this.featuredSeries,
    required this.browseCatalog,
  });

  final List<Series> featuredSeries;
  final AsyncValue<BrowseCatalogData> browseCatalog;

  @override
  Widget build(BuildContext context) {
    final browseData = browseCatalog.asData?.value;

    if (browseCatalog.isLoading && browseData == null) {
      return const _SectionLoadingState(title: 'Discover');
    }

    if (browseCatalog.hasError && browseData == null) {
      return const _SectionErrorState(
        title: 'Discover',
        message: 'Browse slices could not be loaded right now.',
      );
    }

    final sections = <Widget>[];
    if (browseData != null && browseData.latestReleases.isNotEmpty) {
      sections.add(
        _PosterRailSection(
          title: 'Latest Releases',
          seriesList: browseData.latestReleases,
          trailingLabel: 'Browse',
        ),
      );
    }
    if (browseData != null && browseData.trendingSeries.isNotEmpty) {
      sections.add(
        _PosterRailSection(
          title: 'Trending Ongoing',
          seriesList: browseData.trendingSeries,
        ),
      );
    }
    if (browseData != null && browseData.popularSeries.isNotEmpty) {
      sections.add(
        _PosterRailSection(
          title: 'Popular Catalog',
          seriesList: browseData.popularSeries,
        ),
      );
    }
    if (featuredSeries.isNotEmpty) {
      sections.add(
        _PosterRailSection(title: 'More to Start', seriesList: featuredSeries),
      );
    }

    if (sections.isEmpty) {
      return const _InlineEmptyState(
        title: 'Discovery is quiet',
        message: 'There are no additional rails to show right now.',
      );
    }

    return Column(
      children: [
        for (var index = 0; index < sections.length; index++) ...[
          if (index > 0) const SizedBox(height: 24),
          sections[index],
        ],
      ],
    );
  }
}

class _PosterRailSection extends StatelessWidget {
  const _PosterRailSection({
    required this.title,
    required this.seriesList,
    this.trailingLabel,
  });

  final String title;
  final List<Series> seriesList;
  final String? trailingLabel;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: title,
          trailing: trailingLabel == null
              ? null
              : TextButton(
                  onPressed: () => context.go(AppRoutePaths.browse),
                  child: Text(trailingLabel!),
                ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 228,
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
    ].join(' • ');

    return SizedBox(
      width: 144,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openSeriesDetails(context, series),
          borderRadius: BorderRadius.circular(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: AspectRatio(
                    aspectRatio: 2 / 3,
                    child: AnimeCachedArtwork(
                      imageUrl: series.posterImageUrl,
                      label: series.title,
                      icon: Icons.movie_creation_outlined,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                series.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall,
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
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
        trailing ?? const SizedBox.shrink(),
      ],
    );
  }
}

class _SectionLoadingState extends StatelessWidget {
  const _SectionLoadingState({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: title),
        const SizedBox(height: 10),
        const SizedBox(
          height: 168,
          child: Center(child: CircularProgressIndicator()),
        ),
      ],
    );
  }
}

class _SectionErrorState extends StatelessWidget {
  const _SectionErrorState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: title),
        const SizedBox(height: 10),
        _InlineEmptyState(title: 'Unavailable', message: message),
      ],
    );
  }
}

class _InlineEmptyState extends StatelessWidget {
  const _InlineEmptyState({required this.title, required this.message});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
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
