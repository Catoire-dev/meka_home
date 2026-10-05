import 'package:flutter/material.dart';

import '../../models/vehicle/vehicle_category.dart';
import 'vehicle_category_icon.dart';

/// Illustration affichée à la place de la photo d'un véhicule qui n'en a
/// pas, différente selon la catégorie du véhicule.
class VehiclePlaceholder extends StatelessWidget {
  const VehiclePlaceholder({super.key, required this.category});

  final VehicleCategory category;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(
        vehicleCategoryIcon(category),
        size: 40,
        color: colorScheme.onSurfaceVariant,
      ),
    );
  }
}
