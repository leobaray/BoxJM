import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';

/// Botão de quantidade (+/−) — disco de 38dp com hit target de 48dp.
/// Estilo cockpit: preenchimento ignitado com glow quando ativo.
class QtyButton extends StatelessWidget {
  const QtyButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.onPressed,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: semanticLabel,
      excludeSemantics: true,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient:
                  enabled ? AppColors.ignitionGradient : null,
              color: enabled ? null : AppColors.graphiteHigh,
              boxShadow: enabled
                  ? AppShadows.ignition(intensity: 0.7)
                  : null,
            ),
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: enabled
                    ? () {
                        HapticFeedback.lightImpact();
                        onPressed?.call();
                      }
                    : null,
                customBorder: const CircleBorder(),
                splashColor: Colors.white.withValues(alpha: 0.18),
                child: Icon(
                  icon,
                  size: 20,
                  color: enabled ? Colors.white : AppColors.textMuted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
