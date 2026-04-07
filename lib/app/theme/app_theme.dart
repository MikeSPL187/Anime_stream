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
        letterSpacing: -0.6,
        color: Colors.white,
      ),
      headlineMedium: base.textTheme.headlineMedium?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: Colors.white,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
        color: Colors.white,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: Colors.white,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
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
        actionsIconTheme: const IconThemeData(color: Colors.white, size: 26),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF111111),
        indicatorColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelMedium?.copyWith(
            color: selected ? AppThemeTokens.primary : Colors.white,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppThemeTokens.primary : Colors.white,
            size: 26,
          );
        }),
        height: 72,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppThemeTokens.surfaceElevated,
        selectedColor: AppThemeTokens.primaryContainer,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppThemeTokens.chipRadius),
        ),
        labelStyle: textTheme.labelMedium?.copyWith(color: Colors.white),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppThemeTokens.surfaceElevated,
        hintStyle: textTheme.bodyMedium?.copyWith(
          color: AppThemeTokens.onSurfaceFaint,
        ),
        prefixIconColor: Colors.white,
        suffixIconColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
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
            width: 1.2,
          ),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppThemeTokens.primary,
          foregroundColor: Colors.black,
          minimumSize: const Size.fromHeight(52),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppThemeTokens.controlRadius),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: const BorderSide(color: AppThemeTokens.outline),
          minimumSize: const Size.fromHeight(48),
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
      ),
    );
  }
}
