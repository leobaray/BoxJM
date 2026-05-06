import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import 'surface_icon_button.dart';

/// Cockpit Bar — cabeçalho premium com brandmark hexagonal, ambient glow
/// de ignição e hairline cromado. Substitui o antigo BrandHeader plano
/// mantendo a mesma API pública (`title`, `subtitle`, `trailing`, `leading`).
class BrandHeader extends StatelessWidget {
  const BrandHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
    this.leading,
    this.showBrandMark = true,
    this.padding = const EdgeInsets.fromLTRB(20, 20, 20, 18),
    this.contextLine,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? leading;
  final bool showBrandMark;
  final EdgeInsets padding;

  /// Linha opcional de contexto dinâmico (ex: "Olá, João · qui, 23 abr").
  /// Se nula, só exibe title + subtitle.
  final Widget? contextLine;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.cockpitGradient,
      ),
      child: Stack(
        children: [
          // Ambient glow radial atrás do brandmark.
          Positioned(
            top: -60,
            left: -40,
            width: 240,
            height: 240,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.halo(AppColors.ignition, alpha: 0.22),
                ),
              ),
            ),
          ),
          Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    if (leading != null) ...[
                      leading!,
                      const SizedBox(width: 14),
                    ] else if (showBrandMark) ...[
                      const _HexBrandMark(),
                      const SizedBox(width: 14),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Wordmark(title: title),
                          if (subtitle != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textMuted,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 12),
                      trailing!,
                    ],
                  ],
                ),
                if (contextLine != null) ...[
                  const SizedBox(height: 14),
                  const _ChromeHairline(),
                  const SizedBox(height: 10),
                  DefaultTextStyle.merge(
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.25,
                    ),
                    child: contextLine!,
                  ),
                ],
              ],
            ),
          ),
          // Hairline cromado no pé do header (só quando não tem contextLine).
          if (contextLine == null)
            const Positioned(
              bottom: 0,
              left: 20,
              right: 20,
              child: _ChromeHairline(),
            ),
        ],
      ),
    );
  }
}

/// Wordmark "BOX JM" — "BOX" branco + "JM" com shader ignição.
class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    // Se o título não for exatamente "BOX JM", cai no estilo "pageTitle".
    final isBrand = title.trim().toUpperCase() == 'BOX JM';

    if (!isBrand) {
      return Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w900,
          color: AppColors.textPrimary,
          letterSpacing: -0.4,
          height: 1.1,
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        const Text(
          'BOX',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
            letterSpacing: 2.5,
            height: 1,
          ),
        ),
        const SizedBox(width: 6),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (r) => AppColors.ignitionGradient.createShader(r),
          child: const Text(
            'JM',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2.5,
              height: 1,
            ),
          ),
        ),
      ],
    );
  }
}

/// Brandmark: logo oficial "JM" (Owned Regular, vermelho ignicao) sobre
/// fundo branco com rim cromado — casa com a logo do launcher/splash.
class _HexBrandMark extends StatelessWidget {
  const _HexBrandMark();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'BOX JM',
      child: Container(
        width: 46,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: AppShadows.md,
          border: Border.all(color: AppColors.chromeEdgeStrong, width: 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Image.asset(
            'assets/icon/app_icon.png',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}

/// Linha cromada fina (1px) com brilho no centro.
class _ChromeHairline extends StatelessWidget {
  const _ChromeHairline();

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

/// Pill de contexto — uso em contextLine (ex: valor do dia, contador).
class HeaderContextPill extends StatelessWidget {
  const HeaderContextPill({
    super.key,
    required this.icon,
    required this.label,
    this.accent = AppColors.ignition,
  });

  final IconData icon;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.30)),
        boxShadow: AppShadows.statusGlow(accent, intensity: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: accent),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: accent,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

/// Back-compat alias — prefer [SurfaceIconButton] in new code.
typedef BrandIconButton = SurfaceIconButton;
