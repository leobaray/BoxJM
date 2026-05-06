import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/currency.dart';
import '../../core/utils/date_helpers.dart';
import '../../domain/entities/budget.dart';
import 'status_badge.dart';

/// "Ticket de serviço" — card com listra lateral ignitada, valor cromado
/// e hairline no topo. Substitui a versão flat antiga.
class BudgetCard extends StatefulWidget {
  const BudgetCard({super.key, required this.budget});

  final Budget budget;

  static const _stripeColors = {
    BudgetStatus.draft: AppColors.statusDraft,
    BudgetStatus.sent: AppColors.statusSent,
    BudgetStatus.approved: AppColors.statusApproved,
    BudgetStatus.completed: AppColors.statusCompleted,
  };

  @override
  State<BudgetCard> createState() => _BudgetCardState();
}

class _BudgetCardState extends State<BudgetCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final b = widget.budget;
    final clientName =
        b.clientName.isEmpty ? 'Cliente sem nome' : b.clientName;
    final brand = b.vehicleBrand.isEmpty ? 'Marca' : b.vehicleBrand;
    final model = b.vehicleModel.isEmpty ? 'Modelo' : b.vehicleModel;
    final stripe = BudgetCard._stripeColors[b.status]!;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1.0,
        duration: AppMotion.fast,
        curve: Curves.easeOut,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push('/budget/${b.id}'),
            onHighlightChanged: (v) => setState(() => _pressed = v),
            borderRadius: BorderRadius.circular(AppRadius.xl),
            splashColor: AppColors.emberSoft,
            highlightColor: Colors.transparent,
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF181822), Color(0xFF101018)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(AppRadius.xl),
                border: Border.all(color: AppColors.border),
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
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        _StatusStripe(color: stripe),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            clientName,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.textPrimary,
                                              letterSpacing: -0.3,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.directions_car_rounded,
                                                size: 13,
                                                color: AppColors.textMuted,
                                              ),
                                              const SizedBox(width: 5),
                                              Flexible(
                                                child: Text(
                                                  '$brand $model',
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontSize: 12.5,
                                                    color:
                                                        AppColors.textSecondary,
                                                    fontWeight:
                                                        FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    StatusBadge(
                                      status: b.status,
                                      size: StatusBadgeSize.small,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                // Divisor pontilhado — estética de ticket.
                                const _DottedDivider(),
                                const SizedBox(height: 12),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _meta(
                                            Icons.local_car_wash_rounded,
                                            '${b.items.length} ${b.items.length == 1 ? "serviço" : "serviços"}',
                                          ),
                                          const SizedBox(height: 4),
                                          _meta(
                                            Icons.schedule_rounded,
                                            relativeLabel(b.createdAt),
                                          ),
                                        ],
                                      ),
                                    ),
                                    ConstrainedBox(
                                      constraints:
                                          const BoxConstraints(maxWidth: 180),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          const Text(
                                            'TOTAL',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: AppColors.textMuted,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 1.6,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Hero(
                                            tag: 'budget-total-${b.id}',
                                            flightShuttleBuilder: (_, __, ___,
                                                    ____, _____) =>
                                                _MetallicTotal(
                                                    value: Currency.format(
                                                        b.total)),
                                            child: _MetallicTotal(
                                              value: Currency.format(b.total),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 13, color: AppColors.textMuted),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

/// Listra vertical de status com glow.
class _StatusStripe extends StatelessWidget {
  const _StatusStripe({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.lighten(0.25),
            color,
            color.darken(0.35),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppRadius.xl - 1),
          bottomLeft: Radius.circular(AppRadius.xl - 1),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.45),
            blurRadius: 10,
            offset: const Offset(2, 0),
          ),
        ],
      ),
    );
  }
}

/// Divisor pontilhado (estética de cupom / ticket).
class _DottedDivider extends StatelessWidget {
  const _DottedDivider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 1,
      width: double.infinity,
      child: CustomPaint(painter: _DashedLinePainter()),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    const dashWidth = 2.0;
    const dashGap = 4.0;
    final paint = Paint()
      ..color = AppColors.borderStrong
      ..strokeWidth = 1;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0.5), Offset(x + dashWidth, 0.5), paint);
      x += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Valor total com ShaderMask cromado.
class _MetallicTotal extends StatelessWidget {
  const _MetallicTotal({required this.value});
  final String value;

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (r) => AppColors.chromeGradient.createShader(r),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Text(
            value,
            maxLines: 1,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ),
    );
  }
}
