import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutePaths.browse),
            tooltip: 'Browse catalog',
            icon: const Icon(Icons.grid_view_rounded),
          ),
          IconButton(
            onPressed: () => context.push(AppRoutePaths.history),
            tooltip: 'Watch history',
            icon: const Icon(Icons.history_rounded),
          ),
          IconButton(
            onPressed: () => context.push(AppRoutePaths.watchlist),
            tooltip: 'Watchlist',
            icon: const Icon(Icons.bookmark_outline_rounded),
          ),
        ],
      ),
      body: featuredSeries.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed to load featured series.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (seriesList) => _HomeDiscoveryView(
          seriesList: seriesList,
          continueWatching: continueWatching,
        ),
      ),
    );
  }
}

class _HomeDiscoveryView extends StatelessWidget {
  const _HomeDiscoveryView({
    required this.seriesList,
    required this.continueWatching,
  });

  final List<Series> seriesList;
  final AsyncValue<List<HomeContinueWatchingItem>> continueWatching;

  @override
  Widget build(BuildContext context) {
    final featuredSpotlight = seriesList.isEmpty ? null : seriesList.first;
    final discoverySeries = seriesList.length <= 1
        ? const <Series>[]
        : seriesList.sublist(1);
    final hasContinueWatchingEntries =
        continueWatching.asData?.value.isNotEmpty == true;
    final isContinueWatchingLoading = continueWatching.isLoading;
    final hasContinueWatchingError = continueWatching.hasError;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        if (hasContinueWatchingEntries || isContinueWatchingLoading) ...[
          _ContinueWatchingSection(continueWatching: continueWatching),
          const SizedBox(height: 32),
        ],
        if (featuredSpotlight == null)
          const _DiscoveryUnavailableSection()
        else ...[
          _FeaturedSpotlightSection(
            series: featuredSpotlight,
            featuredCount: seriesList.length,
          ),
          if (!hasContinueWatchingEntries && hasContinueWatchingError) ...[
            const SizedBox(height: 32),
            _ContinueWatchingSection(continueWatching: continueWatching),
          ],
          if (discoverySeries.isNotEmpty) ...[
            const SizedBox(height: 32),
            _FeaturedCatalogSection(
              seriesList: discoverySeries,
              totalFeaturedCount: seriesList.length,
            ),
          ],
        ],
      ],
    );
  }
}

class _ContinueWatchingSection extends StatelessWidget {
  const _ContinueWatchingSection({required this.continueWatching});

  final AsyncValue<List<HomeContinueWatchingItem>> continueWatching;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return continueWatching.when(
      loading: () => _SectionBlock(
        title: 'Continue Watching',
        description:
            'Pick up where you left off and jump straight back into playback.',
        trailing: const _SectionCountBadge(label: 'Loading'),
        child: const _SurfaceCard(
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Checking saved watch progress for resume-ready episodes.',
                ),
              ),
            ],
          ),
        ),
      ),
      error: (error, stackTrace) => _SectionBlock(
        title: 'Continue Watching',
        description:
            'Pick up where you left off and jump straight back into playback.',
        child: _SurfaceCard(
          child: Text('Saved watch state could not be loaded.\n$error'),
        ),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return const SizedBox.shrink();
        }

        return _SectionBlock(
          title: 'Continue Watching',
          description:
              'Resume in-progress episodes from the exact watch flow you already started.',
          trailing: _SectionCountBadge(label: '${entries.length} ready'),
          child: _SurfaceCard(
            backgroundColor: theme.colorScheme.primaryContainer.withValues(
              alpha: 0.14,
            ),
            child: Column(
              children: [
                for (var index = 0; index < entries.length; index++) ...[
                  if (index > 0) const Divider(height: 1),
                  _ContinueWatchingRow(item: entries[index]),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ContinueWatchingRow extends StatelessWidget {
  const _ContinueWatchingRow({required this.item});

  final HomeContinueWatchingItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progressPercent = item.progressFraction == null
        ? null
        : '${(item.progressFraction! * 100).round()}% watched';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openContinueWatchingEntry(context, item),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ArtworkThumbnail(
                imageUrl: item.seriesPosterImageUrl,
                width: 76,
                aspectRatio: 2 / 3,
                fallbackLabel: 'No poster',
                icon: Icons.movie_creation_outlined,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetaBadge(
                          label: 'Resume in player',
                          color: theme.colorScheme.primary,
                        ),
                        _MetaBadge(
                          label: item.episodeLabel,
                          color: theme.colorScheme.secondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(item.seriesTitle, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 3),
                    Text(
                      item.episodeTitle,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.progressLabel,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        if (progressPercent != null) ...[
                          const SizedBox(width: 12),
                          Text(
                            progressPercent,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (item.progressFraction != null) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: item.progressFraction,
                          minHeight: 6,
                        ),
                      ),
                    ],
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        FilledButton.tonalIcon(
                          onPressed: () =>
                              _openContinueWatchingEntry(context, item),
                          icon: const Icon(Icons.play_arrow_rounded),
                          label: const Text('Resume Episode'),
                        ),
                        TextButton(
                          onPressed: () =>
                              _openContinueWatchingSeries(context, item),
                          child: const Text('Open Series'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Resume opens playback from your saved position.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
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

class _MetaBadge extends StatelessWidget {
  const _MetaBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color),
      ),
    );
  }
}

class _SectionCountBadge extends StatelessWidget {
  const _SectionCountBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

void _openContinueWatchingSeries(
  BuildContext context,
  HomeContinueWatchingItem item,
) {
  context.push(AppRoutePaths.seriesDetails(item.playerContext.seriesId));
}

class _FeaturedSpotlightSection extends StatelessWidget {
  const _FeaturedSpotlightSection({
    required this.series,
    required this.featuredCount,
  });

  final Series series;
  final int featuredCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metadata = <String>[
      if (series.releaseYear != null) '${series.releaseYear}',
      if (series.genres.isNotEmpty) series.genres.take(2).join(' • '),
    ].join('  •  ');

    return _SectionBlock(
      title: 'Featured Pick',
      description: 'A highlighted series to jump into from Home right now.',
      trailing: Text(
        '$featuredCount featured',
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.primary,
        ),
      ),
      child: _SurfaceCard(
        backgroundColor: theme.colorScheme.surfaceContainerLow,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ArtworkHero(
              imageUrl: series.bannerImageUrl ?? series.posterImageUrl,
              fallbackLabel: series.title,
              icon: Icons.live_tv_rounded,
            ),
            const SizedBox(height: 16),
            Text(series.title, style: theme.textTheme.titleLarge),
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
              const SizedBox(height: 8),
              Text(
                metadata,
                style: theme.textTheme.bodySmall?.copyWith(
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
            FilledButton.icon(
              onPressed: () => _openSeriesDetails(context, series),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Open Series'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturedCatalogSection extends StatelessWidget {
  const _FeaturedCatalogSection({
    required this.seriesList,
    required this.totalFeaturedCount,
  });

  final List<Series> seriesList;
  final int totalFeaturedCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _SectionBlock(
      title: 'More to Explore',
      description: 'More featured series currently available on Home.',
      trailing: Text(
        '${seriesList.length} of $totalFeaturedCount',
        style: theme.textTheme.labelLarge?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
      child: _SurfaceCard(
        child: Column(
          children: [
            for (var index = 0; index < seriesList.length; index++) ...[
              if (index > 0) const Divider(height: 1),
              _SeriesRow(series: seriesList[index]),
            ],
          ],
        ),
      ),
    );
  }
}

class _SeriesRow extends StatelessWidget {
  const _SeriesRow({required this.series});

  final Series series;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metadata = <String>[
      if (series.releaseYear != null) '${series.releaseYear}',
      if (series.genres.isNotEmpty) series.genres.first,
    ].join('  •  ');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openSeriesDetails(context, series),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ArtworkThumbnail(
                imageUrl: series.posterImageUrl,
                width: 56,
                aspectRatio: 2 / 3,
                fallbackLabel: 'No poster',
                icon: Icons.photo_outlined,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(series.title, style: theme.textTheme.titleMedium),
                    if ((series.originalTitle ?? '').trim().isNotEmpty &&
                        series.originalTitle != series.title) ...[
                      const SizedBox(height: 2),
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

class _ArtworkHero extends StatelessWidget {
  const _ArtworkHero({
    required this.imageUrl,
    required this.fallbackLabel,
    required this.icon,
  });

  final String? imageUrl;
  final String fallbackLabel;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: _ArtworkImage(
          imageUrl: imageUrl,
          fallbackLabel: fallbackLabel,
          icon: icon,
          alignment: Alignment.topCenter,
        ),
      ),
    );
  }
}

class _ArtworkThumbnail extends StatelessWidget {
  const _ArtworkThumbnail({
    required this.imageUrl,
    required this.width,
    required this.aspectRatio,
    required this.fallbackLabel,
    required this.icon,
  });

  final String? imageUrl;
  final double width;
  final double aspectRatio;
  final String fallbackLabel;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: width,
        child: AspectRatio(
          aspectRatio: aspectRatio,
          child: _ArtworkImage(
            imageUrl: imageUrl,
            fallbackLabel: fallbackLabel,
            icon: icon,
          ),
        ),
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

class _DiscoveryUnavailableSection extends StatelessWidget {
  const _DiscoveryUnavailableSection();

  @override
  Widget build(BuildContext context) {
    return const _SectionBlock(
      title: 'Featured Discovery',
      description: 'Home can surface featured series when they are available.',
      child: _SurfaceCard(
        child: Text('No featured series are available right now.'),
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

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child, this.backgroundColor});

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
