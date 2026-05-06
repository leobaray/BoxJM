import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/utils/id.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/service_item.dart';

class LocalStorageDataSource {
  LocalStorageDataSource(this._prefs);

  final SharedPreferences _prefs;

  static const _keyBudgets = 'boxjm:budgets';
  static const _keyServices = 'boxjm:services';
  static const _keySyncQueue = 'boxjm:sync_queue';

  // ── Budgets ──────────────────────────────────────────────────────────────
  List<Budget> getBudgets() {
    final raw = _prefs.getString(_keyBudgets);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) {
            try {
              return Budget.fromJson(Map<String, dynamic>.from(e as Map));
            } catch (_) {
              return null;
            }
          })
          .whereType<Budget>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveBudgets(List<Budget> budgets) async {
    final raw = jsonEncode(budgets.map((b) => b.toJson()).toList());
    await _prefs.setString(_keyBudgets, raw);
  }

  // ── Services ─────────────────────────────────────────────────────────────
  List<ServiceItem> getServices() {
    final raw = _prefs.getString(_keyServices);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) {
            try {
              return ServiceItem.fromJson(Map<String, dynamic>.from(e as Map));
            } catch (_) {
              return null;
            }
          })
          .whereType<ServiceItem>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveServices(List<ServiceItem> services) async {
    final raw = jsonEncode(services.map((s) => s.toJson()).toList());
    await _prefs.setString(_keyServices, raw);
  }

  // ── Sync queue ───────────────────────────────────────────────────────────
  List<SyncOp> getSyncQueue() {
    final raw = _prefs.getString(_keySyncQueue);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) {
            try {
              return SyncOp.fromJson(Map<String, dynamic>.from(e as Map));
            } catch (_) {
              return null;
            }
          })
          .whereType<SyncOp>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveSyncQueue(List<SyncOp> queue) async {
    final raw = jsonEncode(queue.map((op) => op.toJson()).toList());
    await _prefs.setString(_keySyncQueue, raw);
  }

  Future<void> addSyncOp(SyncOp op) async {
    final queue = getSyncQueue()..add(op);
    await _saveSyncQueue(queue);
  }

  Future<void> removeSyncOp(String opId) async {
    final queue = getSyncQueue().where((op) => op.id != opId).toList();
    await _saveSyncQueue(queue);
  }

  Future<void> updateSyncOpAttempts(String opId, int attempts) async {
    final queue = getSyncQueue()
        .map((op) => op.id == opId ? op.copyWith(attempts: attempts) : op)
        .toList();
    await _saveSyncQueue(queue);
  }
}

// ── Sync op model ──────────────────────────────────────────────────────────
enum SyncOpType {
  budgetCreate,
  budgetUpdate,
  budgetDelete,
  serviceUpsert,
  serviceDelete,
}

class SyncOp {
  final String id;
  final SyncOpType type;
  final Map<String, dynamic> payload;

  /// Contador de tentativas já gastas nessa op. Quando atinge o limite do
  /// SyncService, a op é descartada para não travar a fila.
  final int attempts;

  SyncOp({
    required this.id,
    required this.type,
    required this.payload,
    this.attempts = 0,
  });

  SyncOp copyWith({int? attempts}) => SyncOp(
        id: id,
        type: type,
        payload: payload,
        attempts: attempts ?? this.attempts,
      );

  factory SyncOp.budgetCreate(Budget budget) => SyncOp(
        id: generateId(),
        type: SyncOpType.budgetCreate,
        payload: budget.toJson(),
      );

  factory SyncOp.budgetUpdate(String budgetId, BudgetUpdate updates) => SyncOp(
        id: generateId(),
        type: SyncOpType.budgetUpdate,
        payload: {'id': budgetId, 'updates': updates.toJson()},
      );

  factory SyncOp.budgetDelete(String budgetId) => SyncOp(
        id: generateId(),
        type: SyncOpType.budgetDelete,
        payload: {'id': budgetId},
      );

  factory SyncOp.serviceUpsert(ServiceItem service) => SyncOp(
        id: generateId(),
        type: SyncOpType.serviceUpsert,
        payload: service.toJson(),
      );

  factory SyncOp.serviceDelete(String serviceId) => SyncOp(
        id: generateId(),
        type: SyncOpType.serviceDelete,
        payload: {'id': serviceId},
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'payload': payload,
        'attempts': attempts,
      };

  factory SyncOp.fromJson(Map<String, dynamic> json) => SyncOp(
        id: json['id'] as String,
        type: SyncOpType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () {
            // Tipo desconhecido — devolve algo que o SyncService tolera.
            // A op vai falhar no _execute e cair no fluxo de descarte.
            return SyncOpType.budgetCreate;
          },
        ),
        payload: Map<String, dynamic>.from(json['payload'] as Map),
        attempts: (json['attempts'] as num?)?.toInt() ?? 0,
      );
}
