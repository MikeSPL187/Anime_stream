import 'package:flutter/material.dart';

import 'app_theme_tokens.dart';

abstract final class AppTheme {
  static ThemeData get darkTheme {
    final colorScheme = ColorScheme.dark(
      brightness: Brightness.dark,
      primary: AppThemeTokens.primary,
      onPrimary: Colors.black,
      primaryContainer: AppThemeTokens.primaryContainer,
      onPrimaryContainer: Colors.white,
      secondary: const Color(0xFFFFA15C),
      onSecondary: Colors.black,
      tertiary: const Color(0xFFFFC28D),
      onTertiary: Colors.black,
      surface: AppThemeTokens.surface,
      onSurface: AppThemeTokens.onSurface,
      error: const Color(0xFFFF6B6B),
      onError: Colors.black,
      outline: AppThemeTokens.outlineStrong,
      surfaceContainerHighest: AppThemeTokens.surfaceMuted,
      surfaceContainerHigh: AppThemeTokens.surfaceElevated,
      surfaceContainerLow: AppThemeTokens.surface,
      onSurfaceVariant: AppThemeTokens.onSurfaceMuted,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppThemeTokens.background,
      canvasColor: AppThemeTokens.background,
      dividerColor: AppThemeTokens.outline,
      splashFactory: InkRipple.splashFactory,
    );

    final textTheme = base.textTheme.copyWith(
      headlineLarge: base.textTheme.headlineLarge?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.7,
        color: Colors.white,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.55,
        color: Colors.white,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.35,
        color: Colors.white,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.25,
        color: Colors.white,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.15,
        color: Colors.white,
      ),
      bodyLarge: base.textTheme.bodyLarge?.copyWith(
        color: Colors.white,
        height: 1.35,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(
        color: Colors.white,
        height: 1.35,
      ),
      bodySmall: base.textTheme.bodySmall?.copyWith(
        color: AppThemeTokens.onSurfaceMuted,
        height: 1.35,
      ),
      labelLarge: base.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
        color: Colors.white,
      ),
      labelMedium: base.textTheme.labelMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.1,
        color: AppThemeTokens.onSurfaceMuted,
      ),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppThemeTokens.background,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
        actionsIconTheme: const IconThemeData(color: Colors.white, size: 24),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF0D0D0D),
        indicatorColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            color: selected
                ? AppThemeTokens.primary
                : AppThemeTokens.onSurfaceMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected
                ? AppThemeTokens.primary
                : AppThemeTokens.onSurfaceMuted,
            size: 24,
          );
        }),
        height: 68,
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: AppThemeTokens.onSurfaceMuted,
        labelStyle: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        unselectedLabelStyle: textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppThemeTokens.onSurfaceMuted,
        ),
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: AppThemeTokens.primary, width: 2),
        ),
        indicatorSize: TabBarIndicatorSize.label,
        splashFactory: NoSplash.splashFactory,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppThemeTokens.surfaceMuted,
        selectedColor: AppThemeTokens.primaryContainer,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppThemeTokens.chipRadius),
        ),
        labelStyle: textTheme.labelMedium?.copyWith(color: Colors.white),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppThemeTokens.surfaceMuted,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: AppThemeTokens.onSurfaceFaint,
        ),
        prefixIconColor: Colors.white,
        suffixIconColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppThemeTokens.controlRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppThemeTokens.controlRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppThemeTokens.controlRadius),
          borderSide: const BorderSide(
            color: AppThemeTokens.primary,
            width: 1.1,
          ),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppThemeTokens.controlRadius),
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppThemeTokens.primary,
          foregroundColor: Colors.black,
          minimumSize: const Size.fromHeight(50),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppThemeTokens.controlRadius),
          ),
          textStyle: textTheme.titleMedium?.copyWith(
            color: Colors.black,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppThemeTokens.controlRadius),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: AppThemeTokens.outlineStrong),
          minimumSize: const Size.fromHeight(48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppThemeTokens.controlRadius),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppThemeTokens.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppThemeTokens.cardRadius),
        ),
        elevation: 0,
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(
        color: AppThemeTokens.outline,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppThemeTokens.surfaceElevated,
        contentTextStyle: textTheme.bodyMedium,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppThemeTokens.cardRadius),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppThemeTokens.primary,
        linearTrackColor: AppThemeTokens.outlineStrong,
      ),
    );
  }
}
