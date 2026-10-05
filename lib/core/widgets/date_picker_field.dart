import 'package:flutter/material.dart';

import '../utils/date_format.dart';

/// Champ de formulaire de sélection de date : affiche la valeur courante,
/// ouvre un `showDatePicker` et, si [clearable], permet de l'effacer.
class DatePickerField extends StatelessWidget {
  const DatePickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.firstDate,
    required this.lastDate,
    this.clearable = true,
    this.emptyLabel = 'Non renseignée',
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final DateTime firstDate;
  final DateTime lastDate;
  final bool clearable;
  final String emptyLabel;

  Future<void> _pick(BuildContext context) async {
    var initial = value ?? DateTime.now();
    if (initial.isBefore(firstDate)) initial = firstDate;
    if (initial.isAfter(lastDate)) initial = lastDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    // Présenté comme les autres champs de saisie (et non comme une ligne
    // de liste) pour être identifiable comme un champ à remplir.
    return InkWell(
      onTap: () => _pick(context),
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        isEmpty: value == null,
        decoration: InputDecoration(
          labelText: label,
          hintText: emptyLabel,
          suffixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (clearable && value != null)
                IconButton(
                  tooltip: 'Effacer',
                  icon: const Icon(Icons.clear),
                  onPressed: () => onChanged(null),
                ),
              IconButton(
                tooltip: 'Choisir une date',
                icon: const Icon(Icons.calendar_today_outlined),
                onPressed: () => _pick(context),
              ),
            ],
          ),
        ),
        child: Text(value == null ? '' : formatDate(value!)),
      ),
    );
  }
}
