import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/browse/browse_providers.dart';
import '../../app/router/app_router.dart';
import '../../domain/models/series.dart';

class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key});

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  BrowseDiscoveryMode _selectedMode = BrowseDiscoveryMode.all;

  void _selectMode(BrowseDiscoveryMode mode) {
    if (mode == _selectedMode) {
      return;
    }

    setState(() {
      _selectedMode = mode;
    });
  }

  @override
  Widget build(BuildContext context) {
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
        data: (catalog) => _BrowseDiscoveryView(
          catalog: catalog,
          selectedMode: _selectedMode,
          onSelectMode: _selectMode,
        ),
      ),
    );
  }
}

enum BrowseDiscoveryMode { all, latest, trending, popular }

class _BrowseDiscoveryView extends StatelessWidget {
  const _BrowseDiscoveryView({
    required this.catalog,
    required this.selectedMode,
    required this.onSelectMode,
  });

  final BrowseCatalogData catalog;
  final BrowseDiscoveryMode selectedMode;
  final ValueChanged<BrowseDiscoveryMode> onSelectMode;

  @override
  Widget build(BuildContext context) {
    final sections = _buildSections(catalog);
    final selectedSection = switch (selectedMode) {
      BrowseDiscoveryMode.latest => sections.firstWhere(
        (section) => section.mode == BrowseDiscoveryMode.latest,
      ),
      BrowseDiscoveryMode.trending => sections.firstWhere(
        (section) => section.mode == BrowseDiscoveryMode.trending,
      ),
      BrowseDiscoveryMode.popular => sections.firstWhere(
        (section) => section.mode == BrowseDiscoveryMode.popular,
      ),
      BrowseDiscoveryMode.all => null,
    };

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        _BrowseHeaderCard(selectedMode: selectedMode),
        const SizedBox(height: 16),
        _BrowseModeSelector(
          selectedMode: selectedMode,
          onSelectMode: onSelectMode,
        ),
        const SizedBox(height: 24),
        if (!catalog.hasAnyContent)
          const _BrowseEmptyState()
        else if (selectedSection == null)
          _BrowseAllDiscoveryBody(
            sections: sections,
            onSelectMode: onSelectMode,
          )
        else
          _BrowseFocusedDiscoveryBody(
            section: selectedSection,
            onSelectMode: onSelectMode,
          ),
      ],
    );
  }

  List<_BrowseSectionData> _buildSections(BrowseCatalogData catalog) {
    return [
      _BrowseSectionData(
        mode: BrowseDiscoveryMode.latest,
        title: 'Latest Releases',
        description:
            'Most recently surfaced releases from the current catalog feed.',
        emphasis:
            'Use this when you want the freshest currently surfaced discovery slice.',
        seriesList: catalog.latestReleases,
      ),
      _BrowseSectionData(
        mode: BrowseDiscoveryMode.trending,
        title: 'Trending Ongoing',
        description:
            'Ongoing titles currently ordered by fresh release activity.',
        emphasis:
            'Use this when you want active, still-moving anime rather than the broader catalog.',
        seriesList: catalog.trendingSeries,
      ),
      _BrowseSectionData(
        mode: BrowseDiscoveryMode.popular,
        title: 'Popular Catalog',
        description:
            'Titles currently surfaced from rating-sorted catalog discovery.',
        emphasis:
            'Use this when you want stronger general catalog picks rather than only the newest releases.',
        seriesList: catalog.popularSeries,
      ),
    ];
  }
}

class _BrowseHeaderCard extends StatelessWidget {
  const _BrowseHeaderCard({required this.selectedMode});

  final BrowseDiscoveryMode selectedMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final helperText = switch (selectedMode) {
      BrowseDiscoveryMode.all =>
        'Browse is now a primary exploration surface. Move across the real discovery slices that the repository already supports.',
      BrowseDiscoveryMode.latest =>
        'Focused on latest surfaced releases so you can scan the freshest discovery slice without leaving Browse.',
      BrowseDiscoveryMode.trending =>
        'Focused on currently active ongoing titles ordered by fresh release activity.',
      BrowseDiscoveryMode.popular =>
        'Focused on broader rating-sorted catalog discovery for stronger general picks.',
    };

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
            Text('Browse Anime', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              helperText,
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
                  label: 'Real discovery slices',
                  color: theme.colorScheme.primary,
                ),
                _BrowseHintChip(
                  label: 'No fake genres',
                  color: theme.colorScheme.secondary,
                ),
                _BrowseHintChip(
                  label: 'Catalog remains deeper listing',
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

class _BrowseModeSelector extends StatelessWidget {
  const _BrowseModeSelector({
    required this.selectedMode,
    required this.onSelectMode,
  });

  final BrowseDiscoveryMode selectedMode;
  final ValueChanged<BrowseDiscoveryMode> onSelectMode;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final mode in BrowseDiscoveryMode.values)
          ChoiceChip(
            selected: selectedMode == mode,
            label: Text(_labelForMode(mode)),
            onSelected: (_) => onSelectMode(mode),
          ),
      ],
    );
  }

  String _labelForMode(BrowseDiscoveryMode mode) {
    return switch (mode) {
      BrowseDiscoveryMode.all => 'All discovery',
      BrowseDiscoveryMode.latest => 'Latest',
      BrowseDiscoveryMode.trending => 'Trending',
      BrowseDiscoveryMode.popular => 'Popular',
    };
  }
}

class _BrowseAllDiscoveryBody extends StatelessWidget {
  const _BrowseAllDiscoveryBody({
    required this.sections,
    required this.onSelectMode,
  });

  final List<_BrowseSectionData> sections;
  final ValueChanged<BrowseDiscoveryMode> onSelectMode;

  @override
  Widget build(BuildContext context) {
    final spotlightSection = sections.firstWhere(
      (section) => section.seriesList.isNotEmpty,
      orElse: () => sections.first,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (spotlightSection.seriesList.isNotEmpty) ...[
          _BrowseSpotlightCard(
            section: spotlightSection,
            series: spotlightSection.seriesList.first,
            onOpenMode: () => onSelectMode(spotlightSection.mode),
          ),
          const SizedBox(height: 24),
        ],
        for (final section in sections) ...[
          if (section.seriesList.isNotEmpty) ...[
            _BrowseRailSection(
              section: section,
              onOpenMode: () => onSelectMode(section.mode),
            ),
            const SizedBox(height: 24),
          ],
        ],
      ],
    );
  }
}

class _BrowseFocusedDiscoveryBody extends StatelessWidget {
  const _BrowseFocusedDiscoveryBody({
    required this.section,
    required this.onSelectMode,
  });

  final _BrowseSectionData section;
  final ValueChanged<BrowseDiscoveryMode> onSelectMode;

  @override
  Widget build(BuildContext context) {
    final featuredSeries = section.seriesList.isEmpty ? null : section.seriesList.first;
    final remainingSeries = section.seriesList.length <= 1
        ? const <Series>[]
        : section.seriesList.sublist(1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _FocusedSectionHeader(
          section: section,
          onShowAllModes: () => onSelectMode(BrowseDiscoveryMode.all),
        ),
        const SizedBox(height: 16),
        if (featuredSeries != null) ...[
          _BrowseSpotlightCard(
            section: section,
            series: featuredSeries,
            onOpenMode: () => onSelectMode(BrowseDiscoveryMode.all),
            ctaLabel: 'Back to all discovery views',
          ),
          const SizedBox(height: 24),
        ],
        if (remainingSeries.isEmpty && featuredSeries != null)
          const _FocusedBrowseEmptyRemainder()
        else if (section.seriesList.isEmpty)
          const _BrowseEmptyState()
        else
          _BrowseSeriesGrid(seriesList: remainingSeries.isEmpty ? section.seriesList : remainingSeries),
      ],
    );
  }
}

class _FocusedSectionHeader extends StatelessWidget {
  const _FocusedSectionHeader({
    required this.section,
    required this.onShowAllModes,
  });

  final _BrowseSectionData section;
  final VoidCallback onShowAllModes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(section.title, style: theme.textTheme.titleLarge),
                      const SizedBox(height: 4),
                      Text(
                        section.description,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _BrowseHintChip(
                  label: '${section.seriesList.length} titles',
                  color: theme.colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              section.emphasis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onShowAllModes,
              icon: const Icon(Icons.dashboard_outlined),
              label: const Text('Back to all discovery views'),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrowseSpotlightCard extends StatelessWidget {
  const _BrowseSpotlightCard({
    required this.section,
    required this.series,
    required this.onOpenMode,
    this.ctaLabel,
  });

  final _BrowseSectionData section;
  final Series series;
  final VoidCallback onOpenMode;
  final String? ctaLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metadata = <String>[
      if (series.releaseYear != null) '${series.releaseYear}',
      if (series.genres.isNotEmpty) series.genres.take(2).join(' • '),
    ].join('  •  ');

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
            _BrowseHintChip(
              label: '${section.title} spotlight',
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            _BrowseHeroArtwork(
              imageUrl: series.bannerImageUrl ?? series.posterImageUrl,
              label: series.title,
            ),
            const SizedBox(height: 16),
            Text(series.title, style: theme.textTheme.headlineSmall),
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
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: () => context.push(AppRoutePaths.seriesDetails(series.id)),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Open Series'),
                ),
                TextButton.icon(
                  onPressed: onOpenMode,
                  icon: const Icon(Icons.explore_outlined),
                  label: Text(ctaLabel ?? 'Focus this discovery view'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BrowseRailSection extends StatelessWidget {
  const _BrowseRailSection({
    required this.section,
    required this.onOpenMode,
  });

  final _BrowseSectionData section;
  final VoidCallback onOpenMode;

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
                  Text(section.title, style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    section.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            TextButton(
              onPressed: onOpenMode,
              child: const Text('Focus'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 286,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: section.seriesList.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              return _BrowseRailCard(
                sectionTitle: section.title,
                series: section.seriesList[index],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _BrowseRailCard extends StatelessWidget {
  const _BrowseRailCard({
    required this.sectionTitle,
    required this.series,
  });

  final String sectionTitle;
  final Series series;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final metadata = <String>[
      if (series.releaseYear != null) '${series.releaseYear}',
      if (series.genres.isNotEmpty) series.genres.first,
    ].join('  •  ');

    return SizedBox(
      width: 180,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push(AppRoutePaths.seriesDetails(series.id)),
          child: Ink(
            decoration: BoxDecoration(
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BrowsePosterArtwork(
                    imageUrl: series.posterImageUrl,
                    label: series.title,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    series.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  if (metadata.isNotEmpty) ...[
                    const SizedBox(height: 6),
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
                    sectionTitle,
                    style: theme.textTheme.labelMedium?.copyWith(
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

class _BrowseSeriesGrid extends StatelessWidget {
  const _BrowseSeriesGrid({required this.seriesList});

  final List<Series> seriesList;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth >= 900
            ? 3
            : constraints.maxWidth >= 560
            ? 2
            : 1;

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: seriesList.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: crossAxisCount == 1 ? 2.6 : 0.78,
          ),
          itemBuilder: (context, index) {
            return _BrowseGridCard(series: seriesList[index]);
          },
        );
      },
    );
  }
}

class _BrowseGridCard extends StatelessWidget {
  const _BrowseGridCard({required this.series});

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
        borderRadius: BorderRadius.circular(16),
        onTap: () => context.push(AppRoutePaths.seriesDetails(series.id)),
        child: Ink(
          decoration: BoxDecoration(
            border: Border.all(color: theme.colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 320;

                if (!isWide) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _BrowsePosterArtwork(
                        imageUrl: series.posterImageUrl,
                        label: series.title,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        series.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium,
                      ),
                      if (metadata.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          metadata,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if ((series.synopsis ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          series.synopsis!,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
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
                  );
                }

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 110,
                      child: _BrowsePosterArtwork(
                        imageUrl: series.posterImageUrl,
                        label: series.title,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            series.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium,
                          ),
                          if ((series.originalTitle ?? '').trim().isNotEmpty &&
                              series.originalTitle != series.title) ...[
                            const SizedBox(height: 4),
                            Text(
                              series.originalTitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                          if (metadata.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              metadata,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                          if ((series.synopsis ?? '').trim().isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              series.synopsis!,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall,
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
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _BrowsePosterArtwork extends StatelessWidget {
  const _BrowsePosterArtwork({required this.imageUrl, required this.label});

  final String? imageUrl;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 2 / 3,
        child: _BrowseArtworkImage(
          imageUrl: imageUrl,
          label: label,
          icon: Icons.movie_creation_outlined,
        ),
      ),
    );
  }
}

class _BrowseHeroArtwork extends StatelessWidget {
  const _BrowseHeroArtwork({required this.imageUrl, required this.label});

  final String? imageUrl;
  final String label;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: _BrowseArtworkImage(
          imageUrl: imageUrl,
          label: label,
          icon: Icons.live_tv_rounded,
          alignment: Alignment.topCenter,
        ),
      ),
    );
  }
}

class _BrowseArtworkImage extends StatelessWidget {
  const _BrowseArtworkImage({
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
      return _BrowseArtworkFallback(label: label, icon: icon);
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
              _BrowseArtworkFallback(label: label, icon: icon),
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _BrowseArtworkFallback(label: label, icon: icon);
        },
      ),
    );
  }
}

class _BrowseArtworkFallback extends StatelessWidget {
  const _BrowseArtworkFallback({required this.label, required this.icon});

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
                'No browse slices are available right now.',
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

class _FocusedBrowseEmptyRemainder extends StatelessWidget {
  const _FocusedBrowseEmptyRemainder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nothing else in this slice yet', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              'The spotlight title is currently the only surfaced result in this discovery view.',
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

class _BrowseSectionData {
  const _BrowseSectionData({
    required this.mode,
    required this.title,
    required this.description,
    required this.emphasis,
    required this.seriesList,
  });

  final BrowseDiscoveryMode mode;
  final String title;
  final String description;
  final String emphasis;
  final List<Series> seriesList;
}
