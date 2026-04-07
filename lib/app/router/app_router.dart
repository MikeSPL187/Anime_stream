import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/browse/browse_screen.dart';
import '../../features/catalog/catalog_screen.dart';
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
            path: AppRoutePaths.search,
            builder: (context, state) => const SearchScreen(),
          ),
          GoRoute(
            path: AppRoutePaths.myLists,
            builder: (context, state) => const MyListsScreen(),
          ),
          GoRoute(
            path: AppRoutePaths.settings,
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
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
        builder: (context, state) {
          final sessionContext = state.extra is PlayerScreenContext
              ? state.extra as PlayerScreenContext
              : null;

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
    ],
  );
});

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

  static String seriesDetails(String id) => '/series/$id';
}
