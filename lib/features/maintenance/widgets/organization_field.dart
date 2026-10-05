import 'package:flutter/material.dart';

import '../../../models/organization/organization.dart';

/// Sélecteur obligatoire du garage / intervenant d'une intervention, avec
/// un raccourci pour en créer un nouveau sans quitter le formulaire.
class OrganizationField extends StatelessWidget {
  const OrganizationField({
    super.key,
    required this.organizations,
    required this.value,
    required this.onChanged,
    required this.onCreate,
  });

  final List<Organization> organizations;
  final String? value;
  final ValueChanged<String?> onChanged;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: DropdownButtonFormField<String>(
            // La clé force la reconstruction si la valeur change par
            // programme (garage créé depuis le formulaire).
            key: ValueKey(value),
            initialValue: value,
            decoration: InputDecoration(
              labelText: 'Garage / intervenant',
              helperText: organizations.isEmpty
                  ? 'Aucun garage pour ce véhicule : créez-en un'
                  : null,
            ),
            items: [
              for (final organization in organizations)
                DropdownMenuItem(
                  value: organization.id,
                  child: Text(organization.name),
                ),
            ],
            onChanged: onChanged,
            validator: (value) => value == null ? 'Requis' : null,
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: IconButton(
            tooltip: 'Nouveau garage',
            icon: const Icon(Icons.add_business_outlined),
            onPressed: onCreate,
          ),
        ),
      ],
    );
  }
}
