import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';

/// Dock flutuante "Ignição" — 2 abas + FAB central sobreposto.
///
/// - As abas ficam dentro de um pill translúcido com blur (glassmorphism).
/// - O FAB é um círculo ignitado que flutua 24px acima do dock.
/// - Um entalhe (notch) no topo do dock "abraça" o FAB.
class IgnitionDock extends StatelessWidget {
  const IgnitionDock({
    super.key,
    required this.items,
    required this.index,
    required this.onTap,
    required this.onFabTap,
    required this.fabIcon,
    required this.fabLabel,
    this.fabActive = false,
  });

  /// As 2 abas laterais. Index 0 à esquerda, 1 à direita.
  final List<DockItem> items;

  /// Índice selecionado (0 ou 1). Use -1 para indicar FAB ativo.
  final int index;

  final ValueChanged<int> onTap;
  final VoidCallback onFabTap;
  final IconData fabIcon;
  final String fabLabel;

  /// Quando o FAB representa a rota atual (ex: na página /new).
  final bool fabActive;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    return SafeArea(
      top: false,
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 0, 16, 14 + bottom),
        child: SizedBox(
          height: AppSpacing.dockHeight + 28,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.bottomCenter,
            children: [
              Positioned.fill(child: _DockBody(
                items: items,
                index: index,
                onTap: onTap,
              )),
              Positioned(
                top: 0,
                child: _IgnitionFab(
                  icon: fabIcon,
                  label: fabLabel,
                  onTap: onFabTap,
                  active: fabActive,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DockItem {
  const DockItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
  final IconData icon;
  final IconData activeIcon;
  final String label;
}

// ═══════════════════════════════════════════════════════════════════════
// Corpo do dock
// ═══════════════════════════════════════════════════════════════════════

class _DockBody extends StatelessWidget {
  const _DockBody({
    required this.items,
    required this.index,
    required this.onTap,
  });

  final List<DockItem> items;
  final int index;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        height: AppSpacing.dockHeight,
        child: ClipPath(
          clipper: _DockNotchClipper(),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.glassGradient,
                boxShadow: AppShadows.lg,
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Hairline cromada no topo.
                  const Positioned(
                    top: 0,
                    left: 24,
                    right: 24,
                    child: _Hairline(),
                  ),
                  // Borda fina geral por cima do path (ClipPath não aceita border).
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _DockBorderPainter(),
                    ),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: _DockTab(
                          item: items[0],
                          active: index == 0,
                          onTap: () => onTap(0),
                          alignment: Alignment.centerLeft,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.fabSize + 16),
                      Expanded(
                        child: _DockTab(
                          item: items[1],
                          active: index == 1,
                          onTap: () => onTap(1),
                          alignment: Alignment.centerRight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// ClipPath que cria o entalhe (U invertido) no topo do dock pra o FAB.
class _DockNotchClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    const r = AppRadius.dock;
    const notchRadius = AppSpacing.fabSize / 2 + 6;
    final cx = size.width / 2;

    final p = Path();
    p.moveTo(r, 0);
    // linha até o início do notch
    p.lineTo(cx - notchRadius - 10, 0);
    // curva entrando no notch
    p.quadraticBezierTo(
      cx - notchRadius,
      0,
      cx - notchRadius,
      12,
    );
    // arco do notch
    p.arcToPoint(
      Offset(cx + notchRadius, 12),
      radius: const Radius.circular(notchRadius),
      clockwise: false,
    );
    // saindo do notch
    p.quadraticBezierTo(
      cx + notchRadius,
      0,
      cx + notchRadius + 10,
      0,
    );
    p.lineTo(size.width - r, 0);
    p.quadraticBezierTo(size.width, 0, size.width, r);
    p.lineTo(size.width, size.height - r);
    p.quadraticBezierTo(
      size.width,
      size.height,
      size.width - r,
      size.height,
    );
    p.lineTo(r, size.height);
    p.quadraticBezierTo(0, size.height, 0, size.height - r);
    p.lineTo(0, r);
    p.quadraticBezierTo(0, 0, r, 0);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

/// Desenha a borda fina por cima do path (ClipPath corta, mas não desenha borda).
class _DockBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = AppColors.border;
    final path = _DockNotchClipper().getClip(size);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Hairline extends StatelessWidget {
  const _Hairline();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      decoration: const BoxDecoration(
        gradient: AppColors.hairlineGradient,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Aba
// ═══════════════════════════════════════════════════════════════════════

class _DockTab extends StatelessWidget {
  const _DockTab({
    required this.item,
    required this.active,
    required this.onTap,
    required this.alignment,
  });

  final DockItem item;
  final bool active;
  final VoidCallback onTap;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        splashColor: AppColors.emberSoft,
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: AnimatedContainer(
            duration: AppMotion.base,
            curve: Curves.easeOutCubic,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: active
                  ? AppColors.graphiteHigh.withValues(alpha: 0.55)
                  : Colors.transparent,
              border: Border.all(
                color: active
                    ? AppColors.chromeEdgeStrong.withValues(alpha: 0.45)
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  duration: AppMotion.base,
                  curve: Curves.easeOutBack,
                  scale: active ? 1.08 : 1.0,
                  child: Icon(
                    active ? item.activeIcon : item.icon,
                    size: 22,
                    color:
                        active ? AppColors.textPrimary : AppColors.textMuted,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: AnimatedDefaultTextStyle(
                    duration: AppMotion.base,
                    curve: Curves.easeOut,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight:
                          active ? FontWeight.w800 : FontWeight.w600,
                      color: active
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                      letterSpacing: 0.3,
                    ),
                    child: Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// FAB de ignição (pulso + halo)
// ═══════════════════════════════════════════════════════════════════════

class _IgnitionFab extends StatefulWidget {
  const _IgnitionFab({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.active,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;

  @override
  State<_IgnitionFab> createState() => _IgnitionFabState();
}

class _IgnitionFabState extends State<_IgnitionFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: AppMotion.breath,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: () {
          HapticFeedback.mediumImpact();
          widget.onTap();
        },
        child: AnimatedBuilder(
          animation: _pulse,
          builder: (context, child) {
            final breath = 1 + (_pulse.value * 0.035);
            final scale = _pressed ? 0.94 : breath;
            return Transform.scale(scale: scale, child: child);
          },
          child: SizedBox(
            width: AppSpacing.fabSize + 20,
            height: AppSpacing.fabSize + 20,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Halo radial externo (ambient).
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.halo(AppColors.ignition, alpha: 0.28),
                  ),
                ),
                // Anel cromado externo.
                Container(
                  width: AppSpacing.fabSize + 8,
                  height: AppSpacing.fabSize + 8,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Color(0x33FFFFFF),
                        Color(0x05FFFFFF),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(3),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.obsidian,
                      ),
                    ),
                  ),
                ),
                // Núcleo ignitado.
                Container(
                  width: AppSpacing.fabSize,
                  height: AppSpacing.fabSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: AppColors.ignitionGradient,
                    boxShadow: AppShadows.ignition(
                      intensity: widget.active ? 1.4 : 1.0,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Transform.rotate(
                    angle: widget.active ? 0.7854 : 0, // 45° quando ativo → X
                    child: Icon(
                      widget.icon,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                // Brilho superior (specular highlight).
                Positioned(
                  top: 6,
                  child: Container(
                    width: 22,
                    height: 8,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      gradient: const LinearGradient(
                        colors: [
                          Color(0x66FFFFFF),
                          Color(0x00FFFFFF),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
