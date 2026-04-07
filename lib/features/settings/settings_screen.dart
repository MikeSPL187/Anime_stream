import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          const _SectionHeader(
            title: 'Playback',
            description:
                'Keep this route focused on real app behavior and utility controls, not service theater.',
          ),
          const SizedBox(height: 12),
          const _SurfaceGroup(
            children: [
              _SettingsInfoTile(
                icon: Icons.fullscreen_rounded,
                title: 'Fullscreen-first player',
                message:
                    'Handset playback opens as an immersive watch surface with fullscreen-aware route behavior.',
              ),
              Divider(height: 1),
              _SettingsInfoTile(
                icon: Icons.save_rounded,
                title: 'Automatic progress sync',
                message:
                    'Playback progress is stored automatically so Continue Watching and Series can restore your place.',
              ),
              Divider(height: 1),
              _SettingsInfoTile(
                icon: Icons.download_rounded,
                title: 'Offline downloads are active',
                message:
                    'Episode downloads are supported from the Series screen. A dedicated downloads destination is being hardened separately.',
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionHeader(
            title: 'Library shortcuts',
            description:
                'Jump directly into the list surfaces that already exist in the repository.',
          ),
          const SizedBox(height: 12),
          _SurfaceGroup(
            children: [
              _SettingsActionTile(
                icon: Icons.bookmarks_rounded,
                title: 'Open My Lists',
                message:
                    'Go to saved titles and completed watch history in one place.',
                onTap: () => context.go(AppRoutePaths.myLists),
              ),
              const Divider(height: 1),
              _SettingsActionTile(
                icon: Icons.bookmark_outline_rounded,
                title: 'Open Watchlist',
                message:
                    'Review titles you saved for later outside active playback.',
                onTap: () => context.push(AppRoutePaths.watchlist),
              ),
              const Divider(height: 1),
              _SettingsActionTile(
                icon: Icons.history_rounded,
                title: 'Open Watch History',
                message:
                    'Review completed viewing activity kept separate from Continue Watching.',
                onTap: () => context.push(AppRoutePaths.history),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const _SectionHeader(
            title: 'About this build',
            description:
                'Keep only the app truths that are real for this single-user product.',
          ),
          const SizedBox(height: 12),
          const _SurfaceGroup(
            children: [
              _SettingsInfoTile(
                icon: Icons.person_outline_rounded,
                title: 'Single-user anime app',
                message:
                    'This build intentionally excludes profiles, subscriptions, and service-scale account systems.',
              ),
              Divider(height: 1),
              _SettingsInfoTile(
                icon: Icons.cloud_outlined,
                title: 'AniLibria source of truth',
                message:
                    'Catalog discovery, series details, playback resolution, and offline packaging rely on AniLibria-backed flows.',
              ),
              Divider(height: 1),
              _SettingsInfoTile(
                icon: Icons.flag_outlined,
                title: 'Current corrective phase',
                message:
                    'Navigation and mobile primitives are being reset toward a tighter content-first streaming grammar.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
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
    );
  }
}

class _SurfaceGroup extends StatelessWidget {
  const _SurfaceGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsInfoTile extends StatelessWidget {
  const _SettingsInfoTile({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _IconTile(icon: icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: theme.textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  const _SettingsActionTile({
    required this.icon,
    required this.title,
    required this.message,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String message;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IconTile(icon: icon),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
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

class _IconTile extends StatelessWidget {
  const _IconTile({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: theme.colorScheme.primary),
    );
  }
}
