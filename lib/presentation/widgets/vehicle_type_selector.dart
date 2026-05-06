import 'package:flutter/material.dart';

import '../../core/constants/catalog.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/vehicle_type.dart';

class VehicleTypeSelector extends StatelessWidget {
  const VehicleTypeSelector({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  final VehicleType selected;
  final ValueChanged<VehicleType> onSelect;

  /// Custom vehicle icon painter per type — all side-profile silhouettes.
  static IconData iconFor(IconDataKey key) => switch (key) {
        IconDataKey.carHatchback => Icons.directions_car_filled_rounded,
        IconDataKey.carSedan => Icons.directions_car_rounded,
        IconDataKey.carEstate => Icons.airport_shuttle_rounded,
        IconDataKey.carSide => Icons.local_shipping_rounded,
        IconDataKey.truck => Icons.local_shipping_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: Text('Tipo de Veículo',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.3,
              )),
        ),
        SizedBox(
          height: 128,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(vertical: 2),
            itemCount: vehicleMultipliers.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final v = vehicleMultipliers[i];
              final isSel = selected == v.type;
              return Semantics(
                button: true,
                selected: isSel,
                label:
                    '${v.label}, multiplicador ${v.multiplier.toStringAsFixed(1)}',
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: isSel
                        ? [
                            BoxShadow(
                              color:
                                  AppColors.ignition.withValues(alpha: 0.18),
                              blurRadius: 9,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Material(
                    color: isSel
                        ? AppColors.emberSoft
                        : AppColors.graphiteElev,
                    borderRadius: BorderRadius.circular(16),
                    child: InkWell(
                      onTap: () => onSelect(v.type),
                      borderRadius: BorderRadius.circular(16),
                      splashColor: AppColors.emberSoft,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 108,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSel
                                ? AppColors.ignition.withValues(alpha: 0.7)
                                : AppColors.border,
                            width: isSel ? 1.4 : 1,
                          ),
                          gradient: isSel
                              ? LinearGradient(
                                  colors: [
                                    AppColors.ignition.withValues(alpha: 0.10),
                                    Colors.transparent,
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                )
                              : null,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                gradient: isSel
                                    ? AppColors.ignitionGradient
                                    : null,
                                color: isSel
                                    ? null
                                    : AppColors.graphiteHigh,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSel
                                      ? Colors.transparent
                                      : AppColors.border,
                                ),
                              ),
                              child: Center(
                                child: ExcludeSemantics(
                                  child: CustomPaint(
                                    size: const Size(30, 30),
                                    painter: _VehicleSilhouettePainter(
                                      type: v.type,
                                      color: isSel
                                          ? Colors.white
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              v.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: isSel
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '×${v.multiplier.toStringAsFixed(1)}',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: isSel
                                    ? AppColors.ignition
                                    : AppColors.textMuted,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Draws a simplified side-profile car silhouette for each vehicle type.
class _VehicleSilhouettePainter extends CustomPainter {
  _VehicleSilhouettePainter({required this.type, required this.color});
  final VehicleType type;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final s = size.width; // work in a square coordinate space

    switch (type) {
      case VehicleType.small:
        _drawHatchback(canvas, paint, s);
      case VehicleType.medium:
        _drawSedan(canvas, paint, s);
      case VehicleType.large:
        _drawEstate(canvas, paint, s);
      case VehicleType.suv:
        _drawSuv(canvas, paint, s);
      case VehicleType.truck:
        _drawTruck(canvas, paint, s);
    }
  }

  void _drawHatchback(Canvas c, Paint p, double s) {
    // Compact hatchback: short body, steep rear
    final path = Path()
      ..moveTo(s * 0.08, s * 0.62)
      ..lineTo(s * 0.08, s * 0.52)
      ..quadraticBezierTo(s * 0.10, s * 0.44, s * 0.22, s * 0.42)
      ..lineTo(s * 0.38, s * 0.42)
      ..quadraticBezierTo(s * 0.42, s * 0.30, s * 0.52, s * 0.28)
      ..lineTo(s * 0.68, s * 0.28)
      ..quadraticBezierTo(s * 0.78, s * 0.28, s * 0.80, s * 0.38)
      ..lineTo(s * 0.88, s * 0.42)
      ..quadraticBezierTo(s * 0.92, s * 0.44, s * 0.92, s * 0.52)
      ..lineTo(s * 0.92, s * 0.62)
      ..quadraticBezierTo(s * 0.92, s * 0.68, s * 0.88, s * 0.70)
      ..lineTo(s * 0.12, s * 0.70)
      ..quadraticBezierTo(s * 0.08, s * 0.68, s * 0.08, s * 0.62)
      ..close();
    c.drawPath(path, p);
    _drawWheels(c, p, s, s * 0.22, s * 0.78);
  }

  void _drawSedan(Canvas c, Paint p, double s) {
    // Sedan: longer body, distinct trunk
    final path = Path()
      ..moveTo(s * 0.06, s * 0.62)
      ..lineTo(s * 0.06, s * 0.52)
      ..quadraticBezierTo(s * 0.08, s * 0.44, s * 0.18, s * 0.42)
      ..lineTo(s * 0.34, s * 0.42)
      ..quadraticBezierTo(s * 0.38, s * 0.30, s * 0.48, s * 0.26)
      ..lineTo(s * 0.62, s * 0.26)
      ..quadraticBezierTo(s * 0.72, s * 0.26, s * 0.76, s * 0.36)
      ..lineTo(s * 0.76, s * 0.42)
      ..lineTo(s * 0.82, s * 0.42)
      ..quadraticBezierTo(s * 0.88, s * 0.42, s * 0.90, s * 0.48)
      ..lineTo(s * 0.94, s * 0.52)
      ..quadraticBezierTo(s * 0.94, s * 0.58, s * 0.92, s * 0.62)
      ..quadraticBezierTo(s * 0.92, s * 0.68, s * 0.88, s * 0.70)
      ..lineTo(s * 0.12, s * 0.70)
      ..quadraticBezierTo(s * 0.06, s * 0.68, s * 0.06, s * 0.62)
      ..close();
    c.drawPath(path, p);
    _drawWheels(c, p, s, s * 0.20, s * 0.80);
  }

  void _drawEstate(Canvas c, Paint p, double s) {
    // Estate/wagon: long roof line extending to rear
    final path = Path()
      ..moveTo(s * 0.06, s * 0.62)
      ..lineTo(s * 0.06, s * 0.52)
      ..quadraticBezierTo(s * 0.08, s * 0.44, s * 0.18, s * 0.42)
      ..lineTo(s * 0.34, s * 0.42)
      ..quadraticBezierTo(s * 0.38, s * 0.30, s * 0.48, s * 0.26)
      ..lineTo(s * 0.88, s * 0.26)
      ..quadraticBezierTo(s * 0.94, s * 0.26, s * 0.94, s * 0.36)
      ..lineTo(s * 0.94, s * 0.52)
      ..quadraticBezierTo(s * 0.94, s * 0.68, s * 0.88, s * 0.70)
      ..lineTo(s * 0.12, s * 0.70)
      ..quadraticBezierTo(s * 0.06, s * 0.68, s * 0.06, s * 0.62)
      ..close();
    c.drawPath(path, p);
    _drawWheels(c, p, s, s * 0.20, s * 0.80);
  }

  void _drawSuv(Canvas c, Paint p, double s) {
    // SUV: taller body, high ground clearance, boxy
    final path = Path()
      ..moveTo(s * 0.06, s * 0.64)
      ..lineTo(s * 0.06, s * 0.48)
      ..quadraticBezierTo(s * 0.08, s * 0.40, s * 0.18, s * 0.38)
      ..lineTo(s * 0.32, s * 0.38)
      ..quadraticBezierTo(s * 0.36, s * 0.24, s * 0.48, s * 0.20)
      ..lineTo(s * 0.74, s * 0.20)
      ..quadraticBezierTo(s * 0.82, s * 0.20, s * 0.84, s * 0.30)
      ..lineTo(s * 0.90, s * 0.38)
      ..quadraticBezierTo(s * 0.94, s * 0.40, s * 0.94, s * 0.48)
      ..lineTo(s * 0.94, s * 0.64)
      ..quadraticBezierTo(s * 0.94, s * 0.68, s * 0.88, s * 0.70)
      ..lineTo(s * 0.12, s * 0.70)
      ..quadraticBezierTo(s * 0.06, s * 0.68, s * 0.06, s * 0.64)
      ..close();
    c.drawPath(path, p);
    _drawWheels(c, p, s, s * 0.20, s * 0.80, bigger: true);
  }

  void _drawTruck(Canvas c, Paint p, double s) {
    // Pickup truck: cab + bed, high ride
    final path = Path()
      ..moveTo(s * 0.06, s * 0.64)
      ..lineTo(s * 0.06, s * 0.48)
      ..quadraticBezierTo(s * 0.08, s * 0.40, s * 0.18, s * 0.38)
      ..lineTo(s * 0.32, s * 0.38)
      ..quadraticBezierTo(s * 0.36, s * 0.22, s * 0.48, s * 0.18)
      ..lineTo(s * 0.58, s * 0.18)
      ..quadraticBezierTo(s * 0.64, s * 0.18, s * 0.64, s * 0.34)
      ..lineTo(s * 0.68, s * 0.38)
      ..lineTo(s * 0.94, s * 0.38)
      ..quadraticBezierTo(s * 0.94, s * 0.58, s * 0.94, s * 0.64)
      ..quadraticBezierTo(s * 0.94, s * 0.68, s * 0.88, s * 0.70)
      ..lineTo(s * 0.12, s * 0.70)
      ..quadraticBezierTo(s * 0.06, s * 0.68, s * 0.06, s * 0.64)
      ..close();
    c.drawPath(path, p);
    _drawWheels(c, p, s, s * 0.20, s * 0.82, bigger: true);
  }

  void _drawWheels(Canvas c, Paint p, double s, double x1, double x2,
      {bool bigger = false}) {
    final r = bigger ? s * 0.10 : s * 0.08;
    final y = s * 0.70;
    c.drawCircle(Offset(x1, y), r, p);
    c.drawCircle(Offset(x2, y), r, p);
  }

  @override
  bool shouldRepaint(covariant _VehicleSilhouettePainter old) =>
      old.type != type || old.color != color;
}
