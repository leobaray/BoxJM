import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/budget.dart';

class BudgetRemoteDataSource {
  BudgetRemoteDataSource(this._client);

  final SupabaseClient _client;
  static const _table = 'budgets';

  Future<List<Budget>> getAll() async {
    final rows = await _client
        .from(_table)
        .select()
        .order('created_at', ascending: false);
    return (rows as List)
        .map((r) => Budget.fromSupabase(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  Future<Budget> create(Budget budget) async {
    final row = await _client
        .from(_table)
        .insert(budget.toSupabaseInsert())
        .select()
        .single();
    return Budget.fromSupabase(row);
  }

  Future<Budget> update(String id, BudgetUpdate updates) async {
    final row = await _client
        .from(_table)
        .update(updates.toSupabase())
        .eq('id', id)
        .select()
        .single();
    return Budget.fromSupabase(row);
  }

  Future<void> delete(String id) async {
    await _client.from(_table).delete().eq('id', id);
  }
}
