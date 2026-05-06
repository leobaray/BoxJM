import 'package:flutter/material.dart';

/// Paleta "Cockpit Edition" — Obsidiana + Ignição + Cromado.
///
/// Inspirada em painéis de carros premium (McLaren Artura, Porsche Taycan).
/// Três pilares: pretos profundos, brasa vermelha como ignição, linhas finas
/// cromadas.
class AppColors {
  AppColors._();

  // ── Surfaces ────────────────────────────────────────────────────────────
  static const obsidian = Color(0xFF06060A);
  static const graphite = Color(0xFF0E0E14);
  static const graphiteElev = Color(0xFF14141C);
  static const graphiteHigh = Color(0xFF1C1C26);

  // Legacy aliases still referenced across the app.
  static const background = obsidian;
  static const surface = graphiteElev;
  static const surfaceHigh = Color(0xFF26262E);
  static const surfaceSoft = graphite;

  // ── Borders ─────────────────────────────────────────────────────────────
  static const border = Color(0xFF22222C);
  static const borderSoft = Color(0xFF1A1A22);
  static const borderStrong = Color(0xFF35353D);

  /// Reflexo cromado — usar como borda superior ou topo de card.
  static const chromeEdge = Color(0x14FFFFFF);
  static const chromeEdgeStrong = Color(0x1FFFFFFF);

  // ── Brand / Ignição ─────────────────────────────────────────────────────
  static const ignition = Color(0xFFFF3B3B);
  static const ignitionBright = Color(0xFFFF6363);
  static const ignitionDeep = Color(0xFFB91C1C);

  /// Halo ambiente — usado em BoxShadow com blur alto.
  static const ember = Color(0x33FF3B3B);
  static const emberSoft = Color(0x1AFF3B3B);

  // Legacy aliases still referenced across the app.
  static const primary = ignition;
  static const primaryTint = Color(0x1FFF3B3B);
  static const primaryTintSoft = emberSoft;

  // ── Accent ──────────────────────────────────────────────────────────────
  static const accent = Color(0xFFF59E0B);

  // ── Text ────────────────────────────────────────────────────────────────
  static const textPrimary = Color(0xFFFAFAFA);
  static const textSecondary = Color(0xFFA1A1AA);
  static const textMuted = Color(0xFF71717A);
  static const textSoft = Color(0xFFE4E4E7);

  // ── Status ──────────────────────────────────────────────────────────────
  static const statusDraft = Color(0xFF8B8B93);
  static const statusSent = Color(0xFF3B82F6);
  static const statusApproved = Color(0xFF10B981);
  static const statusCompleted = Color(0xFF8B5CF6);

  // ── Gradientes ──────────────────────────────────────────────────────────
  /// Ignição: vermelho vivo → profundo. Use em CTAs, FAB, logos.
  static const ignitionGradient = LinearGradient(
    colors: [Color(0xFFFF6363), Color(0xFFE11D48), Color(0xFF7A0F0F)],
    stops: [0.0, 0.55, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Cromo frio — para highlights metálicos em valores, títulos de hero.
  static const chromeGradient = LinearGradient(
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFCFCFD8),
      Color(0xFFFFFFFF),
      Color(0xFFA8A8B2),
    ],
    stops: [0.0, 0.35, 0.7, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Hairline cromado — fine line com brilho no centro.
  static const hairlineGradient = LinearGradient(
    colors: [
      Color(0x00FFFFFF),
      Color(0x1FFFFFFF),
      Color(0x00FFFFFF),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  /// Glass / obsidiana translúcida — base dos docks e sheets com blur.
  static const glassGradient = LinearGradient(
    colors: [Color(0xB31A1A24), Color(0xB30E0E14)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Painel de cockpit — gradiente vertical pra header.
  static const cockpitGradient = LinearGradient(
    colors: [Color(0xFF14141C), Color(0xFF08080C)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Halo radial em torno de um accent (para FAB, selos).
  static RadialGradient halo(Color c, {double alpha = 0.45}) => RadialGradient(
        colors: [c.withValues(alpha: alpha), c.withValues(alpha: 0.0)],
        stops: const [0.0, 1.0],
      );
}

/// Colors helpers for working with [Color] values.
extension AppColorX on Color {
  /// Darken a color by blending with pure black.
  Color darken([double amount = 0.15]) =>
      Color.lerp(this, const Color(0xFF000000), amount) ?? this;

  /// Lighten a color by blending with pure white.
  Color lighten([double amount = 0.15]) =>
      Color.lerp(this, const Color(0xFFFFFFFF), amount) ?? this;
}
