import '../../core/utils/app_logger.dart';
import '../../domain/entities/service_item.dart';
import '../../domain/repositories/catalog_repository.dart';
import '../datasources/catalog_remote_datasource.dart';
import '../datasources/local_storage_datasource.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  CatalogRepositoryImpl(
    this._remote,
    this._local, {
    this.onRemoteSuccess,
    this.onRemoteFailure,
  });

  final CatalogRemoteDataSource _remote;
  final LocalStorageDataSource _local;

  final void Function()? onRemoteSuccess;
  final void Function()? onRemoteFailure;

  final _log = AppLogger('CatalogRepo');

  @override
  Future<List<ServiceItem>> getAll() async {
    try {
      final remote = await _remote.getAll();
      await _local.saveServices(remote);
      onRemoteSuccess?.call();
      return remote;
    } catch (e) {
      _log.warn('getAll remoto falhou — devolvendo cache', e);
      onRemoteFailure?.call();
      return _local.getServices();
    }
  }

  @override
  Future<void> save(ServiceItem service) async {
    final cached = _local.getServices();
    final idx = cached.indexWhere((s) => s.id == service.id);
    final next = idx >= 0
        ? cached.map((s) => s.id == service.id ? service : s).toList()
        : [...cached, service];
    await _local.saveServices(next);

    try {
      await _remote.upsert(service);
      onRemoteSuccess?.call();
    } catch (e) {
      _log.warn('save ${service.id} falhou — enfileirando', e);
      await _local.addSyncOp(SyncOp.serviceUpsert(service));
      onRemoteFailure?.call();
    }
  }

  @override
  Future<void> delete(String id) async {
    final next = _local.getServices().where((s) => s.id != id).toList();
    await _local.saveServices(next);

    try {
      await _remote.delete(id);
      onRemoteSuccess?.call();
    } catch (e) {
      _log.warn('delete $id falhou — enfileirando', e);
      await _local.addSyncOp(SyncOp.serviceDelete(id));
      onRemoteFailure?.call();
    }
  }

  @override
  Future<void> refreshFromRemote() async {
    try {
      final remote = await _remote.getAll();
      await _local.saveServices(remote);
      onRemoteSuccess?.call();
    } catch (e) {
      _log.warn('refreshFromRemote falhou', e);
      onRemoteFailure?.call();
    }
  }
}
