import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/home_screen.dart';
import '../../features/player/player_screen.dart';
import '../../features/search/search_screen.dart';
import '../../features/series/series_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutePaths.home,
    routes: [
      GoRoute(
        path: AppRoutePaths.home,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutePaths.search,
        builder: (context, state) => const SearchScreen(),
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
    ],
  );
});

abstract final class AppRoutePaths {
  static const home = '/';
  static const search = '/search';
  static const series = '/series/:id';
  static const player = '/player';

  static String seriesDetails(String id) => '/series/$id';
}
