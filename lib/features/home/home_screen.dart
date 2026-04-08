import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/home/home_continue_watching.dart';
import '../../app/home/home_discovery.dart';
import '../../app/router/app_router.dart';
import '../../domain/models/series.dart';
import '../../shared/widgets/anime_cached_artwork.dart';
import '../../shared/widgets/media_overlay_pill.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final continueWatching = ref.watch(homeContinueWatchingProvider);
    final homeDiscovery = ref.watch(homeDiscoveryProvider);
    Future<void> handleRefresh() async {
      await Future.wait<Object?>([
        ref.refresh(homeContinueWatchingProvider.future),
        ref.refresh(homeDiscoveryProvider.future),
      ]);
    }

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
        continueWatching: continueWatching,
        homeDiscovery: homeDiscovery,
        onRefresh: handleRefresh,
      ),
    );
  }
}

class _HomeLaunchSurface extends StatelessWidget {
  const _HomeLaunchSurface({
    required this.continueWatching,
    required this.homeDiscovery,
    required this.onRefresh,
  });

  final AsyncValue<List<HomeContinueWatchingItem>> continueWatching;
  final AsyncValue<HomeDiscoveryData> homeDiscovery;
  final RefreshCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final continueWatchingData =
        continueWatching.asData?.value ?? const <HomeContinueWatchingItem>[];
    final discoveryData = homeDiscovery.asData?.value;
    final latestReleases = discoveryData?.latestReleases ?? const <Series>[];
    final hasInitialContent =
        continueWatchingData.isNotEmpty ||
        (discoveryData?.hasAnyContent ?? false);
    final isInitialLoading = !hasInitialContent && homeDiscovery.isLoading;
    final hideContinueWatching =
        continueWatchingData.isEmpty &&
        !continueWatching.isLoading &&
        !continueWatching.hasError;

    if (isInitialLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          if (!hideContinueWatching) ...[
            _ContinueWatchingSection(continueWatching: continueWatching),
            const SizedBox(height: 24),
          ],
          if (homeDiscovery.isLoading && discoveryData == null)
            const _SectionLoadingState(title: 'Latest Spotlight')
          else if (homeDiscovery.hasError && discoveryData == null)
            const _SectionErrorState(
              title: 'Latest Spotlight',
              message: 'Home discovery could not be loaded right now.',
            )
          else if (latestReleases.isNotEmpty)
            _LatestSpotlightHero(series: latestReleases.first)
          else if ((discoveryData?.latestError ?? '').trim().isNotEmpty)
            const _SectionErrorState(
              title: 'Latest Spotlight',
              message: 'Latest releases could not be loaded right now.',
            )
          else
            const _InlineEmptyState(
              title: 'Latest release unavailable',
              message:
                  'Home will surface a latest release spotlight when discovery resolves one.',
            ),
          const SizedBox(height: 28),
          _DiscoverySection(
            latestReleases: latestReleases.skip(1).toList(growable: false),
            homeDiscovery: homeDiscovery,
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
          return const SizedBox.shrink();
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
              height: 244,
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
      width: 176,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openContinueWatchingEntry(context, item),
          borderRadius: BorderRadius.circular(18),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
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
                          Colors.black.withValues(alpha: 0.14),
                          Colors.black.withValues(alpha: 0.9),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  top: 12,
                  child: MediaOverlayPill(
                    label: item.episodeLabel,
                    icon: Icons.play_circle_fill_rounded,
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
                        item.seriesTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          height: 1.08,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.episodeTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: item.progressFraction ?? 0,
                          minHeight: 5,
                          backgroundColor: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.progressLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LatestSpotlightHero extends StatelessWidget {
  const _LatestSpotlightHero({required this.series});

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
        const _SectionHeader(title: 'Latest Spotlight'),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            height: 332,
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
                          Colors.black.withValues(alpha: 0.18),
                          Colors.black.withValues(alpha: 0.93),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 16,
                  top: 16,
                  child: MediaOverlayPill(
                    label: 'Latest release',
                    icon: Icons.star_rounded,
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
                        style: theme.textTheme.headlineMedium?.copyWith(
                          color: Colors.white,
                          height: 1.02,
                          fontWeight: FontWeight.w800,
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
                        const SizedBox(height: 10),
                        Text(
                          series.synopsis!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.92),
                            height: 1.28,
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
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
                            child: const Text('Browse latest'),
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
    required this.latestReleases,
    required this.homeDiscovery,
  });

  final List<Series> latestReleases;
  final AsyncValue<HomeDiscoveryData> homeDiscovery;

  @override
  Widget build(BuildContext context) {
    final discoveryData = homeDiscovery.asData?.value;

    if (homeDiscovery.isLoading && discoveryData == null) {
      return const _SectionLoadingState(title: 'Discover');
    }

    if (homeDiscovery.hasError && discoveryData == null) {
      return const _SectionErrorState(
        title: 'Discover',
        message: 'Home discovery slices could not be loaded right now.',
      );
    }

    final sections = <Widget>[];
    if (discoveryData != null && discoveryData.trendingSeries.isNotEmpty) {
      sections.add(
        _PosterRailSection(
          title: 'Trending now',
          seriesList: discoveryData.trendingSeries,
        ),
      );
    }
    if (discoveryData != null && discoveryData.popularSeries.isNotEmpty) {
      sections.add(
        _PosterRailSection(
          title: 'Popular Catalog',
          seriesList: discoveryData.popularSeries,
        ),
      );
    }
    if (latestReleases.isNotEmpty) {
      sections.add(
        _PosterRailSection(
          title: 'More recent releases',
          seriesList: latestReleases,
          trailingLabel: 'Browse',
        ),
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
          if (index > 0) const SizedBox(height: 26),
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
          height: 240,
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
      width: 150,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openSeriesDetails(context, series),
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
                          Colors.black.withValues(alpha: 0.88),
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
