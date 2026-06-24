import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Trixile "Obsidian" design system theme.
class AppTheme {
  AppTheme._();

  static ThemeData dark() => _buildTheme(Brightness.dark);
  static ThemeData light() => _buildTheme(Brightness.light);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colors = isDark ? AppColors.darkColorSet : AppColors.lightColorSet;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: colors.background,
      colorScheme: ColorScheme(
        brightness: brightness,
        surface: colors.surface,
        onSurface: colors.onSurface,
        primary: colors.primary,
        onPrimary: colors.onPrimary,
        primaryContainer: colors.primaryContainer,
        onPrimaryContainer: colors.onPrimaryContainer,
        secondary: colors.secondary,
        onSecondary: colors.onSecondary,
        secondaryContainer: colors.secondaryContainer,
        onSecondaryContainer: colors.onSecondaryContainer,
        tertiary: colors.tertiary,
        onTertiary: colors.onTertiary,
        error: colors.error,
        onError: colors.onError,
        errorContainer: colors.errorContainer,
        onErrorContainer: colors.onErrorContainer,
        outline: colors.outline,
        outlineVariant: colors.outlineVariant,
        inverseSurface: colors.inverseSurface,
        onInverseSurface: colors.inverseOnSurface,
        inversePrimary: colors.inversePrimary,
      ),
      fontFamily: 'ClanPro',
      textTheme: TextTheme(
        displayLarge: AppTypography.displayLg.copyWith(color: colors.onSurface),
        headlineLarge: AppTypography.headlineLg.copyWith(color: colors.onSurface),
        headlineMedium: AppTypography.headlineLgMobile.copyWith(color: colors.onSurface),
        headlineSmall: AppTypography.headlineMd.copyWith(color: colors.onSurface),
        titleLarge: AppTypography.titleLg.copyWith(color: colors.onSurface),
        titleMedium: AppTypography.titleMd.copyWith(color: colors.onSurface),
        bodyLarge: AppTypography.bodyLg.copyWith(color: colors.onSurface),
        bodyMedium: AppTypography.bodyMd.copyWith(color: colors.onSurface),
        labelLarge: AppTypography.labelMd.copyWith(color: colors.onSurface),
        labelSmall: AppTypography.labelSm.copyWith(color: colors.onSurface),
        bodySmall: AppTypography.caption.copyWith(color: colors.onSurfaceVariant),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: isDark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark,
        titleTextStyle: AppTypography.titleLg,
        iconTheme: IconThemeData(color: colors.primary),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.primary, width: 1.5),
        ),
        hintStyle: AppTypography.bodyLg.copyWith(
          color: colors.onSurfaceVariant.withValues(alpha: 0.5),
        ),
        labelStyle: AppTypography.labelMd.copyWith(
          color: colors.onSurfaceVariant,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          textStyle: AppTypography.titleMd,
          minimumSize: const Size(double.infinity, 52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.onSurface,
          side: BorderSide(color: colors.outlineVariant),
          textStyle: AppTypography.labelMd,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: colors.surfaceContainer,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isDark
                ? const Color(0x0AFFFFFF)
                : Colors.black.withValues(alpha: 0.04),
          ),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: DividerThemeData(
        color: colors.outlineVariant,
        thickness: 1,
        space: 0,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: AppTypography.labelMd,
        unselectedLabelStyle: AppTypography.labelMd,
      ),
    );
  }
}
