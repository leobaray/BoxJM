import '../../core/utils/app_logger.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/service_item.dart';
import '../datasources/budget_remote_datasource.dart';
import '../datasources/catalog_remote_datasource.dart';
import '../datasources/local_storage_datasource.dart';

class SyncService {
  SyncService({
    required LocalStorageDataSource local,
    required BudgetRemoteDataSource budgetRemote,
    required CatalogRemoteDataSource catalogRemote,
  })  : _local = local,
        _budgetRemote = budgetRemote,
        _catalogRemote = catalogRemote;

  final LocalStorageDataSource _local;
  final BudgetRemoteDataSource _budgetRemote;
  final CatalogRemoteDataSource _catalogRemote;
  final _log = AppLogger('SyncService');

  /// Número máximo de tentativas por operação antes de descartá-la.
  /// Evita que uma op "envenenada" (payload inválido, conflito irrecuperável)
  /// bloqueie a fila para sempre.
  static const _maxAttempts = 5;

  Future<void> processQueue() async {
    final queue = _local.getSyncQueue();
    if (queue.isEmpty) return;

    for (final op in queue) {
      try {
        await _execute(op);
        await _local.removeSyncOp(op.id);
        _log.info('op ${op.type.name}#${op.id} sincronizada');
      } catch (e, st) {
        final attempts = op.attempts + 1;
        if (attempts >= _maxAttempts) {
          _log.error(
            'descartando op ${op.type.name}#${op.id} após $_maxAttempts '
            'tentativas',
            e,
            st,
          );
          await _local.removeSyncOp(op.id);
          continue;
        }
        _log.warn(
          'falha em ${op.type.name}#${op.id} (tentativa $attempts/$_maxAttempts)',
          e,
        );
        await _local.updateSyncOpAttempts(op.id, attempts);
        // Segue processando as próximas ops — elas podem não ter dependência
        // com a que falhou. Se a falha for de rede geral, a próxima também
        // vai falhar e eventualmente todas são descartadas ou a conexão volta.
        continue;
      }
    }
  }

  Future<void> _execute(SyncOp op) async {
    switch (op.type) {
      case SyncOpType.budgetCreate:
        await _budgetRemote.create(Budget.fromJson(op.payload));
        break;
      case SyncOpType.budgetUpdate:
        final id = op.payload['id'] as String;
        final updates = BudgetUpdate.fromJson(
          Map<String, dynamic>.from(op.payload['updates'] as Map),
        );
        await _budgetRemote.update(id, updates);
        break;
      case SyncOpType.budgetDelete:
        await _budgetRemote.delete(op.payload['id'] as String);
        break;
      case SyncOpType.serviceUpsert:
        await _catalogRemote.upsert(ServiceItem.fromJson(op.payload));
        break;
      case SyncOpType.serviceDelete:
        await _catalogRemote.delete(op.payload['id'] as String);
        break;
    }
  }

  Future<void> fetchAndCache() async {
    try {
      final results = await Future.wait([
        _budgetRemote.getAll(),
        _catalogRemote.getAll(),
      ]);
      await _local.saveBudgets(results[0] as List<Budget>);
      await _local.saveServices(results[1] as List<ServiceItem>);
      _log.info('cache atualizado com remoto');
    } catch (e, st) {
      _log.warn('fetchAndCache falhou (provavelmente offline)', e);
      _log.error('stack', e, st);
    }
  }

  Future<void> syncAll() async {
    await processQueue();
    await fetchAndCache();
  }
}
