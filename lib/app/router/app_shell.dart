import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme_tokens.dart';
import 'app_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppThemeTokens.background,
          border: Border(
            top: BorderSide(color: AppThemeTokens.outline, width: 1),
          ),
        ),
        child: SafeArea(
          top: false,
          minimum: const EdgeInsets.fromLTRB(12, 8, 12, 10),
          child: Row(
            children: [
              _NavItem(
                label: 'Home',
                icon: Icons.home_outlined,
                selectedIcon: Icons.home_rounded,
                isSelected: _selectedIndex == 0,
                onTap: () => _goTo(context, AppRoutePaths.home),
              ),
              const SizedBox(width: 8),
              _NavItem(
                label: 'Browse',
                icon: Icons.explore_outlined,
                selectedIcon: Icons.explore_rounded,
                isSelected: _selectedIndex == 1,
                onTap: () => _goTo(context, AppRoutePaths.browse),
              ),
              const SizedBox(width: 8),
              _NavItem(
                label: 'My Lists',
                icon: Icons.bookmarks_outlined,
                selectedIcon: Icons.bookmarks_rounded,
                isSelected: _selectedIndex == 2,
                onTap: () => _goTo(context, AppRoutePaths.myLists),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _goTo(BuildContext context, String targetLocation) {
    if (targetLocation == location) {
      return;
    }

    context.go(targetLocation);
  }

  int get _selectedIndex {
    if (location == AppRoutePaths.browse) {
      return 1;
    }

    if (location == AppRoutePaths.myLists) {
      return 2;
    }

    return 0;
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected
        ? AppThemeTokens.primary
        : AppThemeTokens.onSurfaceMuted;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppThemeTokens.primary.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              border: isSelected
                  ? Border.all(
                      color: AppThemeTokens.primary.withValues(alpha: 0.22),
                    )
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(isSelected ? selectedIcon : icon, color: color, size: 24),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
