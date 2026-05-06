import '../../core/utils/app_logger.dart';
import '../../core/utils/id.dart';
import '../../domain/entities/budget.dart';
import '../../domain/repositories/budget_repository.dart';
import '../datasources/budget_remote_datasource.dart';
import '../datasources/local_storage_datasource.dart';

class BudgetRepositoryImpl implements BudgetRepository {
  BudgetRepositoryImpl(
    this._remote,
    this._local, {
    this.onRemoteSuccess,
    this.onRemoteFailure,
  });

  final BudgetRemoteDataSource _remote;
  final LocalStorageDataSource _local;

  /// Notifica o controller de conectividade que uma op remota foi OK.
  final void Function()? onRemoteSuccess;

  /// Notifica que uma op remota falhou — dispara recheck de saúde do BD.
  final void Function()? onRemoteFailure;

  final _log = AppLogger('BudgetRepo');

  @override
  Future<List<Budget>> getAll() async {
    final cached = _local.getBudgets();
    try {
      final remote = await _remote.getAll();
      await _local.saveBudgets(remote);
      onRemoteSuccess?.call();
      return remote;
    } catch (e) {
      _log.warn('getAll remoto falhou — devolvendo cache', e);
      onRemoteFailure?.call();
      return cached;
    }
  }

  @override
  Future<Budget> create(Budget budget) async {
    final ensured = budget.id.isEmpty
        ? budget.copyWith(id: generateId(), createdAt: DateTime.now())
        : budget;

    final next = [ensured, ..._local.getBudgets()];
    await _local.saveBudgets(next);

    try {
      final saved = await _remote.create(ensured);
      final synced = next.map((b) => b.id == ensured.id ? saved : b).toList();
      await _local.saveBudgets(synced);
      onRemoteSuccess?.call();
      return saved;
    } catch (e) {
      _log.warn('create ${ensured.id} falhou — enfileirando', e);
      await _local.addSyncOp(SyncOp.budgetCreate(ensured));
      onRemoteFailure?.call();
      return ensured;
    }
  }

  @override
  Future<Budget> update(String id, BudgetUpdate updates) async {
    final cached = _local.getBudgets();
    final original = cached.firstWhere((b) => b.id == id);
    final updated = updates.apply(original);

    final next = cached.map((b) => b.id == id ? updated : b).toList();
    await _local.saveBudgets(next);

    try {
      final saved = await _remote.update(id, updates);
      final synced = next.map((b) => b.id == id ? saved : b).toList();
      await _local.saveBudgets(synced);
      onRemoteSuccess?.call();
      return saved;
    } catch (e) {
      _log.warn('update $id falhou — enfileirando', e);
      await _local.addSyncOp(SyncOp.budgetUpdate(id, updates));
      onRemoteFailure?.call();
      return updated;
    }
  }

  @override
  Future<void> delete(String id) async {
    final next = _local.getBudgets().where((b) => b.id != id).toList();
    await _local.saveBudgets(next);

    try {
      await _remote.delete(id);
      onRemoteSuccess?.call();
    } catch (e) {
      _log.warn('delete $id falhou — enfileirando', e);
      await _local.addSyncOp(SyncOp.budgetDelete(id));
      onRemoteFailure?.call();
    }
  }

  @override
  Future<void> refreshFromRemote() async {
    try {
      final remote = await _remote.getAll();
      await _local.saveBudgets(remote);
      onRemoteSuccess?.call();
    } catch (e) {
      _log.warn('refreshFromRemote falhou', e);
      onRemoteFailure?.call();
    }
  }
}
