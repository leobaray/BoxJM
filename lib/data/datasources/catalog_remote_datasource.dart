import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/service_item.dart';

class CatalogRemoteDataSource {
  CatalogRemoteDataSource(this._client);

  final SupabaseClient _client;
  static const _table = 'services';

  Future<List<ServiceItem>> getAll() async {
    final rows = await _client
        .from(_table)
        .select()
        .order('created_at', ascending: true);
    return (rows as List)
        .map((r) =>
            ServiceItem.fromSupabase(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  Future<ServiceItem> upsert(ServiceItem service) async {
    final row = await _client
        .from(_table)
        .upsert(service.toSupabase(), onConflict: 'id')
        .select()
        .single();
    return ServiceItem.fromSupabase(row);
  }

  Future<void> delete(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }
}
