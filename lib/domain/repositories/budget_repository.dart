import '../entities/budget.dart';

abstract class BudgetRepository {
  Future<List<Budget>> getAll();
  Future<Budget> create(Budget budget);
  Future<Budget> update(String id, BudgetUpdate updates);
  Future<void> delete(String id);
  Future<void> refreshFromRemote();
}
