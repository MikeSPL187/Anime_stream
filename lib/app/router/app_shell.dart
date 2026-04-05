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
            1 => AppRoutePaths.search,
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
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search_rounded),
            label: 'Search',
          ),
        ],
      ),
    );
  }

  int get _selectedIndex {
    if (location == AppRoutePaths.search) {
      return 1;
    }

    return 0;
  }
}
