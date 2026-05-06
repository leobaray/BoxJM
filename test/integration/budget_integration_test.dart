import 'package:boxjm/data/datasources/budget_remote_datasource.dart';
import 'package:boxjm/domain/entities/budget.dart';
import 'package:boxjm/domain/entities/vehicle_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'test_helpers.dart';

void main() {
  late SupabaseClient client;
  late BudgetRemoteDataSource ds;

  setUpAll(() async {
    client = createSupabaseClient();
    ds = BudgetRemoteDataSource(client);
  });

  tearDownAll(() async {
    await cleanupTestData(client);
  });

  group('BudgetRemoteDataSource — CREATE', () {
    test('cria um budget completo e retorna com dados corretos', () async {
      final budget = makeTestBudget();
      trackBudgetId(budget.id);

      final result = await ds.create(budget);

      expect(result.id, budget.id);
      expect(result.clientName, budget.clientName);
      expect(result.clientPhone, budget.clientPhone);
      expect(result.vehicleBrand, budget.vehicleBrand);
      expect(result.vehicleModel, budget.vehicleModel);
      expect(result.vehicleType, budget.vehicleType);
      expect(result.subtotal, budget.subtotal);
      expect(result.multiplier, budget.multiplier);
      expect(result.total, budget.total);
      expect(result.status, budget.status);
      expect(result.notes, budget.notes);
      expect(result.items.length, 2);
      expect(result.items[0].serviceId, 'ext-wash-basic');
      expect(result.items[0].quantity, 2);
      expect(result.items[1].serviceId, 'int-aspiracao');
      expect(result.items[1].quantity, 1);
    });

    test('cria budget com campos mínimos', () async {
      final budget = makeSimpleTestBudget();
      trackBudgetId(budget.id);

      final result = await ds.create(budget);

      expect(result.id, budget.id);
      expect(result.clientName, 'João Silva');
      expect(result.vehicleBrand, 'Honda');
      expect(result.items.length, 1);
    });
  });

  group('BudgetRemoteDataSource — READ', () {
    test('getAll retorna lista incluindo budgets criados', () async {
      // Criar 2 budgets
      final b1 = makeTestBudget();
      final b2 = makeSimpleTestBudget();
      trackBudgetId(b1.id);
      trackBudgetId(b2.id);

      await ds.create(b1);
      await ds.create(b2);

      final all = await ds.getAll();

      final ids = all.map((b) => b.id).toList();
      expect(ids, contains(b1.id));
      expect(ids, contains(b2.id));
    });

    test('getAll retorna lista ordenada por created_at desc', () async {
      final b1 = makeTestBudget();
      // Pequena pausa para garantir timestamp diferente
      await Future.delayed(const Duration(milliseconds: 100));
      final b2 = makeSimpleTestBudget();
      trackBudgetId(b1.id);
      trackBudgetId(b2.id);

      await ds.create(b1);
      await ds.create(b2);

      final all = await ds.getAll();
      final testBudgets = all.where((b) => b.id == b1.id || b.id == b2.id).toList();

      // b2 foi criado depois, deve vir primeiro
      expect(testBudgets.first.id, b2.id);
    });
  });

  group('BudgetRemoteDataSource — UPDATE', () {
    test('atualiza status do budget', () async {
      final budget = makeTestBudget();
      trackBudgetId(budget.id);
      await ds.create(budget);

      const updates = BudgetUpdate(status: BudgetStatus.sent);
      final result = await ds.update(budget.id, updates);

      expect(result.id, budget.id);
      expect(result.status, BudgetStatus.sent);
      // Outros campos permanecem inalterados
      expect(result.clientName, budget.clientName);
      expect(result.vehicleBrand, budget.vehicleBrand);
    });

    test('atualiza múltiplos campos de uma vez', () async {
      final budget = makeTestBudget(status: BudgetStatus.draft);
      trackBudgetId(budget.id);
      await ds.create(budget);

      const updates = BudgetUpdate(
        clientName: 'Maria Oliveira',
        vehicleBrand: 'Hyundai',
        vehicleModel: 'Tucson',
        vehicleType: VehicleType.suv,
        status: BudgetStatus.approved,
        notes: 'Aprovado pelo cliente',
      );
      final result = await ds.update(budget.id, updates);

      expect(result.clientName, 'Maria Oliveira');
      expect(result.vehicleBrand, 'Hyundai');
      expect(result.vehicleModel, 'Tucson');
      expect(result.vehicleType, VehicleType.suv);
      expect(result.status, BudgetStatus.approved);
      expect(result.notes, 'Aprovado pelo cliente');
    });

    test('atualiza items e recalcula total', () async {
      final budget = makeTestBudget();
      trackBudgetId(budget.id);
      await ds.create(budget);

      final newItems = [
        const BudgetItem(
          serviceId: 'ext-wash-premium',
          serviceName: 'Lavagem Premium',
          basePrice: 80.0,
          quantity: 1,
        ),
      ];
      final updates = BudgetUpdate(
        items: newItems,
        subtotal: 80.0,
        total: 96.0,
      );
      final result = await ds.update(budget.id, updates);

      expect(result.items.length, 1);
      expect(result.items[0].serviceId, 'ext-wash-premium');
      expect(result.subtotal, 80.0);
      expect(result.total, 96.0);
    });
  });

  group('BudgetRemoteDataSource — DELETE', () {
    test('deleta um budget existente', () async {
      final budget = makeTestBudget();
      trackBudgetId(budget.id);
      await ds.create(budget);

      await ds.delete(budget.id);

      // Remover da lista de cleanup já que foi deletado
      _testBudgetIdsLocal.remove(budget.id);

      final all = await ds.getAll();
      expect(all.where((b) => b.id == budget.id), isEmpty);
    });

    test('delete de ID inexistente não lança erro', () async {
      // Supabase DELETE com eq que não encontra nada retorna sucesso
      await ds.delete('nonexistent-test-id-99999');
    });
  });

  group('Budget — Serialização round-trip', () {
    test('Budget.fromSupabase(toSupabaseInsert()) preserva todos os campos', () async {
      final original = makeTestBudget();
      trackBudgetId(original.id);

      // Inserir no Supabase
      await ds.create(original);

      // Buscar de volta
      final all = await ds.getAll();
      final fetched = all.firstWhere((b) => b.id == original.id);

      // Verificar campos
      expect(fetched.id, original.id);
      expect(fetched.clientName, original.clientName);
      expect(fetched.clientPhone, original.clientPhone);
      expect(fetched.vehicleBrand, original.vehicleBrand);
      expect(fetched.vehicleModel, original.vehicleModel);
      expect(fetched.vehicleType, original.vehicleType);
      expect(fetched.subtotal, original.subtotal);
      expect(fetched.multiplier, original.multiplier);
      expect(fetched.total, original.total);
      expect(fetched.status, original.status);
      expect(fetched.notes, original.notes);
      expect(fetched.items.length, original.items.length);
      for (var i = 0; i < fetched.items.length; i++) {
        expect(fetched.items[i].serviceId, original.items[i].serviceId);
        expect(fetched.items[i].serviceName, original.items[i].serviceName);
        expect(fetched.items[i].basePrice, original.items[i].basePrice);
        expect(fetched.items[i].quantity, original.items[i].quantity);
      }
    });

    test('Budget com notes null serializa corretamente', () async {
      final budget = Budget(
        id: 'test-null-notes-${DateTime.now().millisecondsSinceEpoch}',
        clientName: 'Sem Observação',
        clientPhone: '(11) 11111-1111',
        vehicleBrand: 'Fiat',
        vehicleModel: 'Uno',
        vehicleType: VehicleType.small,
        items: [],
        subtotal: 0,
        multiplier: 1.0,
        total: 0,
        status: BudgetStatus.draft,
        createdAt: DateTime.now(),
      );
      trackBudgetId(budget.id);

      final result = await ds.create(budget);
      expect(result.notes, isNull);
    });

    test('BudgetUpdate.toSupabase() inclui apenas campos não null', () {
      const update = BudgetUpdate(status: BudgetStatus.completed);
      final map = update.toSupabase();

      expect(map.containsKey('status'), isTrue);
      expect(map['status'], 'completed');
      expect(map.containsKey('client_name'), isFalse);
      expect(map.containsKey('items'), isFalse);
    });
  });
}

// Local tracking to remove IDs that were already deleted.
final _testBudgetIdsLocal = <String>[];