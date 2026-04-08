import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/browse/browse_screen.dart';
import '../../features/catalog/catalog_screen.dart';
import '../../features/downloads/downloads_screen.dart';
import '../../features/history/history_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/my_lists/my_lists_screen.dart';
import '../../features/player/player_screen.dart';
import '../../features/player/player_screen_context.dart';
import '../../features/search/search_screen.dart';
import '../../features/series/series_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/watchlist/watchlist_screen.dart';
import 'app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutePaths.home,
    errorBuilder: (context, state) {
      return _UnknownRouteScreen(attemptedPath: state.uri.path);
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(location: state.uri.path, child: child);
        },
        routes: [
          GoRoute(
            path: AppRoutePaths.home,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutePaths.browse,
            builder: (context, state) => const BrowseScreen(),
          ),
          GoRoute(
            path: AppRoutePaths.myLists,
            builder: (context, state) => const MyListsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutePaths.search,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.series,
        builder: (context, state) {
          final seriesId = state.pathParameters['id']!;
          return SeriesScreen(seriesId: seriesId);
        },
      ),
      GoRoute(
        path: AppRoutePaths.player,
        redirect: (context, state) {
          if (state.extra is! PlayerScreenContext) {
            return AppRoutePaths.home;
          }
          return null;
        },
        builder: (context, state) {
          final sessionContext = state.extra as PlayerScreenContext;
          return PlayerScreen(sessionContext: sessionContext);
        },
      ),
      GoRoute(
        path: AppRoutePaths.watchlist,
        builder: (context, state) => const WatchlistScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.catalog,
        builder: (context, state) => const CatalogScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.history,
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.downloads,
        builder: (context, state) => const DownloadsScreen(),
      ),
    ],
  );
});

class _UnknownRouteScreen extends StatelessWidget {
  const _UnknownRouteScreen({required this.attemptedPath});

  final String attemptedPath;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trimmedPath = attemptedPath.trim();

    return Scaffold(
      appBar: AppBar(title: const Text('Route unavailable')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    Icons.explore_off_rounded,
                    size: 36,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'This screen is unavailable',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'The requested route could not be opened. Return to Home and continue from a valid entry point.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (trimmedPath.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      trimmedPath,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => context.go(AppRoutePaths.home),
                    icon: const Icon(Icons.home_rounded),
                    label: const Text('Open Home'),
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

abstract final class AppRoutePaths {
  static const home = '/';
  static const browse = '/browse';
  static const search = '/search';
  static const myLists = '/my-lists';
  static const settings = '/settings';
  static const series = '/series/:id';
  static const player = '/player';
  static const watchlist = '/watchlist';
  static const catalog = '/catalog';
  static const history = '/history';
  static const downloads = '/downloads';

  static String seriesDetails(String id) => '/series/$id';
}
