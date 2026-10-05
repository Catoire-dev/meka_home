import 'package:flutter/material.dart';

import '../../../models/maintenance/maintenance_type.dart';

/// Sélecteur obligatoire du type d'entretien, partagé par les formulaires
/// d'intervention et d'échéance.
class MaintenanceTypeField extends StatelessWidget {
  const MaintenanceTypeField({
    super.key,
    required this.types,
    required this.value,
    required this.onChanged,
  });

  final List<MaintenanceType> types;
  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      // La clé force la reconstruction si la valeur change par programme
      // (pré-remplissage), `initialValue` n'étant lu qu'à la création.
      key: ValueKey(value),
      initialValue: value,
      decoration: const InputDecoration(labelText: "Type d'entretien"),
      items: [
        for (final type in types)
          DropdownMenuItem(value: type.id, child: Text(type.label)),
      ],
      onChanged: onChanged,
      validator: (value) => value == null ? 'Requis' : null,
    );
  }
}
