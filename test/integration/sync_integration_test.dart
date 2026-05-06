import 'package:boxjm/data/datasources/budget_remote_datasource.dart';
import 'package:boxjm/data/datasources/catalog_remote_datasource.dart';
import 'package:boxjm/data/datasources/local_storage_datasource.dart';
import 'package:boxjm/data/repositories/sync_service.dart';
import 'package:boxjm/domain/entities/budget.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'test_helpers.dart';

void main() {
  late SupabaseClient client;
  late LocalStorageDataSource local;

  setUp(() async {
    client = createSupabaseClient();
    // Fresh SharedPreferences mock for each test
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    local = LocalStorageDataSource(prefs);
  });

  tearDownAll(() async {
    await cleanupTestData(client);
  });

  group('SyncService — fetchAndCache', () {
    test('busca budgets e services do remoto e salva no local', () async {
      // Criar um budget no remoto
      final budget = makeTestBudget();
      trackBudgetId(budget.id);
      final budgetDs = BudgetRemoteDataSource(client);
      await budgetDs.create(budget);

      final sync = SyncService(
        local: local,
        budgetRemote: budgetDs,
        catalogRemote: CatalogRemoteDataSource(client),
      );

      await sync.fetchAndCache();

      // Verificar que o budget está no cache local
      final cachedBudgets = local.getBudgets();
      expect(cachedBudgets.any((b) => b.id == budget.id), isTrue);

      // Verificar que os services estão no cache local
      final cachedServices = local.getServices();
      expect(cachedServices, isNotEmpty);
    });
  });

  group('SyncService — processQueue com budgetCreate', () {
    test('sincroniza budget criado offline', () async {
      final budget = makeTestBudget();
      trackBudgetId(budget.id);

      // Salvar no local
      final cached = local.getBudgets();
      local.saveBudgets([budget, ...cached]);

      // Adicionar operação de sync
      local.addSyncOp(SyncOp.budgetCreate(budget));

      final sync = SyncService(
        local: local,
        budgetRemote: BudgetRemoteDataSource(client),
        catalogRemote: CatalogRemoteDataSource(client),
      );

      await sync.processQueue();

      // Verificar que o budget está no Supabase
      final remoteBudgets = await BudgetRemoteDataSource(client).getAll();
      expect(remoteBudgets.any((b) => b.id == budget.id), isTrue);

      // Verificar que a operação foi removida da queue
      final queue = local.getSyncQueue();
      expect(queue.isEmpty, isTrue);
    });
  });

  group('SyncService — processQueue com budgetUpdate', () {
    test('sincroniza atualização de budget feita offline', () async {
      // Primeiro, criar um budget no remoto
      final budget = makeTestBudget();
      trackBudgetId(budget.id);
      final budgetDs = BudgetRemoteDataSource(client);
      await budgetDs.create(budget);

      // Salvar versão atualizada no local
      final updated = budget.copyWith(clientName: 'Nome Atualizado Offline');
      local.saveBudgets([updated]);

      // Adicionar operação de sync
      const update = BudgetUpdate(clientName: 'Nome Atualizado Offline');
      local.addSyncOp(SyncOp.budgetUpdate(budget.id, update));

      final sync = SyncService(
        local: local,
        budgetRemote: budgetDs,
        catalogRemote: CatalogRemoteDataSource(client),
      );

      await sync.processQueue();

      // Verificar que o update chegou no remoto
      final remote = await budgetDs.getAll();
      final found = remote.firstWhere((b) => b.id == budget.id);
      expect(found.clientName, 'Nome Atualizado Offline');
    });
  });

  group('SyncService — processQueue com budgetDelete', () {
    test('sincroniza deleção de budget feita offline', () async {
      // Criar budget no remoto
      final budget = makeSimpleTestBudget();
      trackBudgetId(budget.id);
      final budgetDs = BudgetRemoteDataSource(client);
      await budgetDs.create(budget);

      // Remover do local e adicionar operação de sync
      local.saveBudgets(local.getBudgets().where((b) => b.id != budget.id).toList());
      local.addSyncOp(SyncOp.budgetDelete(budget.id));

      final sync = SyncService(
        local: local,
        budgetRemote: budgetDs,
        catalogRemote: CatalogRemoteDataSource(client),
      );

      await sync.processQueue();

      // Verificar que o budget foi deletado no remoto
      final remote = await budgetDs.getAll();
      expect(remote.where((b) => b.id == budget.id), isEmpty);
    });
  });

  group('SyncService — processQueue com serviceUpsert', () {
    test('sincroniza serviço criado offline', () async {
      final service = makeTestService();
      trackServiceId(service.id);

      // Adicionar no local e criar operação de sync
      final cached = local.getServices();
      local.saveServices([service, ...cached]);
      local.addSyncOp(SyncOp.serviceUpsert(service));

      final sync = SyncService(
        local: local,
        budgetRemote: BudgetRemoteDataSource(client),
        catalogRemote: CatalogRemoteDataSource(client),
      );

      await sync.processQueue();

      // Verificar que o serviço está no Supabase
      final catalogDs = CatalogRemoteDataSource(client);
      final remote = await catalogDs.getAll();
      expect(remote.any((s) => s.id == service.id), isTrue);

      // Limpar
      await catalogDs.delete(service.id);
    });
  });

  group('SyncService — syncAll', () {
    test('processa queue e depois atualiza cache', () async {
      // Criar budget no remoto
      final budget = makeSimpleTestBudget();
      trackBudgetId(budget.id);
      final budgetDs = BudgetRemoteDataSource(client);
      await budgetDs.create(budget);

      final sync = SyncService(
        local: local,
        budgetRemote: budgetDs,
        catalogRemote: CatalogRemoteDataSource(client),
      );

      await sync.syncAll();

      // Verificar que o cache local tem o budget
      final cachedBudgets = local.getBudgets();
      expect(cachedBudgets.any((b) => b.id == budget.id), isTrue);
    });
  });

  group('LocalStorage — Serialização', () {
    test('budget round-trip: save → get', () {
      final budget = makeTestBudget();
      local.saveBudgets([budget]);

      final restored = local.getBudgets();
      expect(restored.length, 1);
      expect(restored.first.id, budget.id);
      expect(restored.first.clientName, budget.clientName);
      expect(restored.first.clientPhone, budget.clientPhone);
      expect(restored.first.vehicleBrand, budget.vehicleBrand);
      expect(restored.first.vehicleModel, budget.vehicleModel);
      expect(restored.first.vehicleType, budget.vehicleType);
      expect(restored.first.subtotal, budget.subtotal);
      expect(restored.first.multiplier, budget.multiplier);
      expect(restored.first.total, budget.total);
      expect(restored.first.status, budget.status);
      expect(restored.first.notes, budget.notes);
      expect(restored.first.items.length, budget.items.length);
    });

    test('service round-trip: save → get', () {
      final service = makeTestService();
      local.saveServices([service]);

      final restored = local.getServices();
      expect(restored.length, 1);
      expect(restored.first.id, service.id);
      expect(restored.first.name, service.name);
      expect(restored.first.basePrice, service.basePrice);
      expect(restored.first.category, service.category);
      expect(restored.first.description, service.description);
    });

    test('syncQueue round-trip: add → get', () {
      final budget = makeTestBudget();
      local.addSyncOp(SyncOp.budgetCreate(budget));

      final queue = local.getSyncQueue();
      expect(queue.length, 1);
      expect(queue.first.type, SyncOpType.budgetCreate);
      expect(queue.first.payload['id'], budget.id);
    });

    test('syncQueue: add → remove', () async {
      final budget = makeTestBudget();
      final op = SyncOp.budgetCreate(budget);
      local.addSyncOp(op);

      var queue = local.getSyncQueue();
      expect(queue.length, 1);

      await local.removeSyncOp(op.id);

      queue = local.getSyncQueue();
      expect(queue.length, 0);
    });

    test('SyncOp serializa/deserializa corretamente', () {
      final budget = makeTestBudget();
      final op = SyncOp.budgetCreate(budget);
      final json = op.toJson();
      final restored = SyncOp.fromJson(json);

      expect(restored.id, op.id);
      expect(restored.type, SyncOpType.budgetCreate);
      expect(restored.payload['id'], budget.id);
    });
  });
}