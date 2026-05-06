import 'package:flutter/material.dart';

import '../../domain/entities/service_item.dart';

/// Returns the icon used to represent a given service category across
/// catalog and budget-creation surfaces.
IconData iconForCategory(ServiceCategory c) => switch (c) {
      ServiceCategory.exterior => Icons.water_drop_outlined,
      ServiceCategory.interior => Icons.chair_outlined,
      ServiceCategory.protection => Icons.shield_outlined,
      ServiceCategory.detailing => Icons.auto_fix_high,
    };
