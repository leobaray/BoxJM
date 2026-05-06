import 'package:boxjm/domain/entities/budget.dart';
import 'package:boxjm/domain/entities/service_item.dart';
import 'package:boxjm/domain/entities/vehicle_type.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _supabaseUrl = 'https://bbfseptqqaowqfejwovy.supabase.co';
const _supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.'
    'eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJiZnNlcHRxcWFvd3FmZWp3b3Z5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzYzNTgwNTIsImV4cCI6MjA5MTkzNDA1Mn0.'
    'k_EwXv77aqWKjFiLHPNQWf8z6lumLcTDWXJ6vIklQJA';

/// Budget IDs created during tests — cleaned up in tearDown.
final _testBudgetIds = <String>[];

/// Service IDs created during tests — cleaned up in tearDown.
final _testServiceIds = <String>[];

/// Create a SupabaseClient directly (skips SharedPreferences dependency).
/// Use this for integration tests that only need the REST client.
SupabaseClient createSupabaseClient() {
  return SupabaseClient(_supabaseUrl, _supabaseAnonKey);
}

/// Delete all test budgets and services created during the test run.
/// Call in tearDown (or tearDownAll).
Future<void> cleanupTestData(SupabaseClient client) async {
  for (final id in _testBudgetIds) {
    try {
      await client.from('budgets').delete().eq('id', id);
    } catch (_) {}
  }
  _testBudgetIds.clear();

  for (final id in _testServiceIds) {
    try {
      await client.from('services').delete().eq('id', id);
    } catch (_) {}
  }
  _testServiceIds.clear();
}

/// Track a budget ID for automatic cleanup.
void trackBudgetId(String id) => _testBudgetIds.add(id);

/// Track a service ID for automatic cleanup.
void trackServiceId(String id) => _testServiceIds.add(id);

// ── Fixtures ──────────────────────────────────────────────────────────────

/// A complete Budget suitable for insert tests.
Budget makeTestBudget({String? id, BudgetStatus status = BudgetStatus.draft}) {
  final budgetId = id ?? 'test-budget-${DateTime.now().millisecondsSinceEpoch}';
  return Budget(
    id: budgetId,
    clientName: 'Cliente Teste',
    clientPhone: '(11) 99999-0000',
    vehicleBrand: 'Toyota',
    vehicleModel: 'Corolla',
    vehicleType: VehicleType.medium,
    items: [
      const BudgetItem(
        serviceId: 'ext-wash-basic',
        serviceName: 'Lavagem Básica',
        basePrice: 50.0,
        quantity: 2,
      ),
      const BudgetItem(
        serviceId: 'int-aspiracao',
        serviceName: 'Aspiração',
        basePrice: 40.0,
        quantity: 1,
      ),
    ],
    subtotal: 140.0,
    multiplier: 1.2,
    total: 168.0,
    status: status,
    notes: 'Observação de teste',
    createdAt: DateTime.now(),
  );
}

/// A simple Budget with minimum fields.
Budget makeSimpleTestBudget({String? id}) {
  final budgetId = id ?? 'test-simple-${DateTime.now().millisecondsSinceEpoch}';
  return Budget(
    id: budgetId,
    clientName: 'João Silva',
    clientPhone: '',
    vehicleBrand: 'Honda',
    vehicleModel: 'Civic',
    vehicleType: VehicleType.medium,
    items: [
      const BudgetItem(
        serviceId: 'ext-wash-premium',
        serviceName: 'Lavagem Premium',
        basePrice: 80.0,
        quantity: 1,
      ),
    ],
    subtotal: 80.0,
    multiplier: 1.2,
    total: 96.0,
    status: BudgetStatus.draft,
    createdAt: DateTime.now(),
  );
}

/// A ServiceItem suitable for insert tests.
ServiceItem makeTestService({String? id}) {
  final serviceId = id ?? 'test-svc-${DateTime.now().millisecondsSinceEpoch}';
  return ServiceItem(
    id: serviceId,
    name: 'Serviço de Teste',
    basePrice: 99.90,
    category: ServiceCategory.exterior,
    description: 'Descrição do serviço de teste',
  );
}