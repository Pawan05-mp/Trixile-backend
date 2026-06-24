import 'package:flutter/material.dart';

class AppTypography {
  AppTypography._();

  // Geist → ClanPro (bundled), JetBrains Mono for labels
  static const String _geist = 'ClanPro';
  static const String _mono = 'JetBrainsMono';

  // Display
  static const TextStyle displayLg = TextStyle(
    fontFamily: _geist,
    fontSize: 48,
    fontWeight: FontWeight.w600,
    height: 56 / 48,
    letterSpacing: -0.02 * 48,
  );

  // Headline
  static const TextStyle headlineLg = TextStyle(
    fontFamily: _geist,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 40 / 32,
    letterSpacing: -0.01 * 32,
  );

  static const TextStyle headlineLgMobile = TextStyle(
    fontFamily: _geist,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 32 / 24,
  );

  static const TextStyle headlineMd = TextStyle(
    fontFamily: _geist,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 28 / 20,
  );

  // Title
  static const TextStyle titleLg = TextStyle(
    fontFamily: _geist,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 28 / 20,
  );

  static const TextStyle titleMd = TextStyle(
    fontFamily: _geist,
    fontSize: 18,
    fontWeight: FontWeight.w500,
    height: 24 / 18,
  );

  // Body
  static const TextStyle bodyLg = TextStyle(
    fontFamily: _geist,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 24 / 16,
  );

  static const TextStyle bodyMd = TextStyle(
    fontFamily: _geist,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 20 / 14,
  );

  // Label (JetBrains Mono)
  static const TextStyle labelMd = TextStyle(
    fontFamily: _mono,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 16 / 12,
    letterSpacing: 0.05 * 12,
  );

  static const TextStyle labelSm = TextStyle(
    fontFamily: _mono,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 16 / 11,
    letterSpacing: 0.05 * 11,
  );

  // Section header
  static const TextStyle sectionHeader = TextStyle(
    fontFamily: _geist,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    height: 24 / 16,
  );

  // Caption / overline
  static const TextStyle caption = TextStyle(
    fontFamily: _mono,
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
  );
}
