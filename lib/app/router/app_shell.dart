import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'app_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          final targetLocation = switch (index) {
            0 => AppRoutePaths.home,
            1 => AppRoutePaths.browse,
            2 => AppRoutePaths.search,
            3 => AppRoutePaths.myLists,
            4 => AppRoutePaths.settings,
            _ => AppRoutePaths.home,
          };

          if (targetLocation == location) {
            return;
          }

          context.go(targetLocation);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore_rounded),
            label: 'Browse',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search_rounded),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmarks_outlined),
            selectedIcon: Icon(Icons.bookmarks_rounded),
            label: 'My Lists',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }

  int get _selectedIndex {
    if (location == AppRoutePaths.browse) {
      return 1;
    }

    if (location == AppRoutePaths.search) {
      return 2;
    }

    if (location == AppRoutePaths.myLists) {
      return 3;
    }

    if (location == AppRoutePaths.settings) {
      return 4;
    }

    return 0;
  }
}
