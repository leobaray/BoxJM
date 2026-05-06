import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typographic scale for BOX JM.
///
/// One source of truth for every text style used in the app. Keep all
/// inline [TextStyle] declarations out of widgets — reach for a named
/// getter here instead so hierarchy stays consistent and a single tweak
/// ripples through the whole UI.
class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = 'Inter';

  static TextStyle _base(
    double size, {
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.textPrimary,
    double? letterSpacing,
    double? height,
    TextDecoration? decoration,
  }) =>
      TextStyle(
        fontFamily: fontFamily,
        fontSize: size,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
        decoration: decoration,
      );

  // ── Display (hero totals) ───────────────────────────────────────────
  static TextStyle displayTotal = _base(
    30,
    weight: FontWeight.w900,
    color: Colors.white,
    letterSpacing: -0.8,
    height: 1,
  );

  // ── Titles ──────────────────────────────────────────────────────────
  static TextStyle sectionTitle = _base(
    16,
    weight: FontWeight.w800,
    letterSpacing: -0.2,
  );

  static TextStyle cardTitle = _base(
    18,
    weight: FontWeight.w700,
    letterSpacing: -0.2,
  );

  static TextStyle cardClient = _base(
    20,
    weight: FontWeight.w800,
    letterSpacing: -0.4,
  );

  // ── Money ───────────────────────────────────────────────────────────
  static TextStyle moneyInline = _base(
    15,
    weight: FontWeight.w800,
    color: AppColors.primary,
    letterSpacing: -0.2,
  );

  // ── Body ────────────────────────────────────────────────────────────
  static TextStyle bodyStrong = _base(14, weight: FontWeight.w700);

  static TextStyle bodyMuted = _base(
    13,
    weight: FontWeight.w500,
    color: AppColors.textSecondary,
    height: 1.4,
  );

  // ── Labels ──────────────────────────────────────────────────────────
  static TextStyle labelMuted = _base(
    12,
    weight: FontWeight.w600,
    color: AppColors.textMuted,
    letterSpacing: 0.2,
  );

  static TextStyle sectionEyebrow = _base(
    11,
    weight: FontWeight.w800,
    color: AppColors.textMuted,
    letterSpacing: 1.4,
  );
}
