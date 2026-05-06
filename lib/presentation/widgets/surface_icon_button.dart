import 'dart:ui';

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Glass-chip icon button 44×44 — usado em headers e toolbars.
///
/// Fundo semitransparente com blur leve e borda superior cromada.
/// O `accent` colore o ícone e a borda quando presente.
class SurfaceIconButton extends StatelessWidget {
  const SurfaceIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.accent,
    this.semanticLabel,
    this.badge = false,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final Color? accent;
  final String? semanticLabel;

  /// Exibe um ponto de notificação no canto superior direito.
  final bool badge;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppColors.textPrimary;
    final btn = SizedBox(
      width: 44,
      height: 44,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: Material(
            color: const Color(0xCC181822),
            child: InkWell(
              onTap: onPressed,
              splashColor: AppColors.emberSoft,
              highlightColor: Colors.transparent,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: accent != null
                                ? accent!.withValues(alpha: 0.35)
                                : AppColors.border,
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Top chrome edge (luz batendo).
                  Positioned(
                    top: 0.5,
                    left: 6,
                    right: 6,
                    child: Container(
                      height: 1,
                      decoration: const BoxDecoration(
                        gradient: AppColors.hairlineGradient,
                      ),
                    ),
                  ),
                  Icon(
                    icon,
                    size: 20,
                    color: color,
                    semanticLabel: semanticLabel ?? tooltip,
                  ),
                  if (badge)
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: AppColors.ignition,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.obsidian,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.ignition.withValues(alpha: 0.6),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return tooltip != null ? Tooltip(message: tooltip!, child: btn) : btn;
  }
}
