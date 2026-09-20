import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF2F6D5B);
  static const primaryContainer = Color(0xFFE4F0EA);
  static const background = Color(0xFFF6F8F6);
  static const surface = Color(0xFFFFFFFF);
  static const outline = Color(0xFFD8E2DC);
  static const onSurface = Color(0xFF1B2620);
  static const onSurfaceVariant = Color(0xFF5B6B62);
  static const error = Color(0xFFB3452C);
}

ThemeData buildAppTheme() {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.primary,
    primaryContainer: AppColors.primaryContainer,
    surface: AppColors.surface,
    error: AppColors.error,
    onSurfaceVariant: AppColors.onSurfaceVariant,
    outline: AppColors.outline,
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.onSurface,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: AppColors.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.outline),
      ),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.outline,
      thickness: 1,
      space: 1,
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: AppColors.primary,
      textColor: AppColors.onSurface,
    ),
    textTheme: const TextTheme(
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
      ),
      titleMedium: TextStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: AppColors.onSurface),
      bodyMedium: TextStyle(fontSize: 14, color: AppColors.onSurface),
      bodySmall: TextStyle(fontSize: 13, color: AppColors.onSurfaceVariant),
      labelLarge: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.onSurfaceVariant,
        letterSpacing: 0.2,
      ),
    ),
  );
}