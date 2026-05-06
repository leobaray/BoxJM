import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../domain/entities/budget.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.status,
    this.size = StatusBadgeSize.medium,
  });

  final BudgetStatus status;
  final StatusBadgeSize size;

  static const _colors = {
    BudgetStatus.draft: AppColors.statusDraft,
    BudgetStatus.sent: AppColors.statusSent,
    BudgetStatus.approved: AppColors.statusApproved,
    BudgetStatus.completed: AppColors.statusCompleted,
  };

  static const _icons = {
    BudgetStatus.draft: Icons.edit_note_rounded,
    BudgetStatus.sent: Icons.send_rounded,
    BudgetStatus.approved: Icons.check_circle_rounded,
    BudgetStatus.completed: Icons.verified_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[status]!;
    final icon = _icons[status]!;
    final compact = size == StatusBadgeSize.small;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        boxShadow: AppShadows.statusGlow(color, intensity: 0.5),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 9 : 11,
          vertical: compact ? 4 : 6,
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.22),
              color.withValues(alpha: 0.10),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(999),
          border:
              Border.all(color: color.withValues(alpha: 0.42), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: compact ? 12 : 14, color: color),
            SizedBox(width: compact ? 4 : 6),
            Text(
              status.label,
              style: TextStyle(
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w800,
                color: color,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum StatusBadgeSize { small, medium }
