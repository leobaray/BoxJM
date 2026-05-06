import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/budget_pdf.dart';
import '../../core/utils/currency.dart';
import '../../core/utils/id.dart';
import '../../domain/entities/budget.dart';
import '../providers/providers.dart';
import '../widgets/app_card.dart';
import '../widgets/brand_header.dart';
import '../widgets/status_badge.dart';
import '../widgets/surface_icon_button.dart';
import '../widgets/totals_card.dart';

enum _ShareAs { text, pdf }

class BudgetDetailPage extends ConsumerWidget {
  const BudgetDetailPage({super.key, required this.budgetId});

  final String budgetId;

  void _goBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncBudgets = ref.watch(budgetListProvider);
    final budgets = asyncBudgets.valueOrNull ?? const [];
    final budget = budgets.where((b) => b.id == budgetId).firstOrNull;

    // If data loaded but budget not found, show not-found view
    final notFound = asyncBudgets.hasValue && budget == null;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: notFound
            ? _NotFoundView(onBack: () => _goBack(context))
            : budget == null
                ? _LoadingView(onBack: () => _goBack(context))
                : _Content(budget: budget),
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BrandHeader(
          title: 'Carregando…',
          showBrandMark: false,
          leading: SurfaceIconButton(
            icon: Icons.arrow_back_rounded,
            onPressed: onBack,
            semanticLabel: 'Voltar',
          ),
        ),
        const Expanded(
          child: Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          ),
        ),
      ],
    );
  }
}

class _NotFoundView extends StatelessWidget {
  const _NotFoundView({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        BrandHeader(
          title: 'Orçamento',
          showBrandMark: false,
          leading: SurfaceIconButton(
            icon: Icons.arrow_back_rounded,
            onPressed: onBack,
            semanticLabel: 'Voltar',
          ),
        ),
        const Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_off_rounded,
                    size: 64, color: AppColors.textMuted),
                SizedBox(height: 16),
                Text('Orçamento não encontrado',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content({required this.budget});
  final Budget budget;

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Excluir orçamento'),
        content: const Text('Tem certeza? Essa ação não pode ser desfeita.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Excluir',
                  style: TextStyle(color: AppColors.primary))),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(budgetListProvider.notifier).delete(budget.id);
      if (context.mounted) {
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Falha ao excluir: $e')));
      }
    }
  }

  Future<void> _share(BuildContext context) async {
    if (budget.items.isEmpty) return;
    final choice = await _pickShareFormat(context);
    if (choice == null) return;

    if (choice == _ShareAs.text) {
      await SharePlus.instance.share(
        ShareParams(
          text: _buildShareText(budget),
          subject: 'Orçamento - ${budget.clientName}',
        ),
      );
      return;
    }

    final doc = await buildBudgetPdf(budget);
    final bytes = await doc.save();
    await Printing.sharePdf(
      bytes: bytes,
      filename: _pdfFilename(budget),
    );
  }

  Future<_ShareAs?> _pickShareFormat(BuildContext context) {
    return showModalBottomSheet<_ShareAs>(
      context: context,
      backgroundColor: AppColors.graphiteElev,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 6),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.chromeEdgeStrong,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Row(
                children: [
                  Icon(Icons.ios_share_rounded, color: AppColors.ignition),
                  SizedBox(width: 12),
                  Text('Compartilhar como',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.chat_bubble_outline_rounded,
                  color: AppColors.statusApproved),
              title: const Text('Texto (WhatsApp, SMS…)',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600)),
              subtitle: const Text('Mensagem direta, fácil de colar',
                  style: TextStyle(
                      color: AppColors.textMuted, fontSize: 12)),
              onTap: () => Navigator.pop(context, _ShareAs.text),
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_rounded,
                  color: AppColors.ignition),
              title: const Text('PDF',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600)),
              subtitle: const Text('Documento formal, pronto pra imprimir',
                  style: TextStyle(
                      color: AppColors.textMuted, fontSize: 12)),
              onTap: () => Navigator.pop(context, _ShareAs.pdf),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  String _buildShareText(Budget b) {
    final sb = StringBuffer();
    final date = DateFormat('dd/MM/yyyy').format(b.createdAt);
    sb.writeln('*BOX JM* — Estética Automotiva');
    sb.writeln('Orçamento · $date');
    sb.writeln('');
    sb.writeln('*Cliente:* ${b.clientName.isEmpty ? "—" : b.clientName}');
    if (b.clientPhone.isNotEmpty) {
      sb.writeln('*Telefone:* ${b.clientPhone}');
    }
    final veh = '${b.vehicleBrand} ${b.vehicleModel}'.trim();
    sb.writeln(
        '*Veículo:* ${veh.isEmpty ? "—" : veh} (${b.vehicleType.label})');
    sb.writeln('');
    sb.writeln('*Serviços:*');
    for (var i = 0; i < b.items.length; i++) {
      final item = b.items[i];
      final qty = item.quantity > 1 ? ' (×${item.quantity})' : '';
      final lineTotal =
          Currency.format(item.basePrice * item.quantity * b.multiplier);
      sb.writeln('${i + 1}. ${item.serviceName}$qty — $lineTotal');
    }
    sb.writeln('');
    sb.writeln('*TOTAL: ${Currency.format(b.total)}*');
    if ((b.notes ?? '').trim().isNotEmpty) {
      sb.writeln('');
      sb.writeln('*Observações:*');
      sb.writeln(b.notes!.trim());
    }
    sb.writeln('');
    sb.writeln('Obrigado pela preferência! 🚗✨');
    return sb.toString();
  }

  String _pdfFilename(Budget b) {
    final date = DateFormat('yyyyMMdd').format(b.createdAt);
    final raw = b.clientName.trim().toLowerCase();
    final safe = raw.isEmpty
        ? 'cliente'
        : raw.replaceAll(RegExp(r'[^a-z0-9]+'), '-').replaceAll(
            RegExp(r'^-+|-+$'),
            '',
          );
    return 'orcamento-${safe.isEmpty ? "cliente" : safe}-$date.pdf';
  }

  Future<void> _editTotal(BuildContext context, WidgetRef ref) async {
    final controller =
        TextEditingController(text: budget.total.toStringAsFixed(2));
    final newTotal = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Editar Valor Total'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Os valores dos serviços serão ajustados proporcionalmente.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration:
                  const InputDecoration(prefixText: 'R\$ ', hintText: '0.00'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          TextButton(
              onPressed: () {
                final v = double.tryParse(controller.text.replaceAll(',', '.'));
                if (v == null || v <= 0) return;
                Navigator.pop(context, v);
              },
              child: const Text('Salvar',
                  style: TextStyle(color: AppColors.primary))),
        ],
      ),
    );
    if (newTotal == null) return;

    final factor = newTotal / budget.total;
    final adjusted = budget.items
        .map((item) => item.copyWith(
              basePrice: Currency.round2(item.basePrice * factor),
            ))
        .toList();
    final newSubtotal = Currency.round2(
        adjusted.fold<double>(0, (sum, i) => sum + (i.basePrice * i.quantity)));

    try {
      await ref.read(budgetListProvider.notifier).editBudget(
            budget.id,
            BudgetUpdate(
              items: adjusted,
              subtotal: newSubtotal,
              total: Currency.round2(newTotal),
            ),
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Valor atualizado')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha ao atualizar o valor')),
        );
      }
    }
  }

  Future<void> _duplicate(BuildContext context, WidgetRef ref) async {
    try {
      final copy = budget.copyWith(
        id: generateId(),
        status: BudgetStatus.draft,
        createdAt: DateTime.now(),
      );
      await ref.read(budgetListProvider.notifier).create(copy);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Orçamento duplicado')),
        );
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/');
        }
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha ao duplicar')),
        );
      }
    }
  }

  Future<void> _changeStatus(
      BuildContext context, WidgetRef ref, BudgetStatus status) async {
    try {
      await ref
          .read(budgetListProvider.notifier)
          .editBudget(budget.id, BudgetUpdate(status: status));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status atualizado')),
        );
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Falha ao atualizar status')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _Header(
          onBack: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
          onShare: () => _share(context),
          onEdit: () => context.push('/budget/${budget.id}/edit'),
          onDuplicate: () => _duplicate(context, ref),
          onDelete: () => _confirmDelete(context, ref),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            children: [
              AppCard(
                title: 'Cliente',
                trailing: StatusBadge(status: budget.status),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(budget.clientName, style: AppTextStyles.cardClient),
                    if (budget.clientPhone.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      _info(Icons.phone_rounded, budget.clientPhone),
                    ],
                  ],
                ),
              ),
              AppCard(
                title: 'Veículo',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${budget.vehicleBrand} ${budget.vehicleModel}',
                        style: AppTextStyles.cardTitle),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _InfoPill(
                            icon: Icons.directions_car_rounded,
                            label: budget.vehicleType.label,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _InfoPill(
                            icon: Icons.calculate_rounded,
                            label: '×${budget.multiplier.toStringAsFixed(1)}',
                            accent: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              AppCard(
                title: 'Serviços',
                child: Column(
                  children: [
                    for (var i = 0; i < budget.items.length; i++)
                      _ServiceLine(
                        item: budget.items[i],
                        isLast: i == budget.items.length - 1,
                      ),
                  ],
                ),
              ),
              if ((budget.notes ?? '').isNotEmpty)
                AppCard(
                  title: 'Observações',
                  child: Text(budget.notes!,
                      style: const TextStyle(
                          fontSize: 13.5,
                          height: 1.5,
                          color: AppColors.textSoft)),
                ),
              TotalsCard(
                subtotal: budget.subtotal,
                multiplier: budget.multiplier,
                total: budget.total,
                onEditTotal: () => _editTotal(context, ref),
                heroTag: 'budget-total-${budget.id}',
              ),
              AppCard(
                title: 'Atualizar Status',
                child: Column(
                  children: [
                    for (final s in [
                      BudgetStatus.sent,
                      BudgetStatus.approved,
                      BudgetStatus.completed,
                    ])
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _StatusButton(
                          status: s,
                          active: budget.status == s,
                          onTap: () => _changeStatus(context, ref, s),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 20),
                child: Center(
                  child: Text(
                    'Criado em ${DateFormat("dd/MM/yyyy 'às' HH:mm").format(budget.createdAt)}',
                    style: const TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _info(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Text(text,
            style: const TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500)),
      ],
    );
  }
}

class _BudgetDetailPageColors {
  static const statusColors = {
    BudgetStatus.draft: AppColors.statusDraft,
    BudgetStatus.sent: AppColors.statusSent,
    BudgetStatus.approved: AppColors.statusApproved,
    BudgetStatus.completed: AppColors.statusCompleted,
  };
}

class _Header extends StatelessWidget {
  const _Header({
    required this.onBack,
    required this.onShare,
    required this.onEdit,
    required this.onDuplicate,
    required this.onDelete,
  });

  final VoidCallback onBack;
  final VoidCallback onShare;
  final VoidCallback onEdit;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return BrandHeader(
      title: 'Detalhes',
      subtitle: 'Orçamento',
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      leading: SurfaceIconButton(
        icon: Icons.arrow_back_rounded,
        onPressed: onBack,
        semanticLabel: 'Voltar',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SurfaceIconButton(
            icon: Icons.share_rounded,
            onPressed: onShare,
            accent: AppColors.statusApproved,
            tooltip: 'Compartilhar',
          ),
          const SizedBox(width: 8),
          SurfaceIconButton(
            icon: Icons.edit_rounded,
            onPressed: onEdit,
            accent: AppColors.statusSent,
            tooltip: 'Editar',
          ),
          const SizedBox(width: 8),
          _MoreMenu(
            onDuplicate: onDuplicate,
            onDelete: onDelete,
          ),
        ],
      ),
    );
  }
}

class _MoreMenu extends StatelessWidget {
  const _MoreMenu({required this.onDuplicate, required this.onDelete});
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  void _open(BuildContext context) async {
    final v = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.graphiteElev,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.chromeEdgeStrong,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 18, 20, 6),
              child: Row(
                children: [
                  Icon(Icons.tune_rounded, color: AppColors.ignition),
                  SizedBox(width: 12),
                  Text('Mais opções',
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.copy_rounded,
                  color: AppColors.statusSent),
              title: const Text('Duplicar',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600)),
              subtitle: const Text('Criar uma cópia como rascunho',
                  style:
                      TextStyle(color: AppColors.textMuted, fontSize: 12)),
              onTap: () => Navigator.pop(context, 'duplicate'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.ignition),
              title: const Text('Excluir',
                  style: TextStyle(
                      color: AppColors.ignition,
                      fontWeight: FontWeight.w600)),
              subtitle: const Text('Remover permanentemente o orçamento',
                  style:
                      TextStyle(color: AppColors.textMuted, fontSize: 12)),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
    if (v == 'duplicate') onDuplicate();
    if (v == 'delete') onDelete();
  }

  @override
  Widget build(BuildContext context) {
    return SurfaceIconButton(
      icon: Icons.more_vert_rounded,
      onPressed: () => _open(context),
      tooltip: 'Mais opções',
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.label,
    this.accent,
  });
  final IconData icon;
  final String label;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final color = accent ?? AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: accent ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceLine extends StatelessWidget {
  const _ServiceLine({required this.item, required this.isLast});
  final BudgetItem item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final hasQuantity = item.quantity > 1;
    final subtitle = hasQuantity
        ? '${Currency.format(item.basePrice)} × ${item.quantity}'
        : null;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : const Border(
                bottom: BorderSide(color: AppColors.borderSoft),
              ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.serviceName,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    )),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textMuted,
                          fontWeight: FontWeight.w500)),
                ],
              ],
            ),
          ),
          Text(Currency.format(item.basePrice * item.quantity),
              style: AppTextStyles.moneyInline),
        ],
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({
    required this.status,
    required this.active,
    required this.onTap,
  });
  final BudgetStatus status;
  final bool active;
  final VoidCallback onTap;

  static const _icons = {
    BudgetStatus.draft: Icons.edit_note_rounded,
    BudgetStatus.sent: Icons.send_rounded,
    BudgetStatus.approved: Icons.check_circle_rounded,
    BudgetStatus.completed: Icons.verified_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final color = _BudgetDetailPageColors.statusColors[status]!;
    return Material(
      color: active ? color.withValues(alpha: 0.14) : AppColors.surfaceSoft,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  active ? color.withValues(alpha: 0.6) : AppColors.borderSoft,
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Icon(_icons[status],
                  size: 18, color: active ? color : AppColors.textSecondary),
              const SizedBox(width: 10),
              Text(status.label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: active ? color : AppColors.textPrimary,
                  )),
              const Spacer(),
              if (active) Icon(Icons.check_rounded, size: 18, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
