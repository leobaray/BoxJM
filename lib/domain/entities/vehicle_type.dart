enum VehicleType {
  small,
  medium,
  large,
  suv,
  truck;

  static VehicleType fromString(String? value) {
    return VehicleType.values.firstWhere(
      (v) => v.name == value,
      orElse: () => VehicleType.medium,
    );
  }

  String get label => switch (this) {
        VehicleType.small => 'Pequeno',
        VehicleType.medium => 'Médio',
        VehicleType.large => 'Grande',
        VehicleType.suv => 'SUV',
        VehicleType.truck => 'Caminhonete',
      };
}
