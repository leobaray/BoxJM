import '../../domain/entities/budget.dart';
import '../../domain/entities/vehicle_type.dart';
import '../constants/catalog.dart';
import 'currency.dart';

class BudgetTotals {
  final double subtotal;
  final double multiplier;
  final double total;

  const BudgetTotals({
    required this.subtotal,
    required this.multiplier,
    required this.total,
  });
}

BudgetTotals calculateTotals(List<BudgetItem> items, VehicleType type) {
  final subtotal = items.fold<double>(
    0,
    (sum, item) => sum + (item.basePrice * item.quantity),
  );
  final mult = multiplierFor(type);
  return BudgetTotals(
    subtotal: Currency.round2(subtotal),
    multiplier: mult,
    total: Currency.round2(subtotal * mult),
  );
}
