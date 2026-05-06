import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/catalog.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/budget_calc.dart';
import '../../core/utils/currency.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/id.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/service_item.dart';
import '../../domain/entities/vehicle_type.dart';
import '../providers/providers.dart';
import '../widgets/brand_header.dart';
import '../widgets/gradient_button.dart';
import '../widgets/qty_button.dart';
import '../widgets/service_item_tile.dart';
import '../widgets/totals_card.dart';
import '../widgets/vehicle_type_selector.dart';

class NewBudgetPage extends ConsumerStatefulWidget {
  const NewBudgetPage({super.key, this.editingBudgetId});

  final String? editingBudgetId;

  @override
  ConsumerState<NewBudgetPage> createState() => _NewBudgetPageState();
}

class _NewBudgetPageState extends ConsumerState<NewBudgetPage> {
  final _client = TextEditingController();
  final _phone = TextEditingController();
  final _brand = TextEditingController();
  final _model = TextEditingController();
  final _notes = TextEditingController();

  VehicleType _vehicleType = VehicleType.medium;
  final Map<String, int> _selected = {};
  final Map<String, double> _customPrices = {};
  final Set<ServiceCategory> _expandedCategories = {
    ServiceCategory.exterior,
  };

  // Original values for dirty checking in edit mode
  String _origClient = '';
  String _origPhone = '';
  String _origBrand = '';
  String _origModel = '';
  String _origNotes = '';
  VehicleType _origVehicleType = VehicleType.medium;
  Map<String, int> _origSelected = {};
  Map<String, double> _origCustomPrices = {};

  bool _hydrated = false;
  bool _saving = false;

  @override
  void dispose() {
    _client.dispose();
    _phone.dispose();
    _brand.dispose();
    _model.dispose();
    _notes.dispose();
    super.dispose();
  }

  bool get _isEdit => widget.editingBudgetId != null;

  bool get _isDirty {
    if (_saving) return false;
    if (_isEdit) {
      // Compare against original hydrated values
      return _client.text != _origClient ||
          _phone.text != _origPhone ||
          _brand.text != _origBrand ||
          _model.text != _origModel ||
          _notes.text != _origNotes ||
          _vehicleType != _origVehicleType ||
          !_mapsEqual(_selected, _origSelected) ||
          !_mapsEqual(_customPrices, _origCustomPrices);
    }
    // New budget: dirty if anything is filled
    return _client.text.isNotEmpty ||
        _phone.text.isNotEmpty ||
        _brand.text.isNotEmpty ||
        _model.text.isNotEmpty ||
        _notes.text.isNotEmpty ||
        _selected.isNotEmpty;
  }

  static bool _mapsEqual<K, V>(Map<K, V> a, Map<K, V> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }

  void _hydrateFromBudget(Budget b) {
    if (_hydrated) return;
    _client.text = b.clientName;
    _phone.text = b.clientPhone;
    _brand.text = b.vehicleBrand;
    _model.text = b.vehicleModel;
    _notes.text = b.notes ?? '';
    _vehicleType = b.vehicleType;
    _selected
      ..clear()
      ..addEntries(b.items.map((i) => MapEntry(i.serviceId, i.quantity)));
    _customPrices
      ..clear()
      ..addEntries(b.items.map((i) => MapEntry(i.serviceId, i.basePrice)));
    // Save originals for dirty checking
    _origClient = _client.text;
    _origPhone = _phone.text;
    _origBrand = _brand.text;
    _origModel = _model.text;
    _origNotes = _notes.text;
    _origVehicleType = _vehicleType;
    _origSelected = Map.from(_selected);
    _origCustomPrices = Map.from(_customPrices);
    _hydrated = true;
  }

  Future<bool> _confirmDiscard() async {
    if (!_isDirty) return true;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Descartar alterações?'),
        content:
            const Text('Você tem dados preenchidos. Deseja sair sem salvar?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Continuar editando'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Descartar',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _save() async {
    if (_client.text.trim().isEmpty) {
      _snack('Preencha o nome do cliente');
      return;
    }
    if (_brand.text.trim().isEmpty) {
      _snack('Preencha a marca do veículo');
      return;
    }
    if (_model.text.trim().isEmpty) {
      _snack('Preencha o modelo do veículo');
      return;
    }
    if (_selected.isEmpty) {
      _snack('Adicione pelo menos um serviço');
      return;
    }

    final services = ref.read(catalogListProvider).valueOrNull ?? const [];
    final items = <BudgetItem>[];
    for (final e in _selected.entries) {
      final svc = services.where((s) => s.id == e.key).firstOrNull;
      if (svc == null) continue;
      items.add(BudgetItem(
        serviceId: svc.id,
        serviceName: svc.name,
        basePrice: _customPrices[svc.id] ?? svc.basePrice,
        quantity: e.value,
      ));
    }

    final totals = calculateTotals(items, _vehicleType);
    final controller = ref.read(budgetListProvider.notifier);

    setState(() => _saving = true);
    try {
      if (_isEdit) {
        await controller.editBudget(
          widget.editingBudgetId!,
          BudgetUpdate(
            clientName: _client.text.trim(),
            clientPhone: _phone.text.trim(),
            vehicleBrand: _brand.text.trim(),
            vehicleModel: _model.text.trim(),
            vehicleType: _vehicleType,
            items: items,
            subtotal: totals.subtotal,
            multiplier: totals.multiplier,
            total: totals.total,
            notes: _notes.text.trim(),
          ),
        );
        if (mounted) {
          _snack('Orçamento atualizado');
          context.pop();
        }
      } else {
        await controller.create(
          Budget(
            id: generateId(),
            clientName: _client.text.trim(),
            clientPhone: _phone.text.trim(),
            vehicleBrand: _brand.text.trim(),
            vehicleModel: _model.text.trim(),
            vehicleType: _vehicleType,
            items: items,
            subtotal: totals.subtotal,
            multiplier: totals.multiplier,
            total: totals.total,
            status: BudgetStatus.draft,
            notes: _notes.text.trim(),
            createdAt: DateTime.now(),
          ),
        );
        if (!mounted) return;
        _resetForm();
        _snack('Orçamento criado');
        context.pop();
      }
    } catch (_) {
      _snack('Não foi possível salvar o orçamento');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _resetForm() {
    setState(() {
      _client.clear();
      _phone.clear();
      _brand.clear();
      _model.clear();
      _notes.clear();
      _vehicleType = VehicleType.medium;
      _selected.clear();
      _customPrices.clear();
    });
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _editPrice(ServiceItem svc) async {
    final current = _customPrices[svc.id] ?? svc.basePrice;
    final controller = TextEditingController(text: Currency.format(current));
    final picked = await showDialog<double>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Preço de ${svc.name}',
            style: const TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          inputFormatters: [CurrencyInputFormatter()],
          decoration: const InputDecoration(hintText: 'R\$ 0,00'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          if (_customPrices.containsKey(svc.id))
            TextButton(
              onPressed: () => Navigator.pop(context, svc.basePrice),
              child: const Text('Restaurar',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
          TextButton(
            onPressed: () {
              final v = CurrencyInputFormatter.parse(controller.text);
              if (v == null || v <= 0) return;
              Navigator.pop(context, v);
            },
            child: const Text('Salvar',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
    if (picked == null) return;
    setState(() {
      if (picked == svc.basePrice) {
        _customPrices.remove(svc.id);
      } else {
        _customPrices[svc.id] = Currency.round2(picked);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final services = ref.watch(catalogListProvider).valueOrNull ?? const [];
    final budgets = ref.watch(budgetListProvider).valueOrNull ?? const [];

    if (_isEdit && !_hydrated) {
      final b =
          budgets.where((x) => x.id == widget.editingBudgetId).firstOrNull;
      if (b != null) {
        _hydrateFromBudget(b);
      } else {
        return const _LoadingScaffold();
      }
    }

    final items = <BudgetItem>[];
    for (final e in _selected.entries) {
      final svc = services.where((s) => s.id == e.key).firstOrNull;
      if (svc == null) continue;
      items.add(BudgetItem(
        serviceId: svc.id,
        serviceName: svc.name,
        basePrice: _customPrices[svc.id] ?? svc.basePrice,
        quantity: e.value,
      ));
    }

    final totals = calculateTotals(items, _vehicleType);
    final canSave = _selected.isNotEmpty && !_saving;

    final grouped = <ServiceCategory, List<ServiceItem>>{};
    for (final s in services) {
      grouped.putIfAbsent(s.category, () => []).add(s);
    }

    return PopScope(
      canPop: !_isDirty || _saving,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final ok = await _confirmDiscard();
        if (!mounted || !ok) return;
        if (context.mounted) context.pop();
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              BrandHeader(
                title: _isEdit ? 'Editar Orçamento' : 'Novo Orçamento',
                subtitle: _selected.isEmpty
                    ? 'Preencha os dados e selecione serviços'
                    : '${_selected.length} serviço${_selected.length == 1 ? '' : 's'} • ${Currency.format(totals.total)}',
                leading: _isEdit
                    ? BrandIconButton(
                        icon: Icons.arrow_back_rounded,
                        onPressed: () async {
                          final ok = await _confirmDiscard();
                          if (!mounted || !ok) return;
                          if (context.mounted) context.pop();
                        },
                      )
                    : null,
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    AppSpacing.navReserved +
                        24 +
                        MediaQuery.paddingOf(context).bottom,
                  ),
                  children: [
                    _section('Dados do Cliente', Icons.person_rounded),
                    TextField(
                      controller: _client,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                          hintText: 'Nome do cliente',
                          prefixIcon: Icon(Icons.person_outline_rounded)),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        PhoneInputFormatter(),
                      ],
                      decoration: const InputDecoration(
                          hintText: '(11) 99999-9999',
                          prefixIcon: Icon(Icons.phone_outlined)),
                    ),
                    const SizedBox(height: 24),
                    _section('Veículo', Icons.directions_car_rounded),
                    Row(children: [
                      Expanded(
                        child: TextField(
                          controller: _brand,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(hintText: 'Marca'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _model,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(hintText: 'Modelo'),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 16),
                    VehicleTypeSelector(
                      selected: _vehicleType,
                      onSelect: (t) => setState(() => _vehicleType = t),
                    ),
                    const SizedBox(height: 20),
                    _section('Serviços', Icons.build_rounded,
                        badge:
                            _selected.isEmpty ? null : '${_selected.length}'),
                    for (final cat in ServiceCategory.values)
                      if (grouped[cat] != null && grouped[cat]!.isNotEmpty)
                        _CategoryGroup(
                          category: cat,
                          services: grouped[cat]!,
                          selected: _selected,
                          customPrices: _customPrices,
                          expanded: _expandedCategories.contains(cat),
                          onToggleExpanded: () => setState(() {
                            if (_expandedCategories.contains(cat)) {
                              _expandedCategories.remove(cat);
                            } else {
                              _expandedCategories.add(cat);
                            }
                          }),
                          onToggleService: (svc) => setState(() {
                            if (_selected.containsKey(svc.id)) {
                              _selected.remove(svc.id);
                              _customPrices.remove(svc.id);
                            } else {
                              _selected[svc.id] = 1;
                            }
                          }),
                          onQuantityChange: (svc, delta) => setState(() {
                            final q = (_selected[svc.id] ?? 1) + delta;
                            _selected[svc.id] = q < 1 ? 1 : q;
                          }),
                          onEditPrice: _editPrice,
                        ),
                    const SizedBox(height: 20),
                    _section('Observações', Icons.sticky_note_2_rounded),
                    TextField(
                      controller: _notes,
                      maxLines: 4,
                      decoration: const InputDecoration(
                          hintText: 'Observações adicionais...'),
                    ),
                    const SizedBox(height: 22),
                    if (_selected.isNotEmpty)
                      TotalsCard(
                        subtotal: totals.subtotal,
                        multiplier: totals.multiplier,
                        total: totals.total,
                        margin: EdgeInsets.zero,
                      ),
                    const SizedBox(height: 14),
                    GradientButton(
                      onPressed: canSave ? _save : null,
                      loading: _saving,
                      icon: Icons.check_rounded,
                      label: _isEdit ? 'Salvar Alterações' : 'Criar Orçamento',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(String title, IconData icon, {String? badge}) => Padding(
        padding: const EdgeInsets.only(bottom: 12, top: 2),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(title, style: AppTextStyles.sectionTitle),
            if (badge != null) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(badge,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    )),
              ),
            ],
            const SizedBox(width: 10),
            Expanded(child: Container(height: 1, color: AppColors.borderSoft)),
          ],
        ),
      );
}

class _LoadingScaffold extends StatelessWidget {
  const _LoadingScaffold();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      ),
    );
  }
}

class _CategoryGroup extends StatelessWidget {
  const _CategoryGroup({
    required this.category,
    required this.services,
    required this.selected,
    required this.customPrices,
    required this.expanded,
    required this.onToggleExpanded,
    required this.onToggleService,
    required this.onQuantityChange,
    required this.onEditPrice,
  });

  final ServiceCategory category;
  final List<ServiceItem> services;
  final Map<String, int> selected;
  final Map<String, double> customPrices;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final ValueChanged<ServiceItem> onToggleService;
  final void Function(ServiceItem svc, int delta) onQuantityChange;
  final ValueChanged<ServiceItem> onEditPrice;

  @override
  Widget build(BuildContext context) {
    final selectedCount =
        services.where((s) => selected.containsKey(s.id)).length;
    final hasSelection = selectedCount > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: hasSelection
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: onToggleExpanded,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: hasSelection
                            ? AppColors.primaryTint
                            : AppColors.surfaceHigh,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Icon(iconForCategory(category),
                          color: hasSelection
                              ? AppColors.primary
                              : AppColors.textSecondary,
                          size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            categoryLabels[category] ?? category.name,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            hasSelection
                                ? '$selectedCount de ${services.length} selecionado${selectedCount == 1 ? '' : 's'}'
                                : '${services.length} serviço${services.length == 1 ? '' : 's'}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: hasSelection
                                  ? AppColors.primary
                                  : AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (hasSelection) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('$selectedCount',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            )),
                      ),
                      const SizedBox(width: 8),
                    ],
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 220),
                      turns: expanded ? 0.5 : 0,
                      child: const Icon(Icons.expand_more_rounded,
                          color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: !expanded
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                    child: Column(
                      children: [
                        for (final s in services)
                          _ServiceRow(
                            service: s,
                            selected: selected.containsKey(s.id),
                            quantity: selected[s.id] ?? 1,
                            customPrice: customPrices[s.id],
                            onToggle: () => onToggleService(s),
                            onQuantityChange: (d) => onQuantityChange(s, d),
                            onEditPrice: () => onEditPrice(s),
                          ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
    required this.service,
    required this.selected,
    required this.quantity,
    required this.customPrice,
    required this.onToggle,
    required this.onQuantityChange,
    required this.onEditPrice,
  });

  final ServiceItem service;
  final bool selected;
  final int quantity;
  final double? customPrice;
  final VoidCallback onToggle;
  final ValueChanged<int> onQuantityChange;
  final VoidCallback onEditPrice;

  @override
  Widget build(BuildContext context) {
    final effectivePrice = customPrice ?? service.basePrice;
    final hasCustom = customPrice != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected ? AppColors.primaryTintSoft : AppColors.surfaceSoft,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.65)
                    : AppColors.borderSoft,
                width: selected ? 1.4 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: selected ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(7),
                        border: Border.all(
                          color: selected
                              ? AppColors.primary
                              : AppColors.borderStrong,
                          width: 1.5,
                        ),
                      ),
                      child: selected
                          ? const Icon(Icons.check_rounded,
                              size: 14, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(service.name,
                              style: const TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                                height: 1.25,
                              )),
                          if (service.description != null) ...[
                            const SizedBox(height: 2),
                            Text(service.description!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  height: 1.3,
                                )),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _PriceTapTarget(
                      enabled: selected,
                      onTap: onEditPrice,
                      effectivePrice: effectivePrice,
                      basePrice: service.basePrice,
                      hasCustom: hasCustom,
                      showEditHint: selected && !hasCustom,
                    ),
                  ],
                ),
                if (selected)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        QtyButton(
                          icon: Icons.remove_rounded,
                          semanticLabel: 'Diminuir quantidade',
                          onPressed:
                              quantity > 1 ? () => onQuantityChange(-1) : null,
                        ),
                        SizedBox(
                          width: 40,
                          child: Text(
                            '$quantity',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        QtyButton(
                          icon: Icons.add_rounded,
                          semanticLabel: 'Aumentar quantidade',
                          onPressed: () => onQuantityChange(1),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceHigh,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Text(
                                'Total: ',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textMuted,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              Text(
                                Currency.format(effectivePrice * quantity),
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
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
    );
  }
}

class _PriceTapTarget extends StatelessWidget {
  const _PriceTapTarget({
    required this.enabled,
    required this.onTap,
    required this.effectivePrice,
    required this.basePrice,
    required this.hasCustom,
    required this.showEditHint,
  });

  final bool enabled;
  final VoidCallback onTap;
  final double effectivePrice;
  final double basePrice;
  final bool hasCustom;
  final bool showEditHint;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showEditHint) ...[
              const Icon(Icons.edit_rounded,
                  size: 12, color: AppColors.textSecondary),
              const SizedBox(width: 4),
            ],
            Text(
              Currency.format(effectivePrice),
              style: AppTextStyles.moneyInline.copyWith(
                color: hasCustom ? AppColors.statusApproved : AppColors.primary,
              ),
            ),
          ],
        ),
        if (hasCustom)
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              Currency.format(basePrice),
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
                decoration: TextDecoration.lineThrough,
              ),
            ),
          ),
      ],
    );

    if (!enabled) return content;

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        splashColor: AppColors.primaryTintSoft,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: content,
        ),
      ),
    );
  }
}
