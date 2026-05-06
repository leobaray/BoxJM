import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/currency.dart';

/// Totals card "Cockpit" — ticket premium com listra cromada, ignição
/// sutil e valor total com ShaderMask.
class TotalsCard extends StatelessWidget {
  const TotalsCard({
    super.key,
    required this.subtotal,
    required this.multiplier,
    required this.total,
    this.onEditTotal,
    this.heroTag,
    this.margin = const EdgeInsets.only(bottom: 12),
  });

  final double subtotal;
  final double multiplier;
  final double total;
  final VoidCallback? onEditTotal;
  final Object? heroTag;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color.alphaBlend(
              AppColors.ignition.withValues(alpha: 0.12),
              AppColors.graphiteElev,
            ),
            AppColors.obsidian,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xxl),
        border: Border.all(color: AppColors.ignition.withValues(alpha: 0.28)),
        boxShadow: AppShadows.md,
      ),
      child: Stack(
        children: [
          // Hairline cromado no topo.
          Positioned(
            top: 0,
            left: 20,
            right: 20,
            child: Container(
              height: 1,
              decoration: const BoxDecoration(
                gradient: AppColors.hairlineGradient,
              ),
            ),
          ),
          // Glow radial sutil no canto.
          Positioned(
            right: -40,
            bottom: -40,
            width: 160,
            height: 160,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.halo(AppColors.ignition, alpha: 0.16),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _row('Subtotal', Currency.format(subtotal)),
                const SizedBox(height: 10),
                _row('Multiplicador', '×${multiplier.toStringAsFixed(1)}'),
                const SizedBox(height: 14),
                Container(
                  height: 1,
                  decoration: const BoxDecoration(
                    gradient: AppColors.hairlineGradient,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('TOTAL',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            )),
                        const SizedBox(height: 4),
                        Text('valor final do orçamento',
                            style: AppTextStyles.labelMuted
                                .copyWith(fontSize: 11.5)),
                      ],
                    ),
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: heroTag != null
                                ? Hero(
                                    tag: heroTag!,
                                    flightShuttleBuilder: (_, __, ___, ____,
                                            _____) =>
                                        _ChromeTotal(
                                            value: Currency.format(total)),
                                    child: _ChromeTotal(
                                        value: Currency.format(total)),
                                  )
                                : _ChromeTotal(value: Currency.format(total)),
                          ),
                          if (onEditTotal != null) ...[
                            const SizedBox(width: 10),
                            _EditTotalButton(onTap: onEditTotal!),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppTextStyles.bodyMuted.copyWith(fontSize: 13.5)),
        Text(value, style: AppTextStyles.bodyStrong),
      ],
    );
  }
}

class _ChromeTotal extends StatelessWidget {
  const _ChromeTotal({required this.value});
  final String value;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) =>
            AppColors.chromeGradient.createShader(bounds),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Text(
            value,
            maxLines: 1,
            style: AppTextStyles.displayTotal,
          ),
        ),
      ),
    );
  }
}

class _EditTotalButton extends StatelessWidget {
  const _EditTotalButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.graphiteHigh,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        splashColor: AppColors.emberSoft,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppColors.border),
          ),
          child: const Icon(
            Icons.edit_rounded,
            size: 16,
            color: AppColors.textSoft,
            semanticLabel: 'Editar valor total',
          ),
        ),
      ),
    );
  }
}
