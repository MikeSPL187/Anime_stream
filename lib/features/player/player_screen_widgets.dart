part of 'player_screen.dart';

class _PlaybackStage extends StatelessWidget {
  const _PlaybackStage({
    required this.videoView,
    required this.positionStream,
    required this.durationStream,
    required this.onSeekRequested,
    required this.sessionContext,
    required this.qualityLabel,
    required this.isPlaying,
    required this.isBuffering,
    required this.isCompleted,
    required this.controlsVisible,
    required this.canToggleFullscreen,
    required this.isFullscreen,
    required this.onBackRequested,
    required this.onOpenSeriesRequested,
    required this.onPrimaryAction,
    required this.onSeekBackward,
    required this.onSeekForward,
    required this.onToggleFullscreen,
    required this.onStageTap,
    required this.onTimelineInteractionStart,
    required this.onTimelineInteractionEnd,
    this.previousEpisodeActionLabel,
    this.onPlayPreviousEpisodeRequested,
    this.nextEpisodeActionLabel,
    this.onPlayNextEpisodeRequested,
    this.cancelAutoplayActionLabel,
    this.onCancelAutoplayRequested,
    this.speedActionLabel,
    this.onSpeedRequested,
    this.qualityActionLabel,
    this.onQualityRequested,
  });

  final Widget videoView;
  final Stream<Duration> positionStream;
  final Stream<Duration> durationStream;
  final Future<void> Function(Duration position) onSeekRequested;
  final PlayerScreenContext sessionContext;
  final String qualityLabel;
  final bool isPlaying;
  final bool isBuffering;
  final bool isCompleted;
  final bool controlsVisible;
  final bool canToggleFullscreen;
  final bool isFullscreen;
  final Future<void> Function() onBackRequested;
  final VoidCallback onOpenSeriesRequested;
  final Future<void> Function() onPrimaryAction;
  final Future<void> Function() onSeekBackward;
  final Future<void> Function() onSeekForward;
  final Future<void> Function() onToggleFullscreen;
  final VoidCallback onStageTap;
  final VoidCallback onTimelineInteractionStart;
  final VoidCallback onTimelineInteractionEnd;
  final String? previousEpisodeActionLabel;
  final Future<void> Function()? onPlayPreviousEpisodeRequested;
  final String? nextEpisodeActionLabel;
  final Future<void> Function()? onPlayNextEpisodeRequested;
  final String? cancelAutoplayActionLabel;
  final Future<void> Function()? onCancelAutoplayRequested;
  final String? speedActionLabel;
  final Future<void> Function()? onSpeedRequested;
  final String? qualityActionLabel;
  final Future<void> Function()? onQualityRequested;

  @override
  Widget build(BuildContext context) {
    final isHandset = MediaQuery.sizeOf(context).shortestSide < 600;
    final isHandsetFullscreen = isHandset && isFullscreen;
    final effectiveControlsVisible =
        controlsVisible || !isPlaying || isBuffering || isCompleted;
    final theme = Theme.of(context);
    final playbackStateLabel = isCompleted
        ? 'Complete'
        : isBuffering
        ? 'Buffering'
        : isPlaying
        ? 'Playing'
        : 'Paused';
    final stageLabel = '$qualityLabel • ${sessionContext.episodeDisplayLabel}';
    final titleStyle = isHandsetFullscreen
        ? theme.textTheme.titleSmall?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          )
        : theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          );
    final dockBackground = isHandsetFullscreen
        ? const Color(0x2E101010)
        : const Color(0x40101010);
    final dockPadding = isHandsetFullscreen
        ? const EdgeInsets.fromLTRB(12, 8, 12, 10)
        : const EdgeInsets.fromLTRB(14, 10, 14, 12);

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTap: onStageTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Colors.black),
          videoView,
          if (isBuffering)
            const ColoredBox(
              color: Color(0x33000000),
              child: Center(child: CircularProgressIndicator()),
            ),
          IgnorePointer(
            ignoring: !effectiveControlsVisible,
            child: AnimatedOpacity(
              opacity: effectiveControlsVisible ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xB8000000),
                      Color(0x05000000),
                      Color(0xCC000000),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: isHandsetFullscreen
                        ? const EdgeInsets.fromLTRB(12, 8, 12, 12)
                        : const EdgeInsets.fromLTRB(14, 12, 14, 14),
                    child: Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _OverlayIconButton(
                              icon: Icons.arrow_back_rounded,
                              onPressed: onBackRequested,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _OverlayPill(
                                    label: playbackStateLabel,
                                    color: _playerAccent,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    sessionContext.seriesTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: titleStyle,
                                  ),
                                  SizedBox(height: isHandsetFullscreen ? 2 : 3),
                                  Text(
                                    sessionContext.episodeTitle,
                                    maxLines: isHandsetFullscreen ? 1 : 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: Colors.white70,
                                      height: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            _OverlayIconButton(
                              icon: Icons.menu_book_rounded,
                              onPressed: () async => onOpenSeriesRequested(),
                            ),
                          ],
                        ),
                        const Spacer(),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: isHandsetFullscreen ? 420 : 760,
                          ),
                          child: _PlayerGlassPanel(
                            backgroundColor: dockBackground,
                            padding: dockPadding,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isHandsetFullscreen) ...[
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          stageLabel,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(color: Colors.white70),
                                        ),
                                      ),
                                      if (canToggleFullscreen) ...[
                                        const SizedBox(width: 8),
                                        IconButton(
                                          onPressed: () {
                                            unawaited(onToggleFullscreen());
                                          },
                                          icon: Icon(
                                            isFullscreen
                                                ? Icons.fullscreen_exit_rounded
                                                : Icons.fullscreen_rounded,
                                            color: Colors.white,
                                          ),
                                          tooltip: isFullscreen
                                              ? 'Exit Fullscreen'
                                              : 'Enter Fullscreen',
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                ],
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    _OverlayTransportButton(
                                      icon: Icons.replay_10_rounded,
                                      compact: isHandsetFullscreen,
                                      onPressed: () async {
                                        await onSeekBackward();
                                      },
                                    ),
                                    SizedBox(
                                      width: isHandsetFullscreen ? 14 : 18,
                                    ),
                                    _OverlayTransportButton(
                                      icon: isCompleted
                                          ? Icons.replay_rounded
                                          : isPlaying
                                          ? Icons.pause_rounded
                                          : Icons.play_arrow_rounded,
                                      isPrimary: true,
                                      compact: isHandsetFullscreen,
                                      onPressed: () async {
                                        await onPrimaryAction();
                                      },
                                    ),
                                    SizedBox(
                                      width: isHandsetFullscreen ? 14 : 18,
                                    ),
                                    _OverlayTransportButton(
                                      icon: Icons.forward_10_rounded,
                                      compact: isHandsetFullscreen,
                                      onPressed: () async {
                                        await onSeekForward();
                                      },
                                    ),
                                  ],
                                ),
                                SizedBox(height: isHandsetFullscreen ? 6 : 10),
                                _PlaybackTimeline(
                                  positionStream: positionStream,
                                  durationStream: durationStream,
                                  onSeekRequested: onSeekRequested,
                                  textColor: Colors.white,
                                  inactiveColor: isHandsetFullscreen
                                      ? Colors.white10
                                      : Colors.white24,
                                  compact: isHandsetFullscreen,
                                  onInteractionStart:
                                      onTimelineInteractionStart,
                                  onInteractionEnd: onTimelineInteractionEnd,
                                ),
                                if ((previousEpisodeActionLabel != null &&
                                        onPlayPreviousEpisodeRequested !=
                                            null) ||
                                    (speedActionLabel != null &&
                                        onSpeedRequested != null) ||
                                    (qualityActionLabel != null &&
                                        onQualityRequested != null) ||
                                    (nextEpisodeActionLabel != null &&
                                        onPlayNextEpisodeRequested != null) ||
                                    (cancelAutoplayActionLabel != null &&
                                        onCancelAutoplayRequested != null)) ...[
                                  SizedBox(
                                    height: isHandsetFullscreen ? 6 : 10,
                                  ),
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      alignment: WrapAlignment.end,
                                      children: [
                                        if (previousEpisodeActionLabel !=
                                                null &&
                                            onPlayPreviousEpisodeRequested !=
                                                null)
                                          TextButton.icon(
                                            onPressed: () {
                                              unawaited(
                                                onPlayPreviousEpisodeRequested!
                                                    .call(),
                                              );
                                            },
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.white,
                                            ),
                                            icon: const Icon(
                                              Icons.skip_previous_rounded,
                                            ),
                                            label: Text(
                                              previousEpisodeActionLabel!,
                                            ),
                                          ),
                                        if (speedActionLabel != null &&
                                            onSpeedRequested != null)
                                          TextButton.icon(
                                            onPressed: () {
                                              unawaited(
                                                onSpeedRequested!.call(),
                                              );
                                            },
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.white,
                                            ),
                                            icon: const Icon(
                                              Icons.speed_rounded,
                                            ),
                                            label: Text(speedActionLabel!),
                                          ),
                                        if (qualityActionLabel != null &&
                                            onQualityRequested != null)
                                          TextButton.icon(
                                            onPressed: () {
                                              unawaited(
                                                onQualityRequested!.call(),
                                              );
                                            },
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.white,
                                            ),
                                            icon: const Icon(
                                              Icons.high_quality_rounded,
                                            ),
                                            label: Text(qualityActionLabel!),
                                          ),
                                        if (nextEpisodeActionLabel != null &&
                                            onPlayNextEpisodeRequested != null)
                                          TextButton.icon(
                                            onPressed: () {
                                              unawaited(
                                                onPlayNextEpisodeRequested!
                                                    .call(),
                                              );
                                            },
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.white,
                                            ),
                                            icon: const Icon(
                                              Icons.skip_next_rounded,
                                            ),
                                            label: Text(
                                              nextEpisodeActionLabel!,
                                            ),
                                          ),
                                        if (cancelAutoplayActionLabel != null &&
                                            onCancelAutoplayRequested != null)
                                          TextButton.icon(
                                            onPressed: () {
                                              unawaited(
                                                onCancelAutoplayRequested!
                                                    .call(),
                                              );
                                            },
                                            style: TextButton.styleFrom(
                                              foregroundColor: Colors.white,
                                            ),
                                            icon: const Icon(
                                              Icons.close_rounded,
                                            ),
                                            label: Text(
                                              cancelAutoplayActionLabel!,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                                if (isHandsetFullscreen) ...[
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          stageLabel,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: theme.textTheme.labelSmall
                                              ?.copyWith(
                                                color: Colors.white54,
                                                fontWeight: FontWeight.w600,
                                              ),
                                        ),
                                      ),
                                      if (canToggleFullscreen)
                                        IconButton(
                                          visualDensity: VisualDensity.compact,
                                          onPressed: () {
                                            unawaited(onToggleFullscreen());
                                          },
                                          icon: const Icon(
                                            Icons.fullscreen_exit_rounded,
                                            color: Colors.white70,
                                            size: 20,
                                          ),
                                          tooltip: 'Exit Fullscreen',
                                        ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionSummaryPanel extends StatelessWidget {
  const _SessionSummaryPanel({
    required this.sessionContext,
    required this.qualityLabel,
    required this.streamHost,
    required this.statusText,
    required this.statusLabel,
    required this.primaryActionIcon,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    this.timeline,
    this.secondaryActionIcon,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.speedActionLabel,
    this.onSpeedAction,
    this.qualityActionLabel,
    this.onQualityAction,
  });

  final PlayerScreenContext sessionContext;
  final String? qualityLabel;
  final String? streamHost;
  final String statusText;
  final String statusLabel;
  final Widget? timeline;
  final IconData primaryActionIcon;
  final String primaryActionLabel;
  final Future<void> Function() onPrimaryAction;
  final IconData? secondaryActionIcon;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final String? speedActionLabel;
  final Future<void> Function()? onSpeedAction;
  final String? qualityActionLabel;
  final Future<void> Function()? onQualityAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _PlayerGlassPanel(
      backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.95),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Now playing',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            sessionContext.seriesTitle,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sessionContext.episodeTitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _HeaderChip(
                label: sessionContext.episodeDisplayLabel,
                color: theme.colorScheme.primary,
              ),
              if (qualityLabel != null)
                _HeaderChip(
                  label: qualityLabel!,
                  color: theme.colorScheme.secondary,
                ),
              if (streamHost != null && streamHost!.isNotEmpty)
                _HeaderChip(
                  label: streamHost!,
                  color: theme.colorScheme.tertiary,
                ),
              _HeaderChip(label: statusLabel, color: theme.colorScheme.primary),
            ],
          ),
          if (statusText.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              statusText,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.25,
              ),
            ),
          ],
          if (timeline != null) ...[const SizedBox(height: 14), timeline!],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () {
                  unawaited(onPrimaryAction());
                },
                icon: Icon(primaryActionIcon),
                label: Text(primaryActionLabel),
              ),
              if (speedActionLabel != null && onSpeedAction != null)
                TextButton.icon(
                  onPressed: () {
                    unawaited(onSpeedAction!());
                  },
                  icon: const Icon(Icons.speed_rounded),
                  label: Text(speedActionLabel!),
                ),
              if (qualityActionLabel != null && onQualityAction != null)
                TextButton.icon(
                  onPressed: () {
                    unawaited(onQualityAction!());
                  },
                  icon: const Icon(Icons.high_quality_rounded),
                  label: Text(qualityActionLabel!),
                ),
              if (secondaryActionLabel != null && onSecondaryAction != null)
                TextButton.icon(
                  onPressed: onSecondaryAction,
                  icon: Icon(
                    secondaryActionIcon ?? Icons.arrow_forward_rounded,
                  ),
                  label: Text(secondaryActionLabel!),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CompactSessionSummary extends StatelessWidget {
  const _CompactSessionSummary({
    required this.sessionContext,
    required this.qualityLabel,
    required this.statusLabel,
    required this.statusText,
    required this.primaryActionIcon,
    required this.primaryActionLabel,
    required this.onPrimaryAction,
    this.secondaryActionIcon,
    this.secondaryActionLabel,
    this.onSecondaryAction,
    this.speedActionLabel,
    this.onSpeedAction,
    this.qualityActionLabel,
    this.onQualityAction,
  });

  final PlayerScreenContext sessionContext;
  final String? qualityLabel;
  final String statusLabel;
  final String statusText;
  final IconData primaryActionIcon;
  final String primaryActionLabel;
  final Future<void> Function() onPrimaryAction;
  final IconData? secondaryActionIcon;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;
  final String? speedActionLabel;
  final Future<void> Function()? onSpeedAction;
  final String? qualityActionLabel;
  final Future<void> Function()? onQualityAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final summaryLine = <String>[
      sessionContext.episodeDisplayLabel,
      if (qualityLabel case final value? when value.trim().isNotEmpty)
        value.trim(),
      _compactStatusCopy(statusLabel, statusText),
    ].join(' • ');

    return _PlayerGlassPanel(
      backgroundColor: theme.colorScheme.surface.withValues(alpha: 0.94),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            sessionContext.seriesTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            sessionContext.episodeTitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            summaryLine,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              FilledButton.icon(
                onPressed: () {
                  unawaited(onPrimaryAction());
                },
                icon: Icon(primaryActionIcon),
                label: Text(primaryActionLabel),
              ),
              if (speedActionLabel != null && onSpeedAction != null)
                TextButton.icon(
                  onPressed: () {
                    unawaited(onSpeedAction!());
                  },
                  icon: const Icon(Icons.speed_rounded),
                  label: Text(speedActionLabel!),
                ),
              if (qualityActionLabel != null && onQualityAction != null)
                TextButton.icon(
                  onPressed: () {
                    unawaited(onQualityAction!());
                  },
                  icon: const Icon(Icons.high_quality_rounded),
                  label: Text(qualityActionLabel!),
                ),
              if (secondaryActionLabel != null && onSecondaryAction != null)
                TextButton.icon(
                  onPressed: onSecondaryAction,
                  icon: Icon(
                    secondaryActionIcon ?? Icons.arrow_forward_rounded,
                  ),
                  label: Text(secondaryActionLabel!),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

String _compactStatusCopy(String statusLabel, String statusText) {
  final normalizedStatus = statusText.trim();
  if (normalizedStatus.startsWith('Episode finished')) {
    return 'Marked complete';
  }
  if (normalizedStatus.startsWith('Playback is active, but the stream')) {
    return 'Stream catching up';
  }
  if (normalizedStatus.startsWith('Playback is active')) {
    return 'Progress syncing';
  }
  if (normalizedStatus.startsWith('Playback is paused')) {
    return 'Ready to resume';
  }
  if (normalizedStatus.startsWith('Player is preparing')) {
    return 'Preparing stream';
  }
  if (normalizedStatus.isNotEmpty) {
    return normalizedStatus;
  }
  return statusLabel.trim();
}

class _PlaybackQualitySheet extends StatelessWidget {
  const _PlaybackQualitySheet({
    required this.activeQualityLabel,
    required this.options,
  });

  final String activeQualityLabel;
  final List<PlayerPlaybackQualityOption> options;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Playback quality',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Current stream: $activeQualityLabel',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            for (final option in options)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  option.isSelected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,
                ),
                title: Text(option.label),
                subtitle: option.isOffline
                    ? const Text('Offline source')
                    : const Text('Remote stream'),
                trailing: option.isSelected
                    ? const Icon(Icons.check_rounded)
                    : null,
                onTap: () => Navigator.of(context).pop(option.variantIndex),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlaybackSpeedSheet extends StatelessWidget {
  const _PlaybackSpeedSheet({
    required this.activeRateLabel,
    required this.options,
  });

  final String activeRateLabel;
  final List<PlayerPlaybackSpeedOption> options;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Playback speed',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Now using $activeRateLabel.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            for (final option in options)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  option.isSelected
                      ? Icons.check_circle_rounded
                      : Icons.speed_rounded,
                  color: option.isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                title: Text(option.label),
                trailing: option.isSelected
                    ? Text(
                        'Current',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      )
                    : null,
                onTap: () => Navigator.of(context).pop(option.rate),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlaybackTimeline extends StatefulWidget {
  const _PlaybackTimeline({
    required this.positionStream,
    required this.durationStream,
    required this.onSeekRequested,
    required this.textColor,
    required this.onInteractionStart,
    required this.onInteractionEnd,
    this.compact = false,
    this.inactiveColor,
  });

  final Stream<Duration> positionStream;
  final Stream<Duration> durationStream;
  final Future<void> Function(Duration position) onSeekRequested;
  final Color textColor;
  final Color? inactiveColor;
  final bool compact;
  final VoidCallback onInteractionStart;
  final VoidCallback onInteractionEnd;

  @override
  State<_PlaybackTimeline> createState() => _PlaybackTimelineState();
}

class _PlaybackTimelineState extends State<_PlaybackTimeline> {
  double? _dragValue;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration>(
      stream: widget.positionStream,
      initialData: Duration.zero,
      builder: (context, positionSnapshot) {
        return StreamBuilder<Duration>(
          stream: widget.durationStream,
          initialData: Duration.zero,
          builder: (context, durationSnapshot) {
            final position = positionSnapshot.data ?? Duration.zero;
            final duration = durationSnapshot.data ?? Duration.zero;
            final hasDuration = duration > Duration.zero;
            final currentValue = hasDuration
                ? (position.inMilliseconds / duration.inMilliseconds).clamp(
                    0.0,
                    1.0,
                  )
                : 0.0;
            final displayedValue = _dragValue ?? currentValue;
            final displayedPosition = hasDuration
                ? Duration(
                    milliseconds: (duration.inMilliseconds * displayedValue)
                        .round(),
                  )
                : position;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    overlayShape: SliderComponentShape.noOverlay,
                    trackHeight: widget.compact ? 2 : null,
                    activeTrackColor: widget.textColor,
                    inactiveTrackColor:
                        widget.inactiveColor ??
                        widget.textColor.withValues(alpha: 0.24),
                    thumbColor: widget.textColor,
                    thumbShape: RoundSliderThumbShape(
                      enabledThumbRadius: widget.compact ? 5 : 6,
                    ),
                  ),
                  child: Slider(
                    value: displayedValue,
                    onChangeStart: hasDuration
                        ? (_) => widget.onInteractionStart()
                        : null,
                    onChanged: hasDuration
                        ? (value) {
                            setState(() {
                              _dragValue = value;
                            });
                          }
                        : null,
                    onChangeEnd: hasDuration
                        ? (value) async {
                            final target = Duration(
                              milliseconds: (duration.inMilliseconds * value)
                                  .round(),
                            );
                            await widget.onSeekRequested(target);
                            if (!mounted) {
                              return;
                            }
                            setState(() {
                              _dragValue = null;
                            });
                            widget.onInteractionEnd();
                          }
                        : null,
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _formatPlaybackDuration(displayedPosition),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: widget.textColor,
                        ),
                      ),
                    ),
                    Text(
                      hasDuration ? _formatPlaybackDuration(duration) : '',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: widget.textColor.withValues(alpha: 0.78),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _StageFrame extends StatelessWidget {
  const _StageFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black,
          border: Border.all(color: _playerOutline),
          boxShadow: const [
            BoxShadow(
              color: Color(0x3A000000),
              blurRadius: 30,
              offset: Offset(0, 18),
            ),
          ],
        ),
        child: child,
      ),
    );
  }
}

class _StageContent extends StatelessWidget {
  const _StageContent({
    required this.title,
    required this.message,
    required this.child,
  });

  final String title;
  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: _PlayerGlassPanel(
            backgroundColor: const Color(0x46101010),
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PlayerStateIcon(child: child),
                const SizedBox(height: 16),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    height: 1.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayerGlassPanel extends StatelessWidget {
  const _PlayerGlassPanel({
    required this.child,
    this.backgroundColor,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor ?? _playerOverlaySurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _playerOutline),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );
  }
}

class _PlayerStateIcon extends StatelessWidget {
  const _PlayerStateIcon({this.icon, this.child});

  final IconData? icon;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 62,
      height: 62,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: child ?? Icon(icon, color: Colors.white, size: 30),
    );
  }
}

class _RouteBackButton extends StatelessWidget {
  const _RouteBackButton({required this.onPressed});

  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: _OverlayIconButton(
        icon: Icons.arrow_back_rounded,
        onPressed: onPressed,
      ),
    );
  }
}

class _OverlayIconButton extends StatelessWidget {
  const _OverlayIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final Future<void> Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: SizedBox(
        width: 42,
        height: 42,
        child: IconButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            unawaited(onPressed());
          },
          icon: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

class _OverlayTransportButton extends StatelessWidget {
  const _OverlayTransportButton({
    required this.icon,
    required this.onPressed,
    this.isPrimary = false,
    this.compact = false,
  });

  final IconData icon;
  final Future<void> Function() onPressed;
  final bool isPrimary;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final dimension = switch ((isPrimary, compact)) {
      (true, true) => 58.0,
      (true, false) => 64.0,
      (false, true) => 46.0,
      (false, false) => 52.0,
    };
    final iconSize = switch ((isPrimary, compact)) {
      (true, true) => 28.0,
      (true, false) => 30.0,
      (false, true) => 20.0,
      (false, false) => 22.0,
    };

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: isPrimary
            ? const LinearGradient(
                colors: [Color(0xFFFF8F1F), Color(0xFFFF6A00)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              )
            : null,
        color: isPrimary ? null : Colors.white.withValues(alpha: 0.06),
        shape: BoxShape.circle,
        border: Border.all(
          color: isPrimary
              ? Colors.transparent
              : Colors.white.withValues(alpha: 0.08),
        ),
        boxShadow: isPrimary
            ? const [
                BoxShadow(
                  color: Color(0x45FF7A00),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: SizedBox(
        width: dimension,
        height: dimension,
        child: IconButton(
          padding: EdgeInsets.zero,
          onPressed: () {
            unawaited(onPressed());
          },
          icon: Icon(
            icon,
            color: isPrimary ? Colors.black : Colors.white,
            size: iconSize,
          ),
        ),
      ),
    );
  }
}

class _OverlayPill extends StatelessWidget {
  const _OverlayPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.34)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
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

String _formatPlaybackDuration(Duration duration) {
  final totalSeconds = duration.inSeconds;
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = totalSeconds % 60;

  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}
