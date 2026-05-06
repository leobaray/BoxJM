import '../../core/constants/catalog.dart';
import '../../core/utils/currency.dart';
import 'vehicle_type.dart';

enum BudgetStatus {
  draft,
  sent,
  approved,
  completed;

  static BudgetStatus fromString(String? value) {
    return BudgetStatus.values.firstWhere(
      (s) => s.name == value,
      orElse: () => BudgetStatus.draft,
    );
  }

  String get label => switch (this) {
        BudgetStatus.draft => 'Rascunho',
        BudgetStatus.sent => 'Enviado',
        BudgetStatus.approved => 'Aprovado',
        BudgetStatus.completed => 'Concluído',
      };
}

class BudgetItem {
  final String serviceId;
  final String serviceName;
  final double basePrice;
  final int quantity;

  const BudgetItem({
    required this.serviceId,
    required this.serviceName,
    required this.basePrice,
    required this.quantity,
  });

  BudgetItem copyWith({
    String? serviceId,
    String? serviceName,
    double? basePrice,
    int? quantity,
  }) {
    return BudgetItem(
      serviceId: serviceId ?? this.serviceId,
      serviceName: serviceName ?? this.serviceName,
      basePrice: basePrice ?? this.basePrice,
      quantity: quantity ?? this.quantity,
    );
  }

  factory BudgetItem.fromJson(Map<String, dynamic> json) => BudgetItem(
        serviceId: json['serviceId'] as String,
        serviceName: json['serviceName'] as String,
        basePrice: (json['basePrice'] as num).toDouble(),
        quantity: (json['quantity'] as num).toInt(),
      );

  Map<String, dynamic> toJson() => {
        'serviceId': serviceId,
        'serviceName': serviceName,
        'basePrice': basePrice,
        'quantity': quantity,
      };
}

class Budget {
  final String id;
  final String clientName;
  final String clientPhone;
  final String vehicleBrand;
  final String vehicleModel;
  final VehicleType vehicleType;
  final List<BudgetItem> items;
  final double subtotal;
  final double multiplier;
  final double total;
  final BudgetStatus status;
  final String? notes;
  final DateTime createdAt;

  static const _notesCleared = Object();

  const Budget({
    required this.id,
    required this.clientName,
    required this.clientPhone,
    required this.vehicleBrand,
    required this.vehicleModel,
    required this.vehicleType,
    required this.items,
    required this.subtotal,
    required this.multiplier,
    required this.total,
    required this.status,
    required this.createdAt,
    this.notes,
  });

  Budget copyWith({
    String? id,
    String? clientName,
    String? clientPhone,
    String? vehicleBrand,
    String? vehicleModel,
    VehicleType? vehicleType,
    List<BudgetItem>? items,
    double? subtotal,
    double? multiplier,
    double? total,
    BudgetStatus? status,
    Object? notes = _notesCleared,
    DateTime? createdAt,
  }) {
    return Budget(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      clientPhone: clientPhone ?? this.clientPhone,
      vehicleBrand: vehicleBrand ?? this.vehicleBrand,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleType: vehicleType ?? this.vehicleType,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      multiplier: multiplier ?? this.multiplier,
      total: total ?? this.total,
      status: status ?? this.status,
      notes: identical(notes, _notesCleared) ? this.notes : notes as String?,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Budget.fromJson(Map<String, dynamic> json) => Budget(
        id: json['id'] as String,
        clientName: json['clientName'] as String? ?? '',
        clientPhone: json['clientPhone'] as String? ?? '',
        vehicleBrand: json['vehicleBrand'] as String? ?? '',
        vehicleModel: json['vehicleModel'] as String? ?? '',
        vehicleType: VehicleType.fromString(json['vehicleType'] as String?),
        items: (json['items'] as List<dynamic>? ?? [])
            .map((e) => BudgetItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
        multiplier: (json['multiplier'] as num?)?.toDouble() ?? 1,
        total: (json['total'] as num?)?.toDouble() ?? 0,
        status: BudgetStatus.fromString(json['status'] as String?),
        notes: json['notes'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'clientName': clientName,
        'clientPhone': clientPhone,
        'vehicleBrand': vehicleBrand,
        'vehicleModel': vehicleModel,
        'vehicleType': vehicleType.name,
        'items': items.map((i) => i.toJson()).toList(),
        'subtotal': subtotal,
        'multiplier': multiplier,
        'total': total,
        'status': status.name,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Budget.fromSupabase(Map<String, dynamic> row) => Budget(
        id: row['id'] as String,
        clientName: row['client_name'] as String? ?? '',
        clientPhone: row['client_phone'] as String? ?? '',
        vehicleBrand: row['vehicle_brand'] as String? ?? '',
        vehicleModel: row['vehicle_model'] as String? ?? '',
        vehicleType: VehicleType.fromString(row['vehicle_type'] as String?),
        items: (row['items'] as List<dynamic>? ?? [])
            .map(
                (e) => BudgetItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        subtotal: (row['subtotal'] as num?)?.toDouble() ?? 0,
        multiplier: (row['multiplier'] as num?)?.toDouble() ?? 1,
        total: (row['total'] as num?)?.toDouble() ?? 0,
        status: BudgetStatus.fromString(row['status'] as String?),
        notes: row['notes'] as String?,
        createdAt: DateTime.parse(row['created_at'] as String),
      );

  Map<String, dynamic> toSupabaseInsert() => {
        'id': id,
        'client_name': clientName,
        'client_phone': clientPhone,
        'vehicle_brand': vehicleBrand,
        'vehicle_model': vehicleModel,
        'vehicle_type': vehicleType.name,
        'items': items.map((i) => i.toJson()).toList(),
        'subtotal': subtotal,
        'multiplier': multiplier,
        'total': total,
        'status': status.name,
        'notes': notes,
        'created_at': createdAt.toIso8601String(),
      };
}

class BudgetUpdate {
  final String? clientName;
  final String? clientPhone;
  final String? vehicleBrand;
  final String? vehicleModel;
  final VehicleType? vehicleType;
  final List<BudgetItem>? items;
  final double? subtotal;
  final double? multiplier;
  final double? total;
  final BudgetStatus? status;
  final String? notes;

  const BudgetUpdate({
    this.clientName,
    this.clientPhone,
    this.vehicleBrand,
    this.vehicleModel,
    this.vehicleType,
    this.items,
    this.subtotal,
    this.multiplier,
    this.total,
    this.status,
    this.notes,
  });

  Map<String, dynamic> toSupabase() {
    final map = <String, dynamic>{};
    if (clientName != null) map['client_name'] = clientName;
    if (clientPhone != null) map['client_phone'] = clientPhone;
    if (vehicleBrand != null) map['vehicle_brand'] = vehicleBrand;
    if (vehicleModel != null) map['vehicle_model'] = vehicleModel;
    if (vehicleType != null) map['vehicle_type'] = vehicleType!.name;
    if (items != null) {
      map['items'] = items!.map((i) => i.toJson()).toList();
    }
    if (subtotal != null) map['subtotal'] = subtotal;
    if (multiplier != null) map['multiplier'] = multiplier;
    if (total != null) map['total'] = total;
    if (status != null) map['status'] = status!.name;
    if (notes != null) map['notes'] = notes;
    return map;
  }

  Budget apply(Budget b) {
    final effectiveItems = items ?? b.items;
    final effectiveVehicleType = vehicleType ?? b.vehicleType;

    // Recalculate totals when items or vehicleType changed unless explicitly provided
    final double effectiveSubtotal;
    final double effectiveMultiplier;
    final double effectiveTotal;
    if (items != null || vehicleType != null) {
      final sub = effectiveItems.fold<double>(
        0,
        (sum, item) => sum + (item.basePrice * item.quantity),
      );
      final mult = multiplierFor(effectiveVehicleType);
      effectiveSubtotal = subtotal ?? Currency.round2(sub);
      effectiveMultiplier = multiplier ?? mult;
      effectiveTotal = total ?? Currency.round2(sub * mult);
    } else {
      effectiveSubtotal = subtotal ?? b.subtotal;
      effectiveMultiplier = multiplier ?? b.multiplier;
      effectiveTotal = total ?? b.total;
    }

    return b.copyWith(
      clientName: clientName,
      clientPhone: clientPhone,
      vehicleBrand: vehicleBrand,
      vehicleModel: vehicleModel,
      vehicleType: vehicleType,
      items: items,
      subtotal: effectiveSubtotal,
      multiplier: effectiveMultiplier,
      total: effectiveTotal,
      status: status,
      notes: notes,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{};
    if (clientName != null) map['clientName'] = clientName;
    if (clientPhone != null) map['clientPhone'] = clientPhone;
    if (vehicleBrand != null) map['vehicleBrand'] = vehicleBrand;
    if (vehicleModel != null) map['vehicleModel'] = vehicleModel;
    if (vehicleType != null) map['vehicleType'] = vehicleType!.name;
    if (items != null) {
      map['items'] = items!.map((i) => i.toJson()).toList();
    }
    if (subtotal != null) map['subtotal'] = subtotal;
    if (multiplier != null) map['multiplier'] = multiplier;
    if (total != null) map['total'] = total;
    if (status != null) map['status'] = status!.name;
    if (notes != null) map['notes'] = notes;
    return map;
  }

  factory BudgetUpdate.fromJson(Map<String, dynamic> json) => BudgetUpdate(
        clientName: json['clientName'] as String?,
        clientPhone: json['clientPhone'] as String?,
        vehicleBrand: json['vehicleBrand'] as String?,
        vehicleModel: json['vehicleModel'] as String?,
        vehicleType: json['vehicleType'] != null
            ? VehicleType.fromString(json['vehicleType'] as String)
            : null,
        items: (json['items'] as List<dynamic>?)
            ?.map((e) => BudgetItem.fromJson(e as Map<String, dynamic>))
            .toList(),
        subtotal: (json['subtotal'] as num?)?.toDouble(),
        multiplier: (json['multiplier'] as num?)?.toDouble(),
        total: (json['total'] as num?)?.toDouble(),
        status: json['status'] != null
            ? BudgetStatus.fromString(json['status'] as String)
            : null,
        notes: json['notes'] as String?,
      );
}
