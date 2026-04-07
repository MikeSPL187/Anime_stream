import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/router/app_router.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _SettingsHeroCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Personal Anime App', style: theme.textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  'A minimal single-user settings surface for app behavior, library shortcuts, and product information.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SettingsBadge(
                      label: 'Single user',
                      color: theme.colorScheme.primary,
                    ),
                    _SettingsBadge(
                      label: 'AniLibria source',
                      color: theme.colorScheme.secondary,
                    ),
                    _SettingsBadge(
                      label: 'No subscriptions',
                      color: theme.colorScheme.tertiary,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: 'Playback',
            description:
                'Current playback behavior that is already backed by the app today.',
            child: Column(
              children: const [
                _SettingsInfoTile(
                  icon: Icons.fullscreen_rounded,
                  title: 'Fullscreen-first player',
                  message:
                      'Handset playback opens as an immersive watch surface with fullscreen-aware behavior.',
                ),
                Divider(height: 1),
                _SettingsInfoTile(
                  icon: Icons.save_rounded,
                  title: 'Automatic progress sync',
                  message:
                      'Playback progress is stored automatically so Continue Watching can resume from your saved position.',
                ),
                Divider(height: 1),
                _SettingsInfoTile(
                  icon: Icons.check_circle_outline_rounded,
                  title: 'Watched state control',
                  message:
                      'Episode watched and unwatched actions are managed from the Series screen.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: 'Library shortcuts',
            description:
                'Jump directly into the backed library surfaces you already use.',
            child: Column(
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
          ),
          const SizedBox(height: 24),
          _SettingsSection(
            title: 'About the app',
            description:
                'This surface stays intentionally light and avoids a fake account center.',
            child: Column(
              children: const [
                _SettingsInfoTile(
                  icon: Icons.stream_rounded,
                  title: 'Anime Stream',
                  message: 'Version 0.1.0 • Built as a personal anime streaming app.',
                ),
                Divider(height: 1),
                _SettingsInfoTile(
                  icon: Icons.cloud_outlined,
                  title: 'Data source',
                  message:
                      'Catalog discovery and playback resolution are backed by AniLibria-based flows in the current app.',
                ),
                Divider(height: 1),
                _SettingsInfoTile(
                  icon: Icons.block_rounded,
                  title: 'Deliberately omitted',
                  message:
                      'Profiles, subscriptions, downloads, games, and heavy account systems are intentionally out of scope for this product.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({
    required this.title,
    required this.description,
    required this.child,
  });

  final String title;
  final String description;
  final Widget child;

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
        const SizedBox(height: 12),
        _SettingsSurfaceCard(child: child),
      ],
    );
  }
}

class _SettingsHeroCard extends StatelessWidget {
  const _SettingsHeroCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return _SettingsSurfaceCard(
      backgroundColor: theme.colorScheme.primaryContainer.withValues(alpha: 0.16),
      child: child,
    );
  }
}

class _SettingsSurfaceCard extends StatelessWidget {
  const _SettingsSurfaceCard({required this.child, this.backgroundColor});

  final Widget child;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: child,
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
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: theme.colorScheme.primary),
          ),
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
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: theme.colorScheme.primary),
              ),
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

class _SettingsBadge extends StatelessWidget {
  const _SettingsBadge({required this.label, required this.color});

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
