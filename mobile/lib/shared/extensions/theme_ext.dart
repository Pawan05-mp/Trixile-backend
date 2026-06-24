import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

extension TrixileTheme on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // Surface
  Color get surface =>
      isDark ? AppColors.surface : AppColors.lightSurface;
  Color get surfaceDim =>
      isDark ? AppColors.surfaceDim : AppColors.lightSurfaceDim;
  Color get surfaceBright =>
      isDark ? AppColors.surfaceBright : AppColors.lightSurfaceBright;
  Color get surfaceContainerLowest =>
      isDark ? AppColors.surfaceContainerLowest : AppColors.lightSurfaceContainerLowest;
  Color get surfaceContainerLow =>
      isDark ? AppColors.surfaceContainerLow : AppColors.lightSurfaceContainerLow;
  Color get surfaceContainer =>
      isDark ? AppColors.surfaceContainer : AppColors.lightSurfaceContainer;
  Color get surfaceContainerHigh =>
      isDark ? AppColors.surfaceContainerHigh : AppColors.lightSurfaceContainerHigh;
  Color get surfaceContainerHighest =>
      isDark ? AppColors.surfaceContainerHighest : AppColors.lightSurfaceContainerHighest;
  Color get surfaceVariant =>
      isDark ? AppColors.surfaceVariant : AppColors.lightSurfaceVariant;

  // On-surface
  Color get onSurface =>
      isDark ? AppColors.onSurface : AppColors.lightOnSurface;
  Color get onSurfaceVariant =>
      isDark ? AppColors.onSurfaceVariant : AppColors.lightOnSurfaceVariant;
  Color get inverseSurface =>
      isDark ? AppColors.inverseSurface : AppColors.lightInverseSurface;
  Color get inverseOnSurface =>
      isDark ? AppColors.inverseOnSurface : AppColors.lightInverseOnSurface;

  // Outline
  Color get outline =>
      isDark ? AppColors.outline : AppColors.lightOutline;
  Color get outlineVariant =>
      isDark ? AppColors.outlineVariant : AppColors.lightOutlineVariant;

  // Primary
  Color get primary =>
      isDark ? AppColors.primary : AppColors.lightPrimary;
  Color get onPrimary =>
      isDark ? AppColors.onPrimary : AppColors.lightOnPrimary;
  Color get primaryContainer =>
      isDark ? AppColors.primaryContainer : AppColors.lightPrimaryContainer;
  Color get onPrimaryContainer =>
      isDark ? AppColors.onPrimaryContainer : AppColors.lightOnPrimaryContainer;
  Color get inversePrimary =>
      isDark ? AppColors.inversePrimary : AppColors.lightInversePrimary;

  // Secondary
  Color get secondary =>
      isDark ? AppColors.secondary : AppColors.lightSecondary;
  Color get onSecondary =>
      isDark ? AppColors.onSecondary : AppColors.lightOnSecondary;
  Color get secondaryContainer =>
      isDark ? AppColors.secondaryContainer : AppColors.lightSecondaryContainer;
  Color get onSecondaryContainer =>
      isDark ? AppColors.onSecondaryContainer : AppColors.lightOnSecondaryContainer;

  // Tertiary
  Color get tertiary =>
      isDark ? AppColors.tertiary : AppColors.lightTertiary;
  Color get onTertiary =>
      isDark ? AppColors.onTertiary : AppColors.lightOnTertiary;
  Color get tertiaryContainer =>
      isDark ? AppColors.tertiaryContainer : AppColors.lightTertiaryContainer;
  Color get onTertiaryContainer =>
      isDark ? AppColors.onTertiaryContainer : AppColors.lightOnTertiaryContainer;

  // Error
  Color get error =>
      isDark ? AppColors.error : AppColors.lightError;
  Color get onError =>
      isDark ? AppColors.onError : AppColors.lightOnError;
  Color get errorContainer =>
      isDark ? AppColors.errorContainer : AppColors.lightErrorContainer;
  Color get onErrorContainer =>
      isDark ? AppColors.onErrorContainer : AppColors.lightOnErrorContainer;

  // Glass
  Color get glass =>
      isDark ? AppColors.glass : AppColors.lightGlass;
  Color get dividerColor =>
      isDark ? Colors.white.withValues(alpha: 0.07) : Colors.black.withValues(alpha: 0.08);
  Color get shadowColor =>
      isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.10);
}
