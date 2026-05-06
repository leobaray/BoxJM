/// Spacing tokens — 4pt grid baseline.
class AppSpacing {
  AppSpacing._();

  static const double lg = 16;
  static const double xl = 20;

  // Reserva inferior: dock (68) + gap (12) + FAB overshoot (24) + safe.
  // Conteúdo usa este valor pra não ficar por trás do dock + FAB.
  static const double navReserved = 120;

  // Altura nominal do dock (sem FAB).
  static const double dockHeight = 68;

  // Tamanho do FAB de ignição.
  static const double fabSize = 64;
}

/// Border-radius tokens — "cockpit" usa curvas mais generosas que o legado.
class AppRadius {
  AppRadius._();

  static const double sm = 10;
  static const double md = 12;
  static const double lg = 14;
  static const double xl = 18;
  static const double xxl = 22;
  static const double xxxl = 28;
  static const double dock = 34;
  static const double pill = 999;
}

/// Durações padrão de animação.
class AppMotion {
  AppMotion._();

  static const Duration fast = Duration(milliseconds: 180);
  static const Duration base = Duration(milliseconds: 240);
  static const Duration slow = Duration(milliseconds: 360);
  static const Duration breath = Duration(milliseconds: 2000);
}
