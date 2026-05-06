import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Sombras "Cockpit" — estruturadas em 3 camadas (ambient + key + rim).
///
/// Regra geral:
/// - `ambient`: blur grande, offset alto, alpha baixo — simula luz difusa.
/// - `key`: blur médio, offset curto, alpha médio — sombra direta.
/// - `rim`: inset branco sutil (via border + chromeEdge) — brilho de metal.
class AppShadows {
  AppShadows._();

  /// Elevação leve — chips, inputs em repouso.
  static const List<BoxShadow> sm = [
    BoxShadow(
      color: Color(0x40000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  /// Elevação padrão de cards.
  static const List<BoxShadow> md = [
    BoxShadow(
      color: Color(0x52000000),
      blurRadius: 18,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  /// Elevação alta — dock, sheets, FAB em repouso.
  static const List<BoxShadow> lg = [
    BoxShadow(
      color: Color(0x66000000),
      blurRadius: 32,
      offset: Offset(0, 16),
    ),
    BoxShadow(
      color: Color(0x40000000),
      blurRadius: 8,
      offset: Offset(0, 4),
    ),
  ];

  /// Halo de ignição — use atrás do FAB e em botões primários.
  static List<BoxShadow> ignition({double intensity = 1.0}) => [
        BoxShadow(
          color: AppColors.ignition.withValues(alpha: 0.28 * intensity),
          blurRadius: 24,
          spreadRadius: 1,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: AppColors.ignition.withValues(alpha: 0.18 * intensity),
          blurRadius: 48,
          spreadRadius: 4,
          offset: const Offset(0, 4),
        ),
      ];

  /// Halo de status — glow colorido pra chips selecionados.
  static List<BoxShadow> statusGlow(Color c, {double intensity = 1.0}) => [
        BoxShadow(
          color: c.withValues(alpha: 0.16 * intensity),
          blurRadius: 8,
          spreadRadius: 0,
          offset: const Offset(0, 2),
        ),
      ];
}
