import 'package:flutter/material.dart';

import '../../models/vehicle/vehicle_category.dart';

/// Icône d'une catégorie de véhicule. Les catégories étant gérées côté
/// backend, l'icône est déduite de leur nom ; icône générique à défaut.
IconData vehicleCategoryIcon(VehicleCategory? category) {
  final name = category?.name.toLowerCase() ?? '';
  if (name.contains('moto') || name.contains('scooter')) {
    return Icons.two_wheeler;
  }
  if (name.contains('voiture') || name.contains('auto')) {
    return Icons.directions_car;
  }
  return Icons.category_outlined;
}
