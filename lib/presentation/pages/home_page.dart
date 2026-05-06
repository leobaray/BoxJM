import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/currency.dart';
import '../../core/utils/date_helpers.dart';
import '../../domain/entities/budget.dart';
import '../providers/providers.dart';
import '../widgets/brand_header.dart';
import '../widgets/budget_card.dart';
import '../widgets/surface_icon_button.dart';

enum _SortOption {
  recent,
  highestTotal,
  clientAZ;

  String get label => switch (this) {
        _SortOption.recent => 'Mais recente',
        _SortOption.highestTotal => 'Maior valor',
        _SortOption.clientAZ => 'Cliente A-Z',
      };

  IconData get icon => switch (this) {
        _SortOption.recent => Icons.schedule_rounded,
        _SortOption.highestTotal => Icons.trending_up_rounded,
        _SortOption.clientAZ => Icons.sort_by_alpha_rounded,
      };
}

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final _search = TextEditingController();
  BudgetStatus? _statusFilter;
  _SortOption _sort = _SortOption.recent;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _openSort() async {
    final picked = await showModalBottomSheet<_SortOption>(
      context: context,
      backgroundColor: AppColors.graphiteElev,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                children: [
                  Icon(Icons.sort_rounded, color: AppColors.ignition),
                  SizedBox(width: 12),
                  Text('Ordenar por',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                ],
              ),
            ),
            for (final opt in _SortOption.values)
              ListTile(
                leading: Icon(opt.icon,
                    color: opt == _sort
                        ? AppColors.ignition
                        : AppColors.textSecondary),
                title: Text(opt.label,
                    style: TextStyle(
                      fontSize: 14.5,
                      color: AppColors.textPrimary,
                      fontWeight:
                          opt == _sort ? FontWeight.w700 : FontWeight.w500,
                    )),
                trailing: opt == _sort
                    ? const Icon(Icons.check_rounded,
                        color: AppColors.ignition)
                    : null,
                onTap: () => Navigator.pop(context, opt),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null) setState(() => _sort = picked);
  }

  List<Budget> _applyFilters(List<Budget> src) {
    final q = _search.text.trim().toLowerCase();
    Iterable<Budget> out = src;
    if (_statusFilter != null) {
      out = out.where((b) => b.status == _statusFilter);
    }
    if (q.isNotEmpty) {
      out = out.where((b) {
        return b.clientName.toLowerCase().contains(q) ||
            b.vehicleBrand.toLowerCase().contains(q) ||
            b.vehicleModel.toLowerCase().contains(q);
      });
    }
    final list = out.toList();
    switch (_sort) {
      case _SortOption.recent:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case _SortOption.highestTotal:
        list.sort((a, b) => b.total.compareTo(a.total));
        break;
      case _SortOption.clientAZ:
        list.sort((a, b) =>
            a.clientName.toLowerCase().compareTo(b.clientName.toLowerCase()));
        break;
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final asyncBudgets = ref.watch(budgetListProvider);
    final all = asyncBudgets.valueOrNull;

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          _Header(
            budgets: all,
            onRefresh: () => ref.read(budgetListProvider.notifier).refresh(),
          ),
          Expanded(
            child: asyncBudgets.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.ignition),
              ),
              error: (e, _) => _ErrorView(
                message: '$e',
                onRetry: () => ref.read(budgetListProvider.notifier).refresh(),
              ),
              data: (list) {
                if (list.isEmpty) return const _EmptyState();
                final filtered = _applyFilters(list);
                return RefreshIndicator(
                  color: AppColors.ignition,
                  backgroundColor: AppColors.graphiteElev,
                  onRefresh: () =>
                      ref.read(budgetListProvider.notifier).refresh(),
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
                          child: _StatsStrip(budgets: list),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                          child: _SearchField(controller: _search),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: _StatusFilterRow(
                          selected: _statusFilter,
                          counts: _statusCounts(list),
                          onSelect: (s) => setState(() => _statusFilter = s),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 2, 14, 10),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _resultLabel(filtered.length, list.length),
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.textMuted,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                              _SortPill(
                                option: _sort,
                                onTap: _openSort,
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (filtered.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: _NoResults(
                            onClear: () {
                              _search.clear();
                              setState(() => _statusFilter = null);
                            },
                          ),
                        )
                      else
                        ..._buildSections(filtered),
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: AppSpacing.navReserved +
                              MediaQuery.paddingOf(context).bottom,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Map<BudgetStatus, int> _statusCounts(List<Budget> all) {
    final counts = <BudgetStatus, int>{};
    for (final b in all) {
      counts[b.status] = (counts[b.status] ?? 0) + 1;
    }
    return counts;
  }

  String _resultLabel(int shown, int total) {
    if (shown == total) return '$total orçamento${total == 1 ? '' : 's'}';
    return '$shown de $total';
  }

  List<Widget> _buildSections(List<Budget> budgets) {
    if (_sort != _SortOption.recent) {
      return [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList.builder(
            itemCount: budgets.length,
            itemBuilder: (_, i) => BudgetCard(budget: budgets[i]),
          ),
        ),
      ];
    }
    final grouped = <DateBucket, List<Budget>>{};
    for (final b in budgets) {
      final k = bucketFor(b.createdAt);
      grouped.putIfAbsent(k, () => []).add(b);
    }
    final slivers = <Widget>[];
    for (final bucket in DateBucket.values) {
      final list = grouped[bucket];
      if (list == null || list.isEmpty) continue;
      slivers.add(SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
        sliver: SliverToBoxAdapter(
          child: Row(
            children: [
              Text(bucket.label.toUpperCase(),
                  style: AppTextStyles.sectionEyebrow),
              const SizedBox(width: 10),
              Expanded(
                  child: Container(height: 1, color: AppColors.borderSoft)),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.graphiteElev,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text('${list.length}',
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textSecondary)),
              ),
            ],
          ),
        ),
      ));
      slivers.add(SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverList.builder(
          itemCount: list.length,
          itemBuilder: (_, i) => BudgetCard(budget: list[i]),
        ),
      ));
    }
    return slivers;
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Header
// ═══════════════════════════════════════════════════════════════════════

class _Header extends StatelessWidget {
  const _Header({required this.onRefresh, this.budgets});
  final VoidCallback onRefresh;
  final List<Budget>? budgets;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final approvedToday = budgets?.where((b) =>
            (b.status == BudgetStatus.approved ||
                b.status == BudgetStatus.completed) &&
            _sameDay(b.createdAt, today)) ??
        const [];
    final approvedTotalToday =
        approvedToday.fold<double>(0, (s, b) => s + b.total);

    return BrandHeader(
      title: 'Orçamentos',
      subtitle: 'Seu cockpit de trabalhos',
      trailing: SurfaceIconButton(
        icon: Icons.refresh_rounded,
        onPressed: onRefresh,
        tooltip: 'Atualizar',
      ),
      contextLine: Row(
        children: [
          const Icon(Icons.event_rounded,
              size: 12, color: AppColors.textMuted),
          const SizedBox(width: 5),
          Text(
            _formatDate(today),
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.25,
            ),
          ),
          const SizedBox(width: 10),
          const _Dot(),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${budgets?.length ?? 0} orçamento${budgets?.length == 1 ? '' : 's'} total',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (approvedTotalToday > 0) ...[
            const SizedBox(width: 8),
            HeaderContextPill(
              icon: Icons.trending_up_rounded,
              label: Currency.format(approvedTotalToday),
              accent: AppColors.statusApproved,
            ),
          ],
        ],
      ),
    );
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _formatDate(DateTime d) {
    const days = ['seg', 'ter', 'qua', 'qui', 'sex', 'sáb', 'dom'];
    const months = [
      'jan', 'fev', 'mar', 'abr', 'mai', 'jun',
      'jul', 'ago', 'set', 'out', 'nov', 'dez'
    ];
    return '${days[d.weekday - 1]}, ${d.day} ${months[d.month - 1]}';
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 3,
      height: 3,
      decoration: const BoxDecoration(
        color: AppColors.textMuted,
        shape: BoxShape.circle,
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Stats Strip — "Gauge cards"
// ═══════════════════════════════════════════════════════════════════════

class _StatsStrip extends StatelessWidget {
  const _StatsStrip({required this.budgets});
  final List<Budget> budgets;

  @override
  Widget build(BuildContext context) {
    final approved = budgets
        .where((b) =>
            b.status == BudgetStatus.approved ||
            b.status == BudgetStatus.completed)
        .toList();
    final pending = budgets
        .where((b) =>
            b.status == BudgetStatus.draft || b.status == BudgetStatus.sent)
        .toList();

    final approvedTotal = approved.fold<double>(0, (s, b) => s + b.total);
    final pendingTotal = pending.fold<double>(0, (s, b) => s + b.total);

    final totalCount = approved.length + pending.length;
    final approvedRatio =
        totalCount == 0 ? 0.0 : approved.length / totalCount;
    final pendingRatio =
        totalCount == 0 ? 0.0 : pending.length / totalCount;

    return Row(
      children: [
        Expanded(
          child: _GaugeCard(
            label: 'Aprovados',
            value: Currency.format(approvedTotal),
            count: approved.length,
            ratio: approvedRatio,
            color: AppColors.statusApproved,
            icon: Icons.check_circle_rounded,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _GaugeCard(
            label: 'Pendentes',
            value: Currency.format(pendingTotal),
            count: pending.length,
            ratio: pendingRatio,
            color: AppColors.statusSent,
            icon: Icons.pending_actions_rounded,
          ),
        ),
      ],
    );
  }
}

class _GaugeCard extends StatelessWidget {
  const _GaugeCard({
    required this.label,
    required this.value,
    required this.count,
    required this.ratio,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final int count;
  final double ratio;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF181822),
            Color.alphaBlend(
                color.withValues(alpha: 0.08), const Color(0xFF101018)),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.md,
      ),
      child: Stack(
        children: [
          // Hairline superior.
          Positioned(
            top: -12,
            left: 0,
            right: 0,
            child: Container(
              height: 1,
              decoration: const BoxDecoration(
                gradient: AppColors.hairlineGradient,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: color.withValues(alpha: 0.28), width: 1),
                    ),
                    child: Icon(icon, size: 14, color: color),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                          letterSpacing: 0.1,
                        )),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.graphiteHigh,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('$count',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        )),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              // Mini gauge — barra com porção preenchida pela cor.
              _Gauge(ratio: ratio.clamp(0, 1), color: color),
            ],
          ),
        ],
      ),
    );
  }
}

class _Gauge extends StatelessWidget {
  const _Gauge({required this.ratio, required this.color});
  final double ratio;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: ratio),
      duration: AppMotion.slow,
      curve: Curves.easeOutCubic,
      builder: (context, v, _) {
        return Container(
          height: 5,
          decoration: BoxDecoration(
            color: AppColors.graphite,
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: v,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.lighten(0.15), color.darken(0.2)],
                ),
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.5),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Search + Sort
// ═══════════════════════════════════════════════════════════════════════

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller});
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final hasText = controller.text.isNotEmpty;
    return TextField(
      controller: controller,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14.5),
      decoration: InputDecoration(
        hintText: 'Buscar por cliente ou veículo...',
        prefixIcon:
            const Icon(Icons.search_rounded, color: AppColors.textMuted),
        suffixIcon: hasText
            ? IconButton(
                icon: const Icon(Icons.close_rounded,
                    size: 18, color: AppColors.textMuted),
                onPressed: controller.clear,
              )
            : null,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
    );
  }
}

class _SortPill extends StatelessWidget {
  const _SortPill({required this.option, required this.onTap});
  final _SortOption option;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.emberSoft,
            borderRadius: BorderRadius.circular(999),
            border:
                Border.all(color: AppColors.ignition.withValues(alpha: 0.35)),
            boxShadow: AppShadows.statusGlow(AppColors.ignition,
                intensity: 0.45),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(option.icon, size: 14, color: AppColors.ignition),
              const SizedBox(width: 6),
              Text(option.label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ignition,
                  )),
              const Icon(Icons.expand_more_rounded,
                  size: 16, color: AppColors.ignition),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// Status Filter
// ═══════════════════════════════════════════════════════════════════════

class _StatusFilterRow extends StatelessWidget {
  const _StatusFilterRow({
    required this.selected,
    required this.onSelect,
    required this.counts,
  });

  final BudgetStatus? selected;
  final ValueChanged<BudgetStatus?> onSelect;
  final Map<BudgetStatus, int> counts;

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      _StatusChip(
        label: 'Todos',
        selected: selected == null,
        accent: AppColors.ignition,
        onTap: () => onSelect(null),
      ),
      for (final s in BudgetStatus.values)
        _StatusChip(
          label: '${s.label} (${counts[s] ?? 0})',
          selected: selected == s,
          accent: _colorFor(s),
          onTap: () => onSelect(s),
        ),
    ];
    return SizedBox(
      height: 52,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 2),
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) => chips[i],
      ),
    );
  }

  Color _colorFor(BudgetStatus s) => switch (s) {
        BudgetStatus.draft => AppColors.statusDraft,
        BudgetStatus.sent => AppColors.statusSent,
        BudgetStatus.approved => AppColors.statusApproved,
        BudgetStatus.completed => AppColors.statusCompleted,
      };
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppMotion.base,
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        boxShadow:
            selected ? AppShadows.statusGlow(accent, intensity: 0.8) : null,
      ),
      child: Material(
        color: selected ? accent.withValues(alpha: 0.14) : AppColors.graphite,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          splashColor: accent.withValues(alpha: 0.18),
          child: AnimatedContainer(
            duration: AppMotion.base,
            curve: Curves.easeOut,
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: selected
                    ? accent.withValues(alpha: 0.7)
                    : AppColors.border,
                width: selected ? 1.2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                    boxShadow: selected
                        ? [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.35),
                              blurRadius: 3,
                            ),
                          ]
                        : null,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: selected ? accent : AppColors.textSecondary,
                    letterSpacing: 0.1,
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
// Estados vazios e erro
// ═══════════════════════════════════════════════════════════════════════

class _NoResults extends StatelessWidget {
  const _NoResults({required this.onClear});
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.graphiteElev,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.search_off_rounded,
                  size: 36, color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            const Text('Nada encontrado',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                )),
            const SizedBox(height: 4),
            const Text('Tente ajustar a busca ou os filtros',
                style:
                    TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.refresh_rounded,
                  size: 16, color: AppColors.ignition),
              label: const Text('Limpar filtros',
                  style: TextStyle(
                      color: AppColors.ignition,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: CustomPaint(
                painter: _EmptyOrbitPainter(),
                child: const Center(
                  child: Icon(Icons.description_rounded,
                      size: 44, color: AppColors.ignition),
                ),
              ),
            ),
            const SizedBox(height: 22),
            const Text('Nenhum orçamento ainda',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.3,
                )),
            const SizedBox(height: 8),
            const Text('Toque no botão + pra criar o primeiro',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textSecondary,
                    height: 1.4)),
          ],
        ),
      ),
    );
  }
}

class _EmptyOrbitPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;

    // Glow ambiente.
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..shader = RadialGradient(
          colors: [
            AppColors.ignition.withValues(alpha: 0.25),
            AppColors.ignition.withValues(alpha: 0),
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Anel cromado externo.
    canvas.drawCircle(
      Offset(cx, cy),
      r - 8,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppColors.chromeEdgeStrong,
    );

    // Órbita vermelha tracejada.
    final dashPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = AppColors.ignition.withValues(alpha: 0.55);
    const dashCount = 36;
    for (int i = 0; i < dashCount; i++) {
      final a1 = (i / dashCount) * 2 * math.pi;
      final a2 = a1 + (math.pi / dashCount) * 0.6;
      final rr = r - 18;
      final p1 = Offset(cx + rr * math.cos(a1), cy + rr * math.sin(a1));
      final p2 = Offset(cx + rr * math.cos(a2), cy + rr * math.sin(a2));
      canvas.drawLine(p1, p2, dashPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.graphiteElev,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.cloud_off_rounded,
                  size: 32, color: AppColors.textMuted),
            ),
            const SizedBox(height: 14),
            const Text('Algo deu errado',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                )),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12.5, color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded,
                  size: 16, color: AppColors.ignition),
              label: const Text('Tentar novamente',
                  style: TextStyle(
                      color: AppColors.ignition,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}
