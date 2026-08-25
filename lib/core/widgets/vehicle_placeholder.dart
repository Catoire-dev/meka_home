import 'package:flutter/material.dart';

import '../../models/vehicle/vehicle_category.dart';

/// Illustration affichée à la place de la photo d'un véhicule qui n'en a
/// pas, différente selon [VehicleCategory].
class VehiclePlaceholder extends StatelessWidget {
  const VehiclePlaceholder({super.key, required this.category});

  final VehicleCategory category;

  IconData get _icon => switch (category) {
    VehicleCategory.moto => Icons.two_wheeler,
    VehicleCategory.voiture => Icons.directions_car,
    VehicleCategory.autre => Icons.category_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: colorScheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(_icon, size: 40, color: colorScheme.onSurfaceVariant),
    );
  }
}
