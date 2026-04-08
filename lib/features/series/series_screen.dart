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
import '../../shared/widgets/anime_cached_artwork.dart';
import '../../shared/widgets/media_overlay_pill.dart';
import '../player/player_screen_context.dart';

class SeriesScreen extends ConsumerWidget {
  const SeriesScreen({super.key, required this.seriesId});

  final String seriesId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seriesDetails = ref.watch(seriesDetailsProvider(seriesId));

    Future<void> refreshDetails() async {
      ref.invalidate(seriesContentProvider(seriesId));
      ref.invalidate(seriesDetailsProvider(seriesId));
      ref.invalidate(watchlistMembershipControllerProvider(seriesId));
      ref.invalidate(downloadsListProvider);
      try {
        await ref.read(seriesDetailsProvider(seriesId).future);
      } catch (_) {
        return;
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Series')),
      body: seriesDetails.when(
        loading: () => const _SeriesHubState(
          icon: Icons.live_tv_rounded,
          title: 'Loading series',
          message: 'Preparing this watch hub.',
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => _SeriesHubState(
          icon: Icons.error_outline_rounded,
          title: 'Series unavailable',
          message: 'This series could not be loaded right now.',
          actions: [
            FilledButton.icon(
              onPressed: refreshDetails,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
            ),
            TextButton.icon(
              onPressed: () => context.go(AppRoutePaths.browse),
              icon: const Icon(Icons.explore_outlined),
              label: const Text('Open Browse'),
            ),
          ],
        ),
        data: (details) => RefreshIndicator(
          onRefresh: refreshDetails,
          child: _SeriesPage(details: details),
        ),
      ),
    );
  }
}

class _SeriesHubState extends StatelessWidget {
  const _SeriesHubState({
    required this.icon,
    required this.title,
    required this.message,
    this.child,
    this.actions = const [],
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(24),
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 420),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (child != null) ...[
                    child!,
                    const SizedBox(height: 20),
                  ] else ...[
                    Icon(icon, size: 40, color: theme.colorScheme.primary),
                    const SizedBox(height: 20),
                  ],
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (actions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Wrap(spacing: 8, runSpacing: 8, children: actions),
                  ],
                ],
              ),
            ),
          ),
        ),
      ],
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
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        _SeriesHero(details: details),
        const SizedBox(height: 16),
        _PrimaryWatchPanel(details: details),
        if (!details.isWatchStateAvailable) ...[
          const SizedBox(height: 16),
          const _WatchStateNotice(),
        ],
        const SizedBox(height: 22),
        _SaveIntentSection(series: series),
        const SizedBox(height: 22),
        _EpisodesSection(details: details),
        const SizedBox(height: 22),
        _SeriesDetailsSection(
          series: series,
          episodeCount: details.episodes.length,
        ),
      ],
    );
  }
}

class _SeriesHero extends StatelessWidget {
  const _SeriesHero({required this.details});

  final SeriesDetailsData details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final series = details.series;
    final facts = <String>[
      if (series.releaseYear != null) '${series.releaseYear}',
      if (series.genres.isNotEmpty) series.genres.take(2).join(' • '),
      '${details.episodes.length} episodes',
    ].join(' • ');
    final progressSummary = !details.isWatchStateAvailable
        ? 'Watch activity unavailable'
        : switch ((
            details.inProgressEpisodeCount,
            details.completedEpisodeCount,
          )) {
            (0, 0) => 'No watch activity yet',
            (final inProgress, final completed)
                when inProgress > 0 && completed > 0 =>
              '$inProgress in progress • $completed completed',
            (final inProgress, 0) when inProgress > 0 =>
              '$inProgress episode in progress',
            (0, final completed) when completed > 0 => '$completed completed',
            _ => 'Watch state available',
          };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: SizedBox(
            height: 272,
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
                          Colors.black.withValues(alpha: 0.04),
                          Colors.black.withValues(alpha: 0.14),
                          Colors.black.withValues(alpha: 0.92),
                        ],
                      ),
                    ),
                  ),
                ),
                const Positioned(
                  left: 16,
                  top: 16,
                  child: MediaOverlayPill(
                    label: 'Series hub',
                    icon: Icons.play_circle_fill_rounded,
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (facts.isNotEmpty)
                        Text(
                          facts,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      if (facts.isNotEmpty) const SizedBox(height: 8),
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
                            height: 1.26,
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
        const SizedBox(height: 10),
        Text(
          progressSummary,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _PrimaryWatchPanel extends StatelessWidget {
  const _PrimaryWatchPanel({required this.details});

  final SeriesDetailsData details;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final action = details.primaryWatchAction;
    final targetEpisode = action.targetEpisode;
    final primaryActionLabel =
        !details.isWatchStateAvailable && targetEpisode != null
        ? 'Play Episode ${targetEpisode.numberLabel}'
        : action.label;
    final supportingText = !details.isWatchStateAvailable
        ? targetEpisode == null
              ? 'Watch activity is unavailable right now and no playable episode is ready yet.'
              : 'Watch activity is unavailable right now. Start from Episode ${targetEpisode.numberLabel} or refresh to restore resume state.'
        : switch (action.kind) {
            SeriesPrimaryWatchActionKind.resumeEpisode
                when targetEpisode != null =>
              'Continue from Episode ${targetEpisode.numberLabel} • ${targetEpisode.title}',
            SeriesPrimaryWatchActionKind.continueEpisode
                when targetEpisode != null =>
              'Up next: Episode ${targetEpisode.numberLabel} • ${targetEpisode.title}',
            SeriesPrimaryWatchActionKind.startWatching
                when targetEpisode != null =>
              'Begin with Episode ${targetEpisode.numberLabel} • ${targetEpisode.title}',
            SeriesPrimaryWatchActionKind.endOfAvailableContent =>
              'Every currently available episode is complete.',
            SeriesPrimaryWatchActionKind.unavailable =>
              'Episodes are not available yet.',
            _ => 'A playable episode is not available yet.',
          };
    final activityText = !details.isWatchStateAvailable
        ? 'Resume progress and watched markers could not be loaded right now.'
        : switch ((
            details.latestProgress,
            details.latestProgress == null
                ? null
                : details.episodeForProgress(details.latestProgress!),
          )) {
            (final progress?, final episode?) when progress.isCompleted =>
              'Latest activity: completed Episode ${episode.numberLabel}',
            (final progress?, final episode?) =>
              'Latest activity: Episode ${episode.numberLabel} at ${_formatPlaybackPosition(progress.position)}',
            _ =>
              'Choose a specific episode below or start from the main action.',
          };

    final stateLabel = !details.isWatchStateAvailable
        ? 'Playback'
        : switch (action.kind) {
            SeriesPrimaryWatchActionKind.resumeEpisode => 'Resume',
            SeriesPrimaryWatchActionKind.continueEpisode => 'Up next',
            SeriesPrimaryWatchActionKind.startWatching => 'Start',
            SeriesPrimaryWatchActionKind.endOfAvailableContent => 'Complete',
            SeriesPrimaryWatchActionKind.unavailable => 'Unavailable',
          };

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _HeaderChip(
                  label: stateLabel,
                  color: theme.colorScheme.primary,
                ),
                _HeaderChip(
                  label: '${details.episodes.length} episodes',
                  color: theme.colorScheme.secondary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              primaryActionLabel,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              supportingText,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.28,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              activityText,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
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
                  label: Text(primaryActionLabel),
                ),
                TextButton.icon(
                  onPressed: () => context.push(AppRoutePaths.watchlist),
                  icon: const Icon(Icons.bookmark_outline_rounded),
                  label: const Text('Open Watchlist'),
                ),
              ],
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

    return savedState.when(
      loading: () => DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Padding(
          padding: EdgeInsets.all(14),
          child: Row(
            children: [
              SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Expanded(child: Text('Checking Watchlist status...')),
            ],
          ),
        ),
      ),
      error: (error, stackTrace) => DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Text(
            'The saved-for-later state could not be loaded right now.\n$error',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
      data: (isSaved) {
        return DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: isSaved
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Saved for later',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'This series is already in Watchlist.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 10),
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
                            label: const Text('Remove'),
                          ),
                          TextButton(
                            onPressed: () =>
                                context.push(AppRoutePaths.watchlist),
                            child: const Text('Open Watchlist'),
                          ),
                        ],
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Save for later',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        'Use Watchlist for intent to return later.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 10),
                      FilledButton.tonalIcon(
                        onPressed: () => ref
                            .read(
                              watchlistMembershipControllerProvider(
                                series.id,
                              ).notifier,
                            )
                            .addToWatchlist(),
                        icon: const Icon(Icons.bookmark_add_rounded),
                        label: const Text('Save to Watchlist'),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }
}

class _WatchStateNotice extends StatelessWidget {
  const _WatchStateNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Watch activity unavailable',
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 5),
            Text(
              'Resume progress and watched markers could not be loaded right now. You can still start playback and refresh this page to restore watch-state context.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSecondaryContainer,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SeriesDetailsSection extends StatelessWidget {
  const _SeriesDetailsSection({
    required this.series,
    required this.episodeCount,
  });

  final Series series;
  final int episodeCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final facts = <String>[
      if (series.releaseYear != null) 'Year ${series.releaseYear}',
      if (series.genres.isNotEmpty) series.genres.take(3).join(' • '),
      'Episodes $episodeCount',
    ].where((entry) => entry.trim().isNotEmpty).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('About this series', style: theme.textTheme.titleLarge),
        const SizedBox(height: 8),
        if (facts.isNotEmpty)
          Text(
            facts.join(' • '),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        if ((series.synopsis ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            series.synopsis!.trim(),
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
          ),
        ],
      ],
    );
  }
}

class _EpisodesSection extends StatefulWidget {
  const _EpisodesSection({required this.details});

  final SeriesDetailsData details;

  @override
  State<_EpisodesSection> createState() => _EpisodesSectionState();
}

class _EpisodesSectionState extends State<_EpisodesSection> {
  late final TextEditingController _episodeQueryController;
  _EpisodeListFilter _selectedFilter = _EpisodeListFilter.all;
  _EpisodeSortOrder _selectedSortOrder = _EpisodeSortOrder.oldestFirst;
  String _episodeQuery = '';

  @override
  void initState() {
    super.initState();
    _episodeQueryController = TextEditingController();
  }

  @override
  void dispose() {
    _episodeQueryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = widget.details;
    final series = details.series;
    final watchStateAvailable = details.isWatchStateAvailable;
    final episodes = details.episodes;
    final sortedEpisodes = episodes.toList(growable: false)
      ..sort((left, right) => left.sortOrder.compareTo(right.sortOrder));
    final orderedEpisodes = _selectedSortOrder == _EpisodeSortOrder.oldestFirst
        ? sortedEpisodes
        : sortedEpisodes.reversed.toList(growable: false);
    final inProgressCount = details.inProgressEpisodeCount;
    final watchedCount = details.completedEpisodeCount;
    final unwatchedCount =
        sortedEpisodes.length - inProgressCount - watchedCount;
    final effectiveFilter = watchStateAvailable
        ? _selectedFilter
        : _EpisodeListFilter.all;
    final normalizedEpisodeQuery = _normalizeEpisodeFinderQuery(_episodeQuery);
    final visibleEpisodes = orderedEpisodes
        .where(
          (episode) =>
              _matchesFilter(details, episode, effectiveFilter) &&
              _matchesEpisodeQuery(episode, normalizedEpisodeQuery),
        )
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Episodes', style: theme.textTheme.titleLarge),
            ),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _selectedSortOrder =
                      _selectedSortOrder == _EpisodeSortOrder.oldestFirst
                      ? _EpisodeSortOrder.newestFirst
                      : _EpisodeSortOrder.oldestFirst;
                });
              },
              icon: const Icon(Icons.swap_vert_rounded),
              label: Text(_selectedSortOrder.label),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          watchStateAvailable
              ? 'Primary play path stays first. Secondary actions move into the overflow menu.'
              : 'Watch activity filters are unavailable right now. Refresh to restore resume and watched states.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _episodeQueryController,
          textInputAction: TextInputAction.search,
          onChanged: (value) => setState(() => _episodeQuery = value),
          decoration: InputDecoration(
            hintText: 'Find an episode by number or title',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: normalizedEpisodeQuery.isEmpty
                ? null
                : IconButton(
                    onPressed: () {
                      _episodeQueryController.clear();
                      setState(() => _episodeQuery = '');
                    },
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Clear episode filter',
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          normalizedEpisodeQuery.isEmpty
              ? 'Jump into long runs faster by episode number or title.'
              : 'Showing episodes matching "$normalizedEpisodeQuery".',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _EpisodeFilterButton(
                label: 'All',
                count: sortedEpisodes.length,
                isSelected: effectiveFilter == _EpisodeListFilter.all,
                onTap: () =>
                    setState(() => _selectedFilter = _EpisodeListFilter.all),
              ),
              if (watchStateAvailable) ...[
                const SizedBox(width: 8),
                _EpisodeFilterButton(
                  label: 'Continue',
                  count: inProgressCount,
                  isSelected:
                      effectiveFilter == _EpisodeListFilter.continueWatching,
                  onTap: () => setState(
                    () => _selectedFilter = _EpisodeListFilter.continueWatching,
                  ),
                ),
                const SizedBox(width: 8),
                _EpisodeFilterButton(
                  label: 'Unwatched',
                  count: unwatchedCount,
                  isSelected: effectiveFilter == _EpisodeListFilter.unwatched,
                  onTap: () => setState(
                    () => _selectedFilter = _EpisodeListFilter.unwatched,
                  ),
                ),
                const SizedBox(width: 8),
                _EpisodeFilterButton(
                  label: 'Watched',
                  count: watchedCount,
                  isSelected: effectiveFilter == _EpisodeListFilter.watched,
                  onTap: () => setState(
                    () => _selectedFilter = _EpisodeListFilter.watched,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        if (episodes.isEmpty)
          const _InlineEpisodesState(
            title: 'Episodes unavailable',
            message: 'Episodes are not available for this series yet.',
          )
        else if (visibleEpisodes.isEmpty)
          _InlineEpisodesState(
            title: 'Nothing in this filter',
            message: normalizedEpisodeQuery.isNotEmpty
                ? 'No episodes match "$normalizedEpisodeQuery" in this view.'
                : switch (effectiveFilter) {
                    _EpisodeListFilter.all =>
                      'No episodes are available right now.',
                    _EpisodeListFilter.continueWatching =>
                      'No episodes are currently in progress for this series.',
                    _EpisodeListFilter.unwatched =>
                      'Every available episode already has watch-state activity.',
                    _EpisodeListFilter.watched =>
                      'No episodes have been marked watched yet.',
                  },
          )
        else
          Column(
            children: [
              for (var index = 0; index < visibleEpisodes.length; index++) ...[
                if (index > 0) const Divider(height: 1),
                _EpisodeRow(
                  series: series,
                  episode: visibleEpisodes[index],
                  savedProgress: details.progressForEpisode(
                    visibleEpisodes[index].id,
                  ),
                  actionHint: _episodeActionHint(
                    details,
                    visibleEpisodes[index],
                  ),
                ),
              ],
            ],
          ),
      ],
    );
  }

  bool _matchesFilter(
    SeriesDetailsData details,
    Episode episode,
    _EpisodeListFilter filter,
  ) {
    return switch (filter) {
      _EpisodeListFilter.all => true,
      _EpisodeListFilter.continueWatching => details.isEpisodeInProgress(
        episode.id,
      ),
      _EpisodeListFilter.unwatched => !details.hasSavedProgress(episode.id),
      _EpisodeListFilter.watched => details.isEpisodeCompleted(episode.id),
    };
  }

  bool _matchesEpisodeQuery(Episode episode, String normalizedQuery) {
    if (normalizedQuery.isEmpty) {
      return true;
    }

    final candidates = <String>[
      _normalizeEpisodeFinderQuery(episode.numberLabel),
      _normalizeEpisodeFinderQuery('episode ${episode.numberLabel}'),
      _normalizeEpisodeFinderQuery(episode.title),
      _normalizeEpisodeFinderQuery('${episode.numberLabel} ${episode.title}'),
      _normalizeEpisodeFinderQuery('${episode.sortOrder}'),
    ];

    for (final candidate in candidates) {
      if (candidate.contains(normalizedQuery)) {
        return true;
      }
    }

    return false;
  }

  _EpisodeActionHint? _episodeActionHint(
    SeriesDetailsData details,
    Episode episode,
  ) {
    if (!details.isWatchStateAvailable) {
      return null;
    }

    final action = details.primaryWatchAction;
    final targetEpisode = action.targetEpisode;
    if (targetEpisode == null || targetEpisode.id != episode.id) {
      return null;
    }

    return switch (action.kind) {
      SeriesPrimaryWatchActionKind.resumeEpisode => const _EpisodeActionHint(
        label: 'Resume',
        tone: _EpisodeActionHintTone.primary,
      ),
      SeriesPrimaryWatchActionKind.continueEpisode => const _EpisodeActionHint(
        label: 'Up next',
        tone: _EpisodeActionHintTone.secondary,
      ),
      SeriesPrimaryWatchActionKind.startWatching => const _EpisodeActionHint(
        label: 'Start',
        tone: _EpisodeActionHintTone.primary,
      ),
      _ => null,
    };
  }
}

class _EpisodeFilterButton extends StatelessWidget {
  const _EpisodeFilterButton({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: isSelected
            ? Colors.black
            : theme.colorScheme.onSurface,
        backgroundColor: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.surfaceContainerLow,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
      ),
      child: Text('$label ($count)'),
    );
  }
}

class _InlineEpisodesState extends StatelessWidget {
  const _InlineEpisodesState({required this.title, required this.message});

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
        padding: const EdgeInsets.all(14),
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
    final watchStateOperation = ref.watch(
      seriesWatchStateOperationsControllerProvider(series.id),
    );
    final isBusy =
        downloadActionState.isLoading || watchStateOperation.isLoading;

    final compactStatus = _buildCompactStatus(
      episode: episode,
      savedProgress: savedProgress,
      downloadEntry: downloadEntry,
    );
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

    final backgroundColor = switch (actionHint?.tone) {
      _EpisodeActionHintTone.primary => theme.colorScheme.primary.withValues(
        alpha: 0.08,
      ),
      _EpisodeActionHintTone.secondary =>
        theme.colorScheme.secondary.withValues(alpha: 0.08),
      null when savedProgress != null => theme.colorScheme.surfaceContainerLow,
      _ => Colors.transparent,
    };

    final watchedMenuAction = savedProgress?.isCompleted == true
        ? _EpisodeRowMenuAction.markUnwatched
        : _EpisodeRowMenuAction.markWatched;
    final downloadMenuAction = switch (downloadEntry?.status) {
      DownloadStatus.completed => _EpisodeRowMenuAction.removeDownload,
      DownloadStatus.failed => _EpisodeRowMenuAction.retryDownload,
      DownloadStatus.paused => _EpisodeRowMenuAction.retryDownload,
      DownloadStatus.downloading => _EpisodeRowMenuAction.downloadInProgress,
      DownloadStatus.queued => _EpisodeRowMenuAction.retryDownload,
      null => _EpisodeRowMenuAction.downloadEpisode,
    };

    final primaryActionLabel = downloadEntry?.isPlayableOffline == true
        ? 'Play offline'
        : 'Play episode';

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isBusy
            ? null
            : () => _openEpisodeInPlayer(
                context,
                series: series,
                episode: episode,
              ),
        child: Container(
          color: backgroundColor,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compactWidth = constraints.maxWidth < 430;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: SizedBox(
                          width: compactWidth ? 108 : 122,
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: AnimeCachedArtwork(
                              imageUrl:
                                  episode.thumbnailImageUrl ??
                                  series.posterImageUrl,
                              label: episode.title.trim().isEmpty
                                  ? 'Episode ${episode.numberLabel}'
                                  : episode.title,
                              icon: Icons.movie_creation_outlined,
                              alignment: Alignment.topCenter,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    'EP ${episode.numberLabel}',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      color: theme.colorScheme.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (actionHint != null)
                                    _EpisodeInlineTag(
                                      label: actionHint!.label,
                                      tone: actionHint!.tone,
                                    ),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                episode.title.trim().isEmpty
                                    ? 'Episode ${episode.numberLabel}'
                                    : episode.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium,
                              ),
                              if (compactStatus.isNotEmpty) ...[
                                const SizedBox(height: 5),
                                Text(
                                  compactStatus,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                              if (savedProgress != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  _progressLabel(savedProgress!),
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
                      const SizedBox(width: 8),
                      PopupMenuButton<_EpisodeRowMenuAction>(
                        enabled: !isBusy,
                        tooltip: 'Episode actions',
                        position: PopupMenuPosition.under,
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
                            enabled:
                                downloadMenuAction !=
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                Icons.more_vert_rounded,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                      ),
                    ],
                  ),
                  if (progressFraction != null) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: progressFraction,
                        minHeight: 5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
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
                              : Icons.play_circle_fill_rounded,
                        ),
                        label: Text(primaryActionLabel),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
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
            throw StateError(
              'A stored download could not be found for this episode.',
            );
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

String _buildCompactStatus({
  required Episode episode,
  required EpisodeProgress? savedProgress,
  required DownloadEntry? downloadEntry,
}) {
  final parts = <String>[
    if (episode.duration != null) '${episode.duration!.inMinutes} min',
    if (savedProgress?.isCompleted == true)
      'Completed'
    else if (savedProgress != null)
      'In progress',
    if (downloadEntry?.isPlayableOffline == true)
      'Offline'
    else if (downloadEntry?.status == DownloadStatus.downloading)
      'Downloading'
    else if (downloadEntry?.status == DownloadStatus.queued ||
        downloadEntry?.status == DownloadStatus.paused ||
        downloadEntry?.failureKind == DownloadFailureKind.transferInterrupted)
      'Retry download'
    else if (downloadEntry?.status == DownloadStatus.failed)
      'Download failed',
    if (episode.isRecap) 'Recap' else if (episode.isFiller) 'Filler',
  ];

  return parts.take(3).join(' • ');
}

String _progressLabel(EpisodeProgress progress) {
  if (progress.isCompleted) {
    return 'Watched';
  }

  if (progress.totalDuration != null) {
    return '${_formatPlaybackPosition(progress.position)} / ${_formatPlaybackPosition(progress.totalDuration!)}';
  }

  return _formatPlaybackPosition(progress.position);
}

class _HeaderChip extends StatelessWidget {
  const _HeaderChip({required this.label, required this.color});

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
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EpisodeInlineTag extends StatelessWidget {
  const _EpisodeInlineTag({required this.label, required this.tone});

  final String label;
  final _EpisodeActionHintTone tone;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = tone == _EpisodeActionHintTone.secondary
        ? theme.colorScheme.secondary
        : theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

enum _EpisodeListFilter { all, continueWatching, unwatched, watched }

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

String _normalizeEpisodeFinderQuery(String rawValue) {
  return rawValue
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9а-яё ]+'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ');
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
