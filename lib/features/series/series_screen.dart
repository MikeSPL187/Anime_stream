import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/downloads/downloads_providers.dart';
import '../../app/router/app_router.dart';
import '../../app/series/series_details_data.dart';
import '../../app/series/series_providers.dart';
import '../../app/watch/watch_state_operation_providers.dart';
import '../../app/watchlist/watchlist_providers.dart';
import '../../domain/models/download_entry.dart';
import '../../domain/models/episode.dart';
import '../../domain/models/episode_progress.dart';
import '../../domain/models/series.dart';
import '../player/player_screen_context.dart';

class SeriesScreen extends ConsumerWidget {
  const SeriesScreen({super.key, required this.seriesId});

  final String seriesId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seriesDetails = ref.watch(seriesDetailsProvider(seriesId));

    return Scaffold(
      appBar: AppBar(title: const Text('Series')),
      body: seriesDetails.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Failed to load series $seriesId.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (details) => _SeriesPage(details: details),
      ),
    );
  }
}

class _SeriesPage extends StatelessWidget {
  const _SeriesPage({required this.details});

  final SeriesDetailsData details;

  @override
  Widget build(BuildContext context) {
    final series = details.series;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        _IdentityHeroSection(details: details),
        const SizedBox(height: 16),
        _PrimaryWatchActionSection(details: details),
        const SizedBox(height: 16),
        _SaveIntentSection(series: series),
        const SizedBox(height: 24),
        _EpisodesSection(details: details),
        const SizedBox(height: 24),
        _MetadataSection(series: series, episodeCount: details.episodes.length),
        if ((series.synopsis ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          _SynopsisSection(synopsis: series.synopsis!.trim()),
        ],
      ],
    );
  }
}

class _IdentityHeroSection extends StatelessWidget {
  const _IdentityHeroSection({required this.details});

  final SeriesDetailsData details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final series = details.series;
    final metadata = <String>[
      if (series.releaseYear != null) '${series.releaseYear}',
      if (series.genres.isNotEmpty) series.genres.take(2).join(' • '),
      '${details.episodes.length} episodes',
    ].join('  •  ');
    final stats = <_HeroStat>[
      _HeroStat(
        label: 'In progress',
        value: '${details.inProgressEpisodeCount}',
        color: theme.colorScheme.primary,
      ),
      _HeroStat(
        label: 'Completed',
        value: '${details.completedEpisodeCount}',
        color: theme.colorScheme.tertiary,
      ),
      _HeroStat(
        label: 'Available',
        value: '${details.episodes.length}',
        color: theme.colorScheme.secondary,
      ),
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HeroBannerArtwork(
              imageUrl: series.bannerImageUrl ?? series.posterImageUrl,
              fallbackLabel: series.title,
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _IdentityPoster(
                  imageUrl: series.posterImageUrl,
                  fallbackLabel: series.title,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeroTag(
                        label: 'Series hub',
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        series.title,
                        style: theme.textTheme.headlineMedium,
                      ),
                      if ((series.originalTitle ?? '').trim().isNotEmpty &&
                          series.originalTitle != series.title) ...[
                        const SizedBox(height: 6),
                        Text(
                          series.originalTitle!,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (metadata.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          metadata,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: stats
                  .map((stat) => _HeroStatCard(stat: stat))
                  .toList(growable: false),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryWatchActionSection extends StatelessWidget {
  const _PrimaryWatchActionSection({required this.details});

  final SeriesDetailsData details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final action = details.primaryWatchAction;
    final targetEpisode = action.targetEpisode;
    final latestProgress = details.latestProgress;
    final latestProgressEpisode = latestProgress == null
        ? null
        : details.episodeForProgress(latestProgress);
    final supportingText = switch (action.kind) {
      SeriesPrimaryWatchActionKind.resumeEpisode when targetEpisode != null =>
        'Continue from Episode ${targetEpisode.numberLabel} • ${targetEpisode.title}',
      SeriesPrimaryWatchActionKind.continueEpisode when targetEpisode != null =>
        'Up next: Episode ${targetEpisode.numberLabel} • ${targetEpisode.title}',
      SeriesPrimaryWatchActionKind.startWatching when targetEpisode != null =>
        'Begin with Episode ${targetEpisode.numberLabel} • ${targetEpisode.title}',
      SeriesPrimaryWatchActionKind.endOfAvailableContent =>
        'You have completed all currently available episodes for this series.',
      SeriesPrimaryWatchActionKind.unavailable =>
        'Episodes are not available yet.',
      _ => 'A playable episode is not available yet.',
    };
    final actionBadge = switch (action.kind) {
      SeriesPrimaryWatchActionKind.resumeEpisode => (
        label: 'Resume',
        color: theme.colorScheme.primary,
      ),
      SeriesPrimaryWatchActionKind.continueEpisode => (
        label: 'Up next',
        color: theme.colorScheme.secondary,
      ),
      SeriesPrimaryWatchActionKind.startWatching => (
        label: 'Start',
        color: theme.colorScheme.primary,
      ),
      SeriesPrimaryWatchActionKind.endOfAvailableContent => (
        label: 'Up to date',
        color: theme.colorScheme.tertiary,
      ),
      SeriesPrimaryWatchActionKind.unavailable => (
        label: 'Unavailable',
        color: theme.colorScheme.error,
      ),
    };
    final latestActivityText = switch ((latestProgress, latestProgressEpisode)) {
      (final progress?, final episode?) when progress.isCompleted =>
        'Latest activity: completed Episode ${episode.numberLabel}',
      (final progress?, final episode?) =>
        'Latest activity: Episode ${episode.numberLabel} at ${_formatPlaybackPosition(progress.position)}',
      _ => 'Choose an episode below or start from the main action.',
    };
    final transitionText = switch (action.kind) {
      SeriesPrimaryWatchActionKind.endOfAvailableContent =>
        'Return here after playback to pick the next available episode or revisit earlier episodes.',
      SeriesPrimaryWatchActionKind.unavailable =>
        'This watch action stays unavailable until a playable episode exists.',
      _ =>
        'This action opens the player directly. Progress syncs back to this series and Continue Watching.',
    };

    return _SectionCard(
      title: 'Watch now',
      visualDensity: _SectionDensity.highlighted,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _WatchStateBadge(
                label: actionBadge.label,
                color: actionBadge.color,
              ),
              _WatchStateBadge(
                label: '${details.episodes.length} available',
                color: theme.colorScheme.secondary,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(action.label, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            supportingText,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          _WatchActionSummaryStrip(
            latestActivityText: latestActivityText,
            transitionText: transitionText,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: targetEpisode == null
                  ? null
                  : () => _openEpisodeInPlayer(
                      context,
                      series: details.series,
                      episode: targetEpisode,
                    ),
              icon: Icon(switch (action.kind) {
                SeriesPrimaryWatchActionKind.resumeEpisode =>
                  Icons.play_circle_fill_rounded,
                SeriesPrimaryWatchActionKind.continueEpisode =>
                  Icons.skip_next_rounded,
                SeriesPrimaryWatchActionKind.endOfAvailableContent =>
                  Icons.check_circle_outline_rounded,
                _ => Icons.play_arrow_rounded,
              }),
              label: Text(action.label),
            ),
          ),
        ],
      ),
    );
  }
}

class _WatchActionSummaryStrip extends StatelessWidget {
  const _WatchActionSummaryStrip({
    required this.latestActivityText,
    required this.transitionText,
  });

  final String latestActivityText;
  final String transitionText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.64),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              latestActivityText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              transitionText,
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

class _SaveIntentSection extends ConsumerWidget {
  const _SaveIntentSection({required this.series});

  final Series series;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final savedState = ref.watch(
      watchlistMembershipControllerProvider(series.id),
    );

    return _SectionCard(
      title: 'Save for later',
      child: savedState.when(
        loading: () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Checking whether this series is already saved in your Watchlist.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonalIcon(
              onPressed: null,
              icon: const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              label: const Text('Checking Watchlist'),
            ),
          ],
        ),
        error: (error, stackTrace) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'The saved-for-later state could not be loaded right now.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                ref.invalidate(
                  watchlistMembershipControllerProvider(series.id),
                );
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry Watchlist'),
            ),
          ],
        ),
        data: (isSaved) {
          if (isSaved) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _WatchStateBadge(
                  label: 'Saved for later',
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'This series is saved in Watchlist so you can return later outside active playback progress.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: () => ref
                          .read(
                            watchlistMembershipControllerProvider(
                              series.id,
                            ).notifier,
                          )
                          .removeFromWatchlist(),
                      icon: const Icon(Icons.bookmark_remove_rounded),
                      label: const Text('Remove from Watchlist'),
                    ),
                    TextButton.icon(
                      onPressed: () => context.push(AppRoutePaths.watchlist),
                      icon: const Icon(Icons.bookmarks_outlined),
                      label: const Text('Open Watchlist'),
                    ),
                  ],
                ),
              ],
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Save this series to Watchlist when you want to come back later without starting or continuing playback right now.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: () => ref
                    .read(
                      watchlistMembershipControllerProvider(series.id).notifier,
                    )
                    .addToWatchlist(),
                icon: const Icon(Icons.bookmark_add_rounded),
                label: const Text('Save to Watchlist'),
              ),
              const SizedBox(height: 10),
              Text(
                'Watchlist is separate from Continue Watching and only tracks saved intent.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MetadataSection extends StatelessWidget {
  const _MetadataSection({required this.series, required this.episodeCount});

  final Series series;
  final int episodeCount;

  @override
  Widget build(BuildContext context) {
    final metadata = <String>[
      if (series.releaseYear != null) 'Year ${series.releaseYear}',
      if (series.genres.isNotEmpty) series.genres.take(3).join(' • '),
      'Episodes $episodeCount',
    ];

    return _SectionCard(
      title: 'About this series',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: metadata
            .map(
              (item) => Chip(
                label: Text(item),
                visualDensity: VisualDensity.compact,
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _SynopsisSection extends StatelessWidget {
  const _SynopsisSection({required this.synopsis});

  final String synopsis;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(title: 'Story', child: Text(synopsis));
  }
}

class _EpisodesSection extends StatefulWidget {
  const _EpisodesSection({required this.details});

  final SeriesDetailsData details;

  @override
  State<_EpisodesSection> createState() => _EpisodesSectionState();
}

class _EpisodesSectionState extends State<_EpisodesSection> {
  _EpisodeListFilter _selectedFilter = _EpisodeListFilter.all;
  _EpisodeSortOrder _selectedSortOrder = _EpisodeSortOrder.oldestFirst;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = widget.details;
    final series = details.series;
    final episodes = details.episodes;
    final action = details.primaryWatchAction;
    final actionTargetEpisode = action.targetEpisode;
    final sectionSubtitle = switch (action.kind) {
      SeriesPrimaryWatchActionKind.resumeEpisode
          when actionTargetEpisode != null =>
        'Resume from Episode ${actionTargetEpisode.numberLabel} or manage the full episode list below.',
      SeriesPrimaryWatchActionKind.continueEpisode
          when actionTargetEpisode != null =>
        'Episode ${actionTargetEpisode.numberLabel} is next, or jump anywhere in the episode browser.',
      SeriesPrimaryWatchActionKind.startWatching
          when actionTargetEpisode != null =>
        'Start with Episode ${actionTargetEpisode.numberLabel} or manage the full episode list below.',
      SeriesPrimaryWatchActionKind.endOfAvailableContent =>
        'You are caught up. Revisit watched episodes or jump back into any available episode.',
      _ => 'Choose an episode from the list below.',
    };
    final sortedEpisodes = episodes.toList(growable: false)
      ..sort((left, right) => left.sortOrder.compareTo(right.sortOrder));
    final orderedEpisodes = _selectedSortOrder == _EpisodeSortOrder.oldestFirst
        ? sortedEpisodes
        : sortedEpisodes.reversed.toList(growable: false);
    final inProgressCount = details.inProgressEpisodeCount;
    final watchedCount = details.completedEpisodeCount;
    final unwatchedCount = sortedEpisodes.length - inProgressCount - watchedCount;
    final visibleEpisodes = orderedEpisodes
        .where((episode) => _matchesFilter(details, episode))
        .toList(growable: false);

    return _SectionCard(
      title: 'Episodes',
      trailing: _WatchSummaryChip(
        label: '${episodes.length} available',
        color: theme.colorScheme.primary,
      ),
      visualDensity: _SectionDensity.highlighted,
      child: episodes.isEmpty
          ? const Text('Episodes are not available yet.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _EpisodesSectionLead(
                  message: sectionSubtitle,
                  actionLabel:
                      'Tap an episode to open playback. Use filters, ordering, watch-state and offline actions without leaving the series hub.',
                ),
                const SizedBox(height: 16),
                _EpisodeBrowserControls(
                  selectedFilter: _selectedFilter,
                  selectedSortOrder: _selectedSortOrder,
                  onFilterSelected: (filter) {
                    if (filter == _selectedFilter) {
                      return;
                    }

                    setState(() {
                      _selectedFilter = filter;
                    });
                  },
                  onSortOrderSelected: (sortOrder) {
                    if (sortOrder == _selectedSortOrder) {
                      return;
                    }

                    setState(() {
                      _selectedSortOrder = sortOrder;
                    });
                  },
                  counts: {
                    _EpisodeListFilter.all: sortedEpisodes.length,
                    _EpisodeListFilter.continueWatching: inProgressCount,
                    _EpisodeListFilter.unwatched: unwatchedCount,
                    _EpisodeListFilter.watched: watchedCount,
                  },
                ),
                const SizedBox(height: 12),
                Text(
                  'Showing ${visibleEpisodes.length} of ${sortedEpisodes.length} episodes',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                if (visibleEpisodes.isEmpty)
                  _EpisodeBrowserEmptyState(filter: _selectedFilter)
                else
                  for (var index = 0; index < visibleEpisodes.length; index++) ...[
                    if (index > 0) const SizedBox(height: 12),
                    _EpisodeRow(
                      series: series,
                      episode: visibleEpisodes[index],
                      savedProgress: details.progressForEpisode(
                        visibleEpisodes[index].id,
                      ),
                      actionHint: _episodeActionHint(details, visibleEpisodes[index]),
                    ),
                  ],
              ],
            ),
    );
  }

  bool _matchesFilter(SeriesDetailsData details, Episode episode) {
    return switch (_selectedFilter) {
      _EpisodeListFilter.all => true,
      _EpisodeListFilter.continueWatching => details.isEpisodeInProgress(episode.id),
      _EpisodeListFilter.unwatched => !details.hasSavedProgress(episode.id),
      _EpisodeListFilter.watched => details.isEpisodeCompleted(episode.id),
    };
  }

  _EpisodeActionHint? _episodeActionHint(
    SeriesDetailsData details,
    Episode episode,
  ) {
    final action = details.primaryWatchAction;
    final targetEpisode = action.targetEpisode;
    if (targetEpisode == null || targetEpisode.id != episode.id) {
      return null;
    }

    return switch (action.kind) {
      SeriesPrimaryWatchActionKind.resumeEpisode => _EpisodeActionHint(
        label: 'Resume here',
        tone: _EpisodeActionHintTone.primary,
      ),
      SeriesPrimaryWatchActionKind.continueEpisode => _EpisodeActionHint(
        label: 'Up next',
        tone: _EpisodeActionHintTone.secondary,
      ),
      SeriesPrimaryWatchActionKind.startWatching => _EpisodeActionHint(
        label: 'Start here',
        tone: _EpisodeActionHintTone.primary,
      ),
      _ => null,
    };
  }
}

class _EpisodeBrowserControls extends StatelessWidget {
  const _EpisodeBrowserControls({
    required this.selectedFilter,
    required this.selectedSortOrder,
    required this.onFilterSelected,
    required this.onSortOrderSelected,
    required this.counts,
  });

  final _EpisodeListFilter selectedFilter;
  final _EpisodeSortOrder selectedSortOrder;
  final ValueChanged<_EpisodeListFilter> onFilterSelected;
  final ValueChanged<_EpisodeSortOrder> onSortOrderSelected;
  final Map<_EpisodeListFilter, int> counts;

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
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Episode browser', style: theme.textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              'Focus the list on your next watch decision or reverse the order for catch-up browsing.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final filter in _EpisodeListFilter.values)
                  ChoiceChip(
                    label: Text('${filter.label} (${counts[filter] ?? 0})'),
                    selected: filter == selectedFilter,
                    onSelected: (_) => onFilterSelected(filter),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final sortOrder in _EpisodeSortOrder.values)
                  ChoiceChip(
                    label: Text(sortOrder.label),
                    selected: sortOrder == selectedSortOrder,
                    onSelected: (_) => onSortOrderSelected(sortOrder),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EpisodeBrowserEmptyState extends StatelessWidget {
  const _EpisodeBrowserEmptyState({required this.filter});

  final _EpisodeListFilter filter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final message = switch (filter) {
      _EpisodeListFilter.all => 'No episodes are available right now.',
      _EpisodeListFilter.continueWatching =>
        'No episodes are currently in progress for this series.',
      _EpisodeListFilter.unwatched =>
        'Every available episode already has watch-state activity.',
      _EpisodeListFilter.watched =>
        'No episodes have been marked watched yet.',
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _EpisodeRow extends ConsumerWidget {
  const _EpisodeRow({
    required this.series,
    required this.episode,
    this.savedProgress,
    this.actionHint,
  });

  final Series series;
  final Episode episode;
  final EpisodeProgress? savedProgress;
  final _EpisodeActionHint? actionHint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final episodeLabel = 'Episode ${episode.numberLabel}';
    final resolvedTitle = episode.title.trim().isEmpty
        ? episodeLabel
        : episode.title;
    final subtitleParts = <String>[
      if (episode.duration != null) '${episode.duration!.inMinutes} min',
      if (episode.isRecap) 'Recap',
      if (episode.isFiller) 'Filler',
    ];
    final watchStatus = switch (savedProgress) {
      final progress? when progress.isCompleted == true => (
        label: 'Completed',
        color: theme.colorScheme.tertiary,
      ),
      _? => (label: 'In progress', color: theme.colorScheme.primary),
      _ => null,
    };
    final progressLabel = switch (savedProgress) {
      final progress? when progress.isCompleted => 'Watched',
      final progress? when progress.totalDuration != null =>
        '${_formatPlaybackPosition(progress.position)} / ${_formatPlaybackPosition(progress.totalDuration!)} watched',
      final progress? =>
        '${_formatPlaybackPosition(progress.position)} watched',
      _ => null,
    };
    final progressFraction = switch (savedProgress) {
      final progress? when progress.isCompleted => 1.0,
      final progress?
          when progress.totalDuration != null &&
              progress.totalDuration! > Duration.zero =>
        (progress.position.inMilliseconds /
                progress.totalDuration!.inMilliseconds)
            .clamp(0.0, 1.0)
            .toDouble(),
      _ => null,
    };
    final actionHintColor = switch (actionHint?.tone) {
      _EpisodeActionHintTone.secondary => theme.colorScheme.secondary,
      _EpisodeActionHintTone.primary => theme.colorScheme.primary,
      null => null,
    };

    final downloadKey = EpisodeDownloadKey(
      seriesId: series.id,
      episodeId: episode.id,
    );
    final downloadEntryAsync = ref.watch(
      episodeDownloadEntryProvider(downloadKey),
    );
    final downloadActionState = ref.watch(
      episodeDownloadActionControllerProvider(downloadKey),
    );
    final downloadEntry = downloadEntryAsync.asData?.value;
    final isMutatingDownload = downloadActionState.isLoading;
    final watchStateOperation = ref.watch(
      seriesWatchStateOperationsControllerProvider(series.id),
    );
    final isMutatingWatchState = watchStateOperation.isLoading;
    final isBusy = isMutatingDownload || isMutatingWatchState;

    final watchedMenuAction = savedProgress?.isCompleted == true
        ? _EpisodeRowMenuAction.markUnwatched
        : _EpisodeRowMenuAction.markWatched;
    final downloadMenuAction = switch (downloadEntry?.status) {
      DownloadStatus.completed => _EpisodeRowMenuAction.removeDownload,
      DownloadStatus.failed => _EpisodeRowMenuAction.retryDownload,
      DownloadStatus.paused => _EpisodeRowMenuAction.retryDownload,
      DownloadStatus.downloading => _EpisodeRowMenuAction.downloadInProgress,
      DownloadStatus.queued => _EpisodeRowMenuAction.downloadInProgress,
      null => _EpisodeRowMenuAction.downloadEpisode,
    };
    final downloadStatusPill = _downloadStatusPill(theme, downloadEntry);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: actionHint != null
            ? actionHintColor!.withValues(alpha: 0.08)
            : savedProgress != null
                ? theme.colorScheme.surfaceContainerLow
                : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: actionHint != null
              ? actionHintColor!.withValues(alpha: 0.3)
              : theme.colorScheme.outlineVariant,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: isBusy
              ? null
              : () {
                  _openEpisodeInPlayer(context, series: series, episode: episode);
                },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _EpisodeNumberTile(
                  numberLabel: episode.numberLabel,
                  color: actionHintColor ?? theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _EpisodeWatchStatus(
                            label: episodeLabel,
                            color: theme.colorScheme.secondary,
                          ),
                          if (actionHint != null)
                            _EpisodeWatchStatus(
                              label: actionHint!.label,
                              color: actionHintColor!,
                            ),
                          if (watchStatus != null)
                            _EpisodeWatchStatus(
                              label: watchStatus.label,
                              color: watchStatus.color,
                            ),
                    ?downloadStatusPill,
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(resolvedTitle, style: theme.textTheme.titleMedium),
                      if (progressLabel != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          progressLabel,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (progressFraction != null) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: progressFraction,
                            minHeight: 6,
                          ),
                        ),
                      ],
                      if (subtitleParts.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          subtitleParts.join('  •  '),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if ((episode.synopsis ?? '').trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          episode.synopsis!,
                          style: theme.textTheme.bodyMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          FilledButton.tonalIcon(
                            onPressed: isBusy
                                ? null
                                : () => _openEpisodeInPlayer(
                                      context,
                                      series: series,
                                      episode: episode,
                                    ),
                            icon: Icon(
                              downloadEntry?.isPlayableOffline == true
                                  ? Icons.offline_pin_rounded
                                  : Icons.play_arrow_rounded,
                            ),
                            label: Text(
                              downloadEntry?.isPlayableOffline == true
                                  ? 'Play offline'
                                  : 'Play episode',
                            ),
                          ),
                          if (savedProgress?.isCompleted == true)
                            _EpisodeInfoPill(
                              label: 'Marked watched',
                              color: theme.colorScheme.tertiary,
                            )
                          else if (savedProgress != null)
                            _EpisodeInfoPill(
                              label: 'Resume-ready',
                              color: theme.colorScheme.primary,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<_EpisodeRowMenuAction>(
                  enabled: !isBusy,
                  tooltip: 'Episode actions',
                  onSelected: (action) async {
                    await _handleEpisodeMenuAction(
                      context,
                      ref,
                      action,
                      downloadKey: downloadKey,
                      downloadEntry: downloadEntry,
                    );
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem<_EpisodeRowMenuAction>(
                      value: _EpisodeRowMenuAction.play,
                      child: Text('Play episode'),
                    ),
                    PopupMenuItem<_EpisodeRowMenuAction>(
                      value: downloadMenuAction,
                      enabled: downloadMenuAction !=
                          _EpisodeRowMenuAction.downloadInProgress,
                      child: Text(downloadMenuAction.label),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem<_EpisodeRowMenuAction>(
                      value: watchedMenuAction,
                      child: Text(watchedMenuAction.label),
                    ),
                  ],
                  icon: isBusy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          Icons.more_vert_rounded,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget? _downloadStatusPill(ThemeData theme, DownloadEntry? entry) {
    return switch (entry?.status) {
      DownloadStatus.completed => _EpisodeWatchStatus(
          label: 'Available offline',
          color: theme.colorScheme.primary,
        ),
      DownloadStatus.downloading => _EpisodeWatchStatus(
          label: 'Downloading',
          color: theme.colorScheme.secondary,
        ),
      DownloadStatus.queued => _EpisodeWatchStatus(
          label: 'Queued',
          color: theme.colorScheme.secondary,
        ),
      DownloadStatus.failed => _EpisodeWatchStatus(
          label: 'Download failed',
          color: theme.colorScheme.error,
        ),
      DownloadStatus.paused => _EpisodeWatchStatus(
          label: 'Download paused',
          color: theme.colorScheme.tertiary,
        ),
      null => null,
    };
  }

  Future<void> _handleEpisodeMenuAction(
    BuildContext context,
    WidgetRef ref,
    _EpisodeRowMenuAction action, {
    required EpisodeDownloadKey downloadKey,
    required DownloadEntry? downloadEntry,
  }) async {
    if (action == _EpisodeRowMenuAction.play) {
      _openEpisodeInPlayer(context, series: series, episode: episode);
      return;
    }

    final watchController = ref.read(
      seriesWatchStateOperationsControllerProvider(series.id).notifier,
    );
    final downloadController = ref.read(
      episodeDownloadActionControllerProvider(downloadKey).notifier,
    );

    try {
      switch (action) {
        case _EpisodeRowMenuAction.play:
        case _EpisodeRowMenuAction.downloadInProgress:
          return;
        case _EpisodeRowMenuAction.markWatched:
          await watchController.markEpisodeWatched(episode.id);
          break;
        case _EpisodeRowMenuAction.markUnwatched:
          await watchController.markEpisodeUnwatched(episode.id);
          break;
        case _EpisodeRowMenuAction.downloadEpisode:
        case _EpisodeRowMenuAction.retryDownload:
          await downloadController.startDownload();
          break;
        case _EpisodeRowMenuAction.removeDownload:
          final downloadId = downloadEntry?.id;
          if (downloadId == null) {
            throw StateError('A stored download could not be found for this episode.');
          }
          await downloadController.removeDownload(downloadId);
          break;
      }
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Could not update Episode ${episode.numberLabel}.\n$error',
            ),
          ),
        );
      return;
    }

    if (!context.mounted) {
      return;
    }

    final message = switch (action) {
      _EpisodeRowMenuAction.play => 'Opening Episode ${episode.numberLabel}.',
      _EpisodeRowMenuAction.markWatched =>
        'Episode ${episode.numberLabel} marked as watched.',
      _EpisodeRowMenuAction.markUnwatched =>
        'Episode ${episode.numberLabel} reset to unwatched.',
      _EpisodeRowMenuAction.downloadEpisode =>
        'Episode ${episode.numberLabel} downloaded for offline playback.',
      _EpisodeRowMenuAction.retryDownload =>
        'Episode ${episode.numberLabel} download retried.',
      _EpisodeRowMenuAction.removeDownload =>
        'Offline download removed for Episode ${episode.numberLabel}.',
      _EpisodeRowMenuAction.downloadInProgress =>
        'Download already in progress.',
    };

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _EpisodeInfoPill extends StatelessWidget {
  const _EpisodeInfoPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
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

void _openEpisodeInPlayer(
  BuildContext context, {
  required Series series,
  required Episode episode,
}) {
  context.push(
    AppRoutePaths.player,
    extra: PlayerScreenContext(
      seriesId: series.id,
      seriesTitle: series.title,
      episodeId: episode.id,
      episodeNumberLabel: episode.numberLabel,
      episodeTitle: episode.title,
    ),
  );
}

class _WatchSummaryChip extends StatelessWidget {
  const _WatchSummaryChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: color.withValues(alpha: 0.28)),
      labelStyle: Theme.of(
        context,
      ).textTheme.labelMedium?.copyWith(color: color),
      backgroundColor: color.withValues(alpha: 0.08),
    );
  }
}

class _WatchStateBadge extends StatelessWidget {
  const _WatchStateBadge({required this.label, required this.color});

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
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
      ),
    );
  }
}

enum _EpisodeListFilter {
  all('All'),
  continueWatching('Continue'),
  unwatched('Unwatched'),
  watched('Watched');

  const _EpisodeListFilter(this.label);

  final String label;
}

enum _EpisodeSortOrder {
  oldestFirst('Oldest first'),
  newestFirst('Newest first');

  const _EpisodeSortOrder(this.label);

  final String label;
}

class _EpisodeActionHint {
  const _EpisodeActionHint({required this.label, required this.tone});

  final String label;
  final _EpisodeActionHintTone tone;
}

enum _EpisodeActionHintTone { primary, secondary }

enum _EpisodeRowMenuAction {
  play('Play episode'),
  downloadEpisode('Download for offline'),
  retryDownload('Retry download'),
  removeDownload('Remove offline download'),
  downloadInProgress('Download in progress'),
  markWatched('Mark as watched'),
  markUnwatched('Mark as unwatched');

  const _EpisodeRowMenuAction(this.label);

  final String label;
}

class _EpisodesSectionLead extends StatelessWidget {
  const _EpisodesSectionLead({
    required this.message,
    required this.actionLabel,
  });

  final String message;
  final String actionLabel;

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
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              actionLabel,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EpisodeNumberTile extends StatelessWidget {
  const _EpisodeNumberTile({required this.numberLabel, required this.color});

  final String numberLabel;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 68,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Text(
            'EP',
            style: theme.textTheme.labelMedium?.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Text(
            numberLabel,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
        ],
      ),
    );
  }
}

class _EpisodeWatchStatus extends StatelessWidget {
  const _EpisodeWatchStatus({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(color: color),
      ),
    );
  }
}

class _HeroBannerArtwork extends StatelessWidget {
  const _HeroBannerArtwork({
    required this.imageUrl,
    required this.fallbackLabel,
  });

  final String? imageUrl;
  final String fallbackLabel;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: _SeriesArtworkImage(
          imageUrl: imageUrl,
          fallbackLabel: fallbackLabel,
          icon: Icons.live_tv_rounded,
          alignment: Alignment.topCenter,
        ),
      ),
    );
  }
}

class _IdentityPoster extends StatelessWidget {
  const _IdentityPoster({required this.imageUrl, required this.fallbackLabel});

  final String? imageUrl;
  final String fallbackLabel;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: SizedBox(
        width: 110,
        child: AspectRatio(
          aspectRatio: 2 / 3,
          child: _SeriesArtworkImage(
            imageUrl: imageUrl,
            fallbackLabel: fallbackLabel,
            icon: Icons.movie_creation_outlined,
          ),
        ),
      ),
    );
  }
}

class _SeriesArtworkImage extends StatelessWidget {
  const _SeriesArtworkImage({
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
      return _SeriesArtworkFallback(fallbackLabel: fallbackLabel, icon: icon);
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
              _SeriesArtworkFallback(fallbackLabel: fallbackLabel, icon: icon),
              const Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ],
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _SeriesArtworkFallback(
            fallbackLabel: fallbackLabel,
            icon: icon,
          );
        },
      ),
    );
  }
}

class _SeriesArtworkFallback extends StatelessWidget {
  const _SeriesArtworkFallback({
    required this.fallbackLabel,
    required this.icon,
  });

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

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.trailing,
    this.visualDensity = _SectionDensity.standard,
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final _SectionDensity visualDensity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final highlighted = visualDensity == _SectionDensity.highlighted;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: highlighted
            ? theme.colorScheme.surfaceContainerLow
            : theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(highlighted ? 24 : 22),
      ),
      child: Padding(
        padding: EdgeInsets.all(highlighted ? 18 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
                if (trailing != null) ...[
                  const SizedBox(width: 12),
                  trailing!,
                ],
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

enum _SectionDensity { standard, highlighted }

class _HeroTag extends StatelessWidget {
  const _HeroTag({required this.label, required this.color});

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
        style: Theme.of(context).textTheme.labelLarge?.copyWith(color: color),
      ),
    );
  }
}

class _HeroStat {
  const _HeroStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;
}

class _HeroStatCard extends StatelessWidget {
  const _HeroStatCard({required this.stat});

  final _HeroStat stat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: 132,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: stat.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: stat.color.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stat.label,
            style: theme.textTheme.labelMedium?.copyWith(color: stat.color),
          ),
          const SizedBox(height: 6),
          Text(
            stat.value,
            style: theme.textTheme.headlineSmall,
          ),
        ],
      ),
    );
  }
}

String _formatPlaybackPosition(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);

  if (hours > 0) {
    return minutes == 0 ? '${hours}h' : '${hours}h ${minutes}m';
  }

  if (duration.inMinutes > 0) {
    return '${duration.inMinutes}m';
  }

  return '${duration.inSeconds}s';
}
