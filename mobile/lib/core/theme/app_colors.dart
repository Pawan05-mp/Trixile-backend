import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Surface tiers
  static const Color background = Color(0xFF121416);
  static const Color surface = Color(0xFF121416);
  static const Color surfaceDim = Color(0xFF121416);
  static const Color surfaceBright = Color(0xFF37393B);
  static const Color surfaceContainerLowest = Color(0xFF0C0E10);
  static const Color surfaceContainerLow = Color(0xFF1A1C1E);
  static const Color surfaceContainer = Color(0xFF1E2022);
  static const Color surfaceContainerHigh = Color(0xFF282A2C);
  static const Color surfaceContainerHighest = Color(0xFF333537);
  static const Color surfaceVariant = Color(0xFF333537);

  // On-surface
  static const Color onSurface = Color(0xFFE2E2E5);
  static const Color onSurfaceVariant = Color(0xFFC6C7BF);
  static const Color inverseSurface = Color(0xFFE2E2E5);
  static const Color inverseOnSurface = Color(0xFF2F3133);

  // Outline
  static const Color outline = Color(0xFF90918A);
  static const Color outlineVariant = Color(0xFF454841);

  // Primary
  static const Color primary = Color(0xFFE0E4D5);
  static const Color onPrimary = Color(0xFF2D3228);
  static const Color primaryContainer = Color(0xFFC4C8BA);
  static const Color onPrimaryContainer = Color(0xFF4F5449);
  static const Color inversePrimary = Color(0xFF5C6055);
  static const Color primaryFixed = Color(0xFFE0E4D6);
  static const Color primaryFixedDim = Color(0xFFC4C8BA);

  // Secondary
  static const Color secondary = Color(0xFFC4C8BB);
  static const Color onSecondary = Color(0xFF2D3229);
  static const Color secondaryContainer = Color(0xFF43483E);
  static const Color onSecondaryContainer = Color(0xFFB2B7AA);

  // Tertiary
  static const Color tertiary = Color(0xFFF0DEE4);
  static const Color onTertiary = Color(0xFF382D32);
  static const Color tertiaryContainer = Color(0xFFD3C2C8);
  static const Color onTertiaryContainer = Color(0xFF5B4F54);

  // Error
  static const Color error = Color(0xFFFFB4AB);
  static const Color onError = Color(0xFF690005);
  static const Color errorContainer = Color(0xFF93000A);
  static const Color onErrorContainer = Color(0xFFFFDAD6);

  // Occasion accent colours
  static const Color dateNight = Color(0xFFEC4899);   // pink-500
  static const Color friends = Color(0xFF3B82F6);      // blue-500
  static const Color family = Color(0xFF10B981);       // emerald-500
  static const Color solo = Color(0xFFA855F7);         // purple-500

  // Utility
  static const Color star = Color(0xFFFFB800);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // Glass overlay
  static Color glass = const Color(0xFF1A1C1E).withValues(alpha: 0.85);

  // ── Light surface palette ──────────────────────────────────────────────
  static const lightBackground = Color(0xFFF8F9FA);
  static const lightSurface = Color(0xFFF8F9FA);
  static const lightSurfaceDim = Color(0xFFD8D9DD);
  static const lightSurfaceBright = Color(0xFFF8F9FA);
  static const lightSurfaceContainerLowest = Color(0xFFFFFFFF);
  static const lightSurfaceContainerLow = Color(0xFFF3F4F7);
  static const lightSurfaceContainer = Color(0xFFEEEFF2);
  static const lightSurfaceContainerHigh = Color(0xFFE3E4E8);
  static const lightSurfaceContainerHighest = Color(0xFFD8D9DD);
  static const lightSurfaceVariant = Color(0xFFE0E4D6);

  static const lightOnSurface = Color(0xFF1A1C1E);
  static const lightOnSurfaceVariant = Color(0xFF44483D);
  static const lightInverseSurface = Color(0xFF2F3133);
  static const lightInverseOnSurface = Color(0xFFE2E2E5);

  static const lightOutline = Color(0xFF74796C);
  static const lightOutlineVariant = Color(0xFFC4C8BB);

  // Light brand
  static const lightPrimary = Color(0xFF5C6055);
  static const lightOnPrimary = Color(0xFFE0E4D5);
  static const lightPrimaryContainer = Color(0xFFC4C8BA);
  static const lightOnPrimaryContainer = Color(0xFF2D3228);
  static const lightInversePrimary = Color(0xFFC4C8BA);

  static const lightSecondary = Color(0xFF5C6057);
  static const lightOnSecondary = Color(0xFFC4C8BB);
  static const lightSecondaryContainer = Color(0xFFB2B7AA);
  static const lightOnSecondaryContainer = Color(0xFF43483E);

  static const lightTertiary = Color(0xFF6B5A62);
  static const lightOnTertiary = Color(0xFFF0DEE4);
  static const lightTertiaryContainer = Color(0xFFD3C2C8);
  static const lightOnTertiaryContainer = Color(0xFF382D32);

  static const lightError = Color(0xFFBA1A1A);
  static const lightOnError = Color(0xFFFFFFFF);
  static const lightErrorContainer = Color(0xFFFFDAD6);
  static const lightOnErrorContainer = Color(0xFF410002);

  // Light glass
  static Color lightGlass = const Color(0xFFF8F9FA).withValues(alpha: 0.85);

  // ── Color sets for theme builder ─────────────────────────────────────────
  static const ColorSet darkColorSet = ColorSet(
    background: background,
    surface: surface,
    surfaceDim: surfaceDim,
    surfaceBright: surfaceBright,
    surfaceContainerLowest: surfaceContainerLowest,
    surfaceContainerLow: surfaceContainerLow,
    surfaceContainer: surfaceContainer,
    surfaceContainerHigh: surfaceContainerHigh,
    surfaceContainerHighest: surfaceContainerHighest,
    surfaceVariant: surfaceVariant,
    onSurface: onSurface,
    onSurfaceVariant: onSurfaceVariant,
    inverseSurface: inverseSurface,
    inverseOnSurface: inverseOnSurface,
    outline: outline,
    outlineVariant: outlineVariant,
    primary: primary,
    onPrimary: onPrimary,
    primaryContainer: primaryContainer,
    onPrimaryContainer: onPrimaryContainer,
    inversePrimary: inversePrimary,
    secondary: secondary,
    onSecondary: onSecondary,
    secondaryContainer: secondaryContainer,
    onSecondaryContainer: onSecondaryContainer,
    tertiary: tertiary,
    onTertiary: onTertiary,
    tertiaryContainer: tertiaryContainer,
    onTertiaryContainer: onTertiaryContainer,
    error: error,
    onError: onError,
    errorContainer: errorContainer,
    onErrorContainer: onErrorContainer,
  );

  static const ColorSet lightColorSet = ColorSet(
    background: lightBackground,
    surface: lightSurface,
    surfaceDim: lightSurfaceDim,
    surfaceBright: lightSurfaceBright,
    surfaceContainerLowest: lightSurfaceContainerLowest,
    surfaceContainerLow: lightSurfaceContainerLow,
    surfaceContainer: lightSurfaceContainer,
    surfaceContainerHigh: lightSurfaceContainerHigh,
    surfaceContainerHighest: lightSurfaceContainerHighest,
    surfaceVariant: lightSurfaceVariant,
    onSurface: lightOnSurface,
    onSurfaceVariant: lightOnSurfaceVariant,
    inverseSurface: lightInverseSurface,
    inverseOnSurface: lightInverseOnSurface,
    outline: lightOutline,
    outlineVariant: lightOutlineVariant,
    primary: lightPrimary,
    onPrimary: lightOnPrimary,
    primaryContainer: lightPrimaryContainer,
    onPrimaryContainer: lightOnPrimaryContainer,
    inversePrimary: lightInversePrimary,
    secondary: lightSecondary,
    onSecondary: lightOnSecondary,
    secondaryContainer: lightSecondaryContainer,
    onSecondaryContainer: lightOnSecondaryContainer,
    tertiary: lightTertiary,
    onTertiary: lightOnTertiary,
    tertiaryContainer: lightTertiaryContainer,
    onTertiaryContainer: lightOnTertiaryContainer,
    error: lightError,
    onError: lightOnError,
    errorContainer: lightErrorContainer,
    onErrorContainer: lightOnErrorContainer,
  );
}

/// Structured color set used by [AppTheme._buildTheme].
class ColorSet {
  final Color background, surface, surfaceDim, surfaceBright;
  final Color surfaceContainerLowest, surfaceContainerLow, surfaceContainer;
  final Color surfaceContainerHigh, surfaceContainerHighest, surfaceVariant;
  final Color onSurface, onSurfaceVariant;
  final Color inverseSurface, inverseOnSurface;
  final Color outline, outlineVariant;
  final Color primary, onPrimary, primaryContainer, onPrimaryContainer, inversePrimary;
  final Color secondary, onSecondary, secondaryContainer, onSecondaryContainer;
  final Color tertiary, onTertiary, tertiaryContainer, onTertiaryContainer;
  final Color error, onError, errorContainer, onErrorContainer;

  const ColorSet({
    required this.background,
    required this.surface,
    required this.surfaceDim,
    required this.surfaceBright,
    required this.surfaceContainerLowest,
    required this.surfaceContainerLow,
    required this.surfaceContainer,
    required this.surfaceContainerHigh,
    required this.surfaceContainerHighest,
    required this.surfaceVariant,
    required this.onSurface,
    required this.onSurfaceVariant,
    required this.inverseSurface,
    required this.inverseOnSurface,
    required this.outline,
    required this.outlineVariant,
    required this.primary,
    required this.onPrimary,
    required this.primaryContainer,
    required this.onPrimaryContainer,
    required this.inversePrimary,
    required this.secondary,
    required this.onSecondary,
    required this.secondaryContainer,
    required this.onSecondaryContainer,
    required this.tertiary,
    required this.onTertiary,
    required this.tertiaryContainer,
    required this.onTertiaryContainer,
    required this.error,
    required this.onError,
    required this.errorContainer,
    required this.onErrorContainer,
  });
}
