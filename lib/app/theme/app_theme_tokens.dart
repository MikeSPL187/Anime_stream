import 'package:flutter/material.dart';

abstract final class AppThemeTokens {
  static const background = Color(0xFF070707);
  static const surface = Color(0xFF101010);
  static const surfaceElevated = Color(0xFF141414);
  static const surfaceMuted = Color(0xFF181818);

  static const outline = Color(0x1FFFFFFF);
  static const outlineStrong = Color(0x33FFFFFF);

  static const primary = Color(0xFFFF6B00);
  static const primaryPressed = Color(0xFFE65F00);
  static const primaryContainer = Color(0xFF2B1608);

  static const onBackground = Colors.white;
  static const onSurface = Colors.white;
  static const onSurfaceMuted = Color(0xFFB8B8B8);
  static const onSurfaceFaint = Color(0xFF8D8D8D);

  static const pagePadding = 16.0;
  static const cardRadius = 16.0;
  static const controlRadius = 14.0;
  static const chipRadius = 999.0;
  static const railGap = 10.0;

  static const pageTopGap = 12.0;
  static const sectionGap = 24.0;
}
