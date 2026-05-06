import 'package:flutter/material.dart';

import '../../core/constants/catalog.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/service_item.dart';
import 'gradient_button.dart';

Future<void> showServiceEditorSheet({
  required BuildContext context,
  ServiceItem? service,
  required ValueChanged<ServiceItem> onSave,
  ValueChanged<String>? onDelete,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ServiceEditorSheet(
      service: service,
      onSave: onSave,
      onDelete: onDelete,
    ),
  );
}

class _ServiceEditorSheet extends StatefulWidget {
  const _ServiceEditorSheet({
    required this.service,
    required this.onSave,
    this.onDelete,
  });

  final ServiceItem? service;
  final ValueChanged<ServiceItem> onSave;
  final ValueChanged<String>? onDelete;

  @override
  State<_ServiceEditorSheet> createState() => _ServiceEditorSheetState();
}

class _ServiceEditorSheetState extends State<_ServiceEditorSheet> {
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _description;
  late ServiceCategory _category;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.service?.name ?? '');
    _price = TextEditingController(
        text: widget.service?.basePrice.toStringAsFixed(2) ?? '');
    _description =
        TextEditingController(text: widget.service?.description ?? '');
    _category = widget.service?.category ?? ServiceCategory.exterior;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _description.dispose();
    super.dispose();
  }

  void _save() {
    final priceText = _price.text.replaceAll(',', '.');
    final priceValue = double.tryParse(priceText);
    if (_name.text.trim().isEmpty || priceValue == null || priceValue <= 0) {
      return;
    }
    final svc = ServiceItem(
      id: widget.service?.id ??
          'custom-${DateTime.now().millisecondsSinceEpoch}',
      name: _name.text.trim(),
      basePrice: priceValue,
      category: _category,
      description:
          _description.text.trim().isEmpty ? null : _description.text.trim(),
    );
    widget.onSave(svc);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.service != null;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.92,
        ),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderStrong,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primaryTint,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isEdit ? Icons.edit_rounded : Icons.add_circle_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isEdit ? 'Editar Serviço' : 'Novo Serviço',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          isEdit
                              ? 'Atualize as informações do serviço'
                              : 'Adicione um serviço ao catálogo',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.borderSoft),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Nome do Serviço'),
                    TextField(
                      controller: _name,
                      decoration: const InputDecoration(
                          hintText: 'Ex: Polimento Premium'),
                    ),
                    _label('Preço Base (R\$)'),
                    TextField(
                      controller: _price,
                      decoration: const InputDecoration(hintText: '0.00'),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                    ),
                    _label('Categoria'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ServiceCategory.values.map((c) {
                        final sel = c == _category;
                        return Material(
                          color: sel
                              ? AppColors.primaryTintSoft
                              : AppColors.surfaceSoft,
                          borderRadius: BorderRadius.circular(20),
                          child: InkWell(
                            onTap: () => setState(() => _category = c),
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 9),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: sel
                                      ? AppColors.primary.withValues(alpha: 0.6)
                                      : AppColors.border,
                                  width: 1.2,
                                ),
                              ),
                              child: Text(
                                categoryLabels[c] ?? c.name,
                                style: TextStyle(
                                  color: sel
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    _label('Descrição (opcional)'),
                    TextField(
                      controller: _description,
                      maxLines: 3,
                      decoration: const InputDecoration(
                          hintText: 'Detalhes sobre o serviço...'),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.borderSoft),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    if (isEdit && widget.onDelete != null) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            widget.onDelete!(widget.service!.id);
                            Navigator.of(context).pop();
                          },
                          icon: const Icon(Icons.delete_outline_rounded,
                              color: AppColors.primary, size: 18),
                          label: const Text('Excluir',
                              style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700)),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                                color:
                                    AppColors.primary.withValues(alpha: 0.5)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      flex: 2,
                      child: GradientButton(
                        onPressed: _save,
                        icon: Icons.check_rounded,
                        label: 'Salvar',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: AppColors.textMuted,
            letterSpacing: 0.6,
          ),
        ),
      );
}
