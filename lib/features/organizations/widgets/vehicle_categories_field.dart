import 'package:flutter/material.dart';

import '../../../models/vehicle/vehicle_category.dart';

/// Cases à cocher, en ligne, des catégories de véhicules prises en charge
/// par un garage. Au moins une case est requise si [required].
class VehicleCategoriesField extends StatelessWidget {
  const VehicleCategoriesField({
    super.key,
    required this.title,
    required this.categories,
    required this.value,
    required this.onChanged,
    this.required = true,
  });

  final String title;
  final List<VehicleCategory> categories;
  final Set<VehicleCategory> value;
  final ValueChanged<Set<VehicleCategory>> onChanged;
  final bool required;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FormField<Set<VehicleCategory>>(
      initialValue: value,
      validator: (value) => required && (value?.isEmpty ?? true)
          ? 'Cochez au moins une catégorie'
          : null,
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          Wrap(
            spacing: 16,
            children: [
              for (final category in categories)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Checkbox(
                      value: value.contains(category),
                      onChanged: (checked) {
                        final next = checked == true
                            ? {...value, category}
                            : value.difference({category});
                        field.didChange(next);
                        onChanged(next);
                      },
                    ),
                    Text(category.name),
                  ],
                ),
            ],
          ),
          if (field.errorText != null)
            Text(
              field.errorText!,
              style: TextStyle(color: theme.colorScheme.error),
            ),
        ],
      ),
    );
  }
}
