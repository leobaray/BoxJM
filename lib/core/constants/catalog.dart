import '../../domain/entities/service_item.dart';
import '../../domain/entities/vehicle_type.dart';

class VehicleMultiplier {
  final VehicleType type;
  final String label;
  final double multiplier;
  final IconDataKey iconKey;

  const VehicleMultiplier({
    required this.type,
    required this.label,
    required this.multiplier,
    required this.iconKey,
  });
}

enum IconDataKey {
  carHatchback,
  carSedan,
  carEstate,
  carSide,
  truck,
}

const vehicleMultipliers = <VehicleMultiplier>[
  VehicleMultiplier(
    type: VehicleType.small,
    label: 'Pequeno',
    multiplier: 1.0,
    iconKey: IconDataKey.carHatchback,
  ),
  VehicleMultiplier(
    type: VehicleType.medium,
    label: 'Médio',
    multiplier: 1.2,
    iconKey: IconDataKey.carSedan,
  ),
  VehicleMultiplier(
    type: VehicleType.large,
    label: 'Grande',
    multiplier: 1.5,
    iconKey: IconDataKey.carEstate,
  ),
  VehicleMultiplier(
    type: VehicleType.suv,
    label: 'SUV',
    multiplier: 1.7,
    iconKey: IconDataKey.carSide,
  ),
  VehicleMultiplier(
    type: VehicleType.truck,
    label: 'Caminhonete',
    multiplier: 2.0,
    iconKey: IconDataKey.truck,
  ),
];

double multiplierFor(VehicleType type) =>
    vehicleMultipliers.firstWhere((v) => v.type == type).multiplier;

const categoryLabels = {
  ServiceCategory.exterior: 'Externo',
  ServiceCategory.interior: 'Interno',
  ServiceCategory.protection: 'Proteção',
  ServiceCategory.detailing: 'Detalhamento',
};
