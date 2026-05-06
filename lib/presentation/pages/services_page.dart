import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/catalog.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/currency.dart';
import '../../domain/entities/service_item.dart';
import '../providers/providers.dart';
import '../widgets/brand_header.dart';
import '../widgets/service_editor_sheet.dart';
import '../widgets/service_item_tile.dart';

class ServicesPage extends ConsumerStatefulWidget {
  const ServicesPage({super.key});

  @override
  ConsumerState<ServicesPage> createState() => _ServicesPageState();
}

class _ServicesPageState extends ConsumerState<ServicesPage> {
  ServiceCategory? _expanded = ServiceCategory.exterior;

  @override
  Widget build(BuildContext context) {
    final asyncServices = ref.watch(catalogListProvider);

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          BrandHeader(
            title: 'Catálogo',
            subtitle: 'Serviços disponíveis',
            trailing: _AddButton(onTap: () => _openEditor(null)),
            contextLine: _CatalogContext(asyncServices: asyncServices),
          ),
          Expanded(
            child: asyncServices.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.ignition)),
              error: (e, _) => Center(
                child: Text('Erro: $e',
                    style: const TextStyle(color: AppColors.textSecondary)),
              ),
              data: (services) {
                final grouped = <ServiceCategory, List<ServiceItem>>{};
                for (final s in services) {
                  grouped.putIfAbsent(s.category, () => []).add(s);
                }
                final categories =
                    ServiceCategory.values.where(grouped.containsKey);
                return ListView(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    AppSpacing.navReserved +
                        MediaQuery.paddingOf(context).bottom,
                  ),
                  children: [
                    for (final cat in categories)
                      _CategorySection(
                        category: cat,
                        services: grouped[cat]!,
                        expanded: _expanded == cat,
                        onToggle: () => setState(() {
                          _expanded = _expanded == cat ? null : cat;
                        }),
                        onServiceTap: _openEditor,
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openEditor(ServiceItem? service) {
    showServiceEditorSheet(
      context: context,
      service: service,
      onSave: (svc) => ref.read(catalogListProvider.notifier).save(svc),
      onDelete: (id) => ref.read(catalogListProvider.notifier).delete(id),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        splashColor: Colors.white.withValues(alpha: 0.14),
        child: Ink(
          decoration: BoxDecoration(
            gradient: AppColors.ignitionGradient,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            boxShadow: AppShadows.ignition(intensity: 0.9),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              const SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.add_rounded,
                    color: Colors.white, size: 24),
              ),
              Positioned(
                top: 3,
                left: 10,
                right: 10,
                child: Container(
                  height: 1,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0),
                        Colors.white.withValues(alpha: 0.5),
                        Colors.white.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CatalogContext extends StatelessWidget {
  const _CatalogContext({required this.asyncServices});
  final AsyncValue<List<ServiceItem>> asyncServices;

  @override
  Widget build(BuildContext context) {
    final services = asyncServices.valueOrNull;
    final count = services?.length ?? 0;
    final avg = services == null || services.isEmpty
        ? 0.0
        : services.fold<double>(0, (s, i) => s + i.basePrice) /
            services.length;

    return Row(
      children: [
        const Icon(Icons.auto_awesome_rounded,
            size: 12, color: AppColors.textMuted),
        const SizedBox(width: 5),
        Text(
          '$count serviço${count == 1 ? '' : 's'} no catálogo',
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.25,
          ),
        ),
        const Spacer(),
        if (count > 0)
          HeaderContextPill(
            icon: Icons.payments_rounded,
            label: '~ ${Currency.format(avg)}',
            accent: AppColors.accent,
          ),
      ],
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.category,
    required this.services,
    required this.expanded,
    required this.onToggle,
    required this.onServiceTap,
  });

  final ServiceCategory category;
  final List<ServiceItem> services;
  final bool expanded;
  final VoidCallback onToggle;
  final ValueChanged<ServiceItem> onServiceTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF181822), Color(0xFF101018)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: expanded
              ? AppColors.ignition.withValues(alpha: 0.45)
              : AppColors.border,
          width: expanded ? 1.2 : 1,
        ),
        boxShadow: expanded
            ? AppShadows.statusGlow(AppColors.ignition, intensity: 0.6)
            : AppShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.xl),
            child: InkWell(
              onTap: onToggle,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              splashColor: AppColors.emberSoft,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: expanded
                            ? AppColors.ignitionGradient
                            : null,
                        color: expanded ? null : AppColors.graphiteHigh,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: expanded
                              ? Colors.transparent
                              : AppColors.border,
                        ),
                        boxShadow: expanded
                            ? AppShadows.ignition(intensity: 0.7)
                            : null,
                      ),
                      child: Icon(iconForCategory(category),
                          color: expanded
                              ? Colors.white
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
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${services.length} serviço${services.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      duration: const Duration(milliseconds: 220),
                      turns: expanded ? 0.5 : 0,
                      child: Icon(
                        Icons.expand_more_rounded,
                        color: expanded
                            ? AppColors.ignition
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: !expanded
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                    child: Column(
                      children: [
                        Container(
                          height: 1,
                          decoration: const BoxDecoration(
                            gradient: AppColors.hairlineGradient,
                          ),
                        ),
                        const SizedBox(height: 8),
                        for (final s in services)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Material(
                              color: AppColors.graphite,
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: () => onServiceTap(s),
                                borderRadius: BorderRadius.circular(12),
                                splashColor: AppColors.emberSoft,
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: AppColors.borderSoft),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 4,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          gradient: const LinearGradient(
                                            colors: [
                                              Color(0xFFFF6363),
                                              Color(0xFFB91C1C),
                                            ],
                                            begin: Alignment.topCenter,
                                            end: Alignment.bottomCenter,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          boxShadow: [
                                            BoxShadow(
                                              color: AppColors.ignition
                                                  .withValues(alpha: 0.35),
                                              blurRadius: 6,
                                              offset: const Offset(1, 0),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(s.name,
                                                style: const TextStyle(
                                                  fontSize: 14.5,
                                                  fontWeight: FontWeight.w700,
                                                  color:
                                                      AppColors.textPrimary,
                                                )),
                                            if (s.description != null) ...[
                                              const SizedBox(height: 3),
                                              Text(
                                                s.description!,
                                                maxLines: 1,
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: AppColors
                                                      .textSecondary,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(Currency.format(s.basePrice),
                                              style: AppTextStyles
                                                  .moneyInline),
                                          const SizedBox(height: 2),
                                          const Icon(
                                            Icons.edit_rounded,
                                            size: 14,
                                            color: AppColors.textMuted,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
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
