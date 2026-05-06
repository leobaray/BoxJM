import '../entities/service_item.dart';

abstract class CatalogRepository {
  Future<List<ServiceItem>> getAll();
  Future<void> save(ServiceItem service);
  Future<void> delete(String id);
  Future<void> refreshFromRemote();
}
