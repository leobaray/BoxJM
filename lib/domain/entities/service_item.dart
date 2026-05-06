enum ServiceCategory {
  exterior,
  interior,
  protection,
  detailing;

  static ServiceCategory fromString(String? value) {
    return ServiceCategory.values.firstWhere(
      (c) => c.name == value,
      orElse: () => ServiceCategory.exterior,
    );
  }
}

class ServiceItem {
  final String id;
  final String name;
  final double basePrice;
  final ServiceCategory category;
  final String? description;

  const ServiceItem({
    required this.id,
    required this.name,
    required this.basePrice,
    required this.category,
    this.description,
  });

  ServiceItem copyWith({
    String? id,
    String? name,
    double? basePrice,
    ServiceCategory? category,
    String? description,
  }) {
    return ServiceItem(
      id: id ?? this.id,
      name: name ?? this.name,
      basePrice: basePrice ?? this.basePrice,
      category: category ?? this.category,
      description: description ?? this.description,
    );
  }

  factory ServiceItem.fromJson(Map<String, dynamic> json) => ServiceItem(
        id: json['id'] as String,
        name: json['name'] as String,
        basePrice: (json['basePrice'] as num).toDouble(),
        category: ServiceCategory.fromString(json['category'] as String?),
        description: json['description'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'basePrice': basePrice,
        'category': category.name,
        'description': description,
      };

  factory ServiceItem.fromSupabase(Map<String, dynamic> row) => ServiceItem(
        id: row['id'] as String,
        name: row['name'] as String,
        basePrice: (row['base_price'] as num?)?.toDouble() ?? 0,
        category: ServiceCategory.fromString(row['category'] as String?),
        description: row['description'] as String?,
      );

  Map<String, dynamic> toSupabase() => {
        'id': id,
        'name': name,
        'base_price': basePrice,
        'category': category.name,
        'description': description,
      };
}
