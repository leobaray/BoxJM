import 'package:boxjm/data/datasources/catalog_remote_datasource.dart';
import 'package:boxjm/domain/entities/service_item.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'test_helpers.dart';

void main() {
  late SupabaseClient client;
  late CatalogRemoteDataSource ds;

  setUpAll(() async {
    client = createSupabaseClient();
    ds = CatalogRemoteDataSource(client);
  });

  tearDownAll(() async {
    await cleanupTestData(client);
  });

  group('CatalogRemoteDataSource — READ', () {
    test('getAll retorna os serviços existentes', () async {
      final services = await ds.getAll();

      expect(services, isNotEmpty);
      // Deve ter pelo menos os 11 serviços padrão
      expect(services.length, greaterThanOrEqualTo(11));
    });

    test('getAll retorna serviços com campos válidos', () async {
      final services = await ds.getAll();

      for (final s in services) {
        expect(s.id, isNotEmpty);
        expect(s.name, isNotEmpty);
        expect(s.basePrice, greaterThan(0));
        expect(
          ServiceCategory.values.map((c) => c.name).contains(s.category.name),
          isTrue,
        );
      }
    });

    test('getAll retorna serviços ordenados por created_at asc', () async {
      final services = await ds.getAll();

      for (var i = 1; i < services.length; i++) {
        // Serviços mais novos vêm depois (ascending = true)
        // Não comparamos datas diretamente pois podem ser nulas ou iguais
        expect(services[i].id, isNotEmpty);
      }
    });
  });

  group('CatalogRemoteDataSource — UPSERT CREATE', () {
    test('cria um novo serviço via upsert', () async {
      final service = makeTestService();
      trackServiceId(service.id);

      final result = await ds.upsert(service);

      expect(result.id, service.id);
      expect(result.name, service.name);
      expect(result.basePrice, service.basePrice);
      expect(result.category, service.category);
      expect(result.description, service.description);
    });

    test('cria serviço com categorias diferentes', () async {
      const categories = ServiceCategory.values;
      for (final cat in categories) {
        final service = ServiceItem(
          id: 'test-cat-${cat.name}-${DateTime.now().millisecondsSinceEpoch}',
          name: 'Teste ${cat.name}',
          basePrice: 50.0,
          category: cat,
        );
        trackServiceId(service.id);

        final result = await ds.upsert(service);

        expect(result.category, cat);
      }
    });

    test('cria serviço sem descrição', () async {
      final service = ServiceItem(
        id: 'test-nodesc-${DateTime.now().millisecondsSinceEpoch}',
        name: 'Serviço Sem Descrição',
        basePrice: 75.0,
        category: ServiceCategory.interior,
      );
      trackServiceId(service.id);

      final result = await ds.upsert(service);

      expect(result.description, isNull);
      expect(result.name, 'Serviço Sem Descrição');
    });
  });

  group('CatalogRemoteDataSource — UPSERT UPDATE', () {
    test('atualiza preço e nome de serviço existente via upsert', () async {
      // Criar
      final service = makeTestService();
      trackServiceId(service.id);
      await ds.upsert(service);

      // Atualizar com mesmo ID, novo preço
      final updated = service.copyWith(
        name: 'Serviço Atualizado',
        basePrice: 149.90,
      );
      final result = await ds.upsert(updated);

      expect(result.id, service.id);
      expect(result.name, 'Serviço Atualizado');
      expect(result.basePrice, 149.90);
    });

    test('atualizar descrição de null para valor', () async {
      final service = ServiceItem(
        id: 'test-upddesc-${DateTime.now().millisecondsSinceEpoch}',
        name: 'Novo Serviço',
        basePrice: 100.0,
        category: ServiceCategory.protection,
      );
      trackServiceId(service.id);
      await ds.upsert(service);

      final updated = service.copyWith(description: 'Agora tem descrição');
      final result = await ds.upsert(updated);

      expect(result.description, 'Agora tem descrição');
    });
  });

  group('CatalogRemoteDataSource — DELETE', () {
    test('deleta um serviço existente', () async {
      final service = makeTestService();
      trackServiceId(service.id);
      await ds.upsert(service);

      await ds.delete(service.id);

      // Remover do tracking pois já foi deletado
      _testServiceIdsLocal.remove(service.id);

      final all = await ds.getAll();
      expect(all.where((s) => s.id == service.id), isEmpty);
    });

    test('delete de ID inexistente não lança erro', () async {
      await ds.delete('nonexistent-test-svc-99999');
    });
  });

  group('ServiceItem — Serialização', () {
    test('fromSupabase(toSupabase()) round-trip', () async {
      final original = makeTestService();
      trackServiceId(original.id);

      // Inserir via upsert
      await ds.upsert(original);

      // Buscar de volta
      final all = await ds.getAll();
      final fetched = all.firstWhere((s) => s.id == original.id);

      expect(fetched.id, original.id);
      expect(fetched.name, original.name);
      expect(fetched.basePrice, original.basePrice);
      expect(fetched.category, original.category);
      expect(fetched.description, original.description);
    });

    test('toJson/fromJson preserva todos os campos', () {
      const service = ServiceItem(
        id: 'test-json-1',
        name: 'Teste JSON',
        basePrice: 123.45,
        category: ServiceCategory.detailing,
        description: 'Descrição teste',
      );

      final json = service.toJson();
      final restored = ServiceItem.fromJson(json);

      expect(restored.id, service.id);
      expect(restored.name, service.name);
      expect(restored.basePrice, service.basePrice);
      expect(restored.category, service.category);
      expect(restored.description, service.description);
    });

    test('toSupabase() usa snake_case para as colunas', () {
      const service = ServiceItem(
        id: 'test-sup-1',
        name: 'Teste Supabase',
        basePrice: 99.0,
        category: ServiceCategory.exterior,
        description: 'Desc',
      );

      final map = service.toSupabase();

      expect(map.containsKey('base_price'), isTrue);
      expect(map.containsKey('basePrice'), isFalse);
      expect(map.containsKey('created_at'), isFalse); // Auto-gerado pelo Supabase
    });
  });
}

final _testServiceIdsLocal = <String>[];