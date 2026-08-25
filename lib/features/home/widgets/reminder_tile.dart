import 'package:flutter/material.dart';

import '../../../models/reminder/reminder.dart';
import '../../../models/vehicle/vehicle.dart';

/// Ligne représentant une échéance d'entretien à venir, avec son niveau
/// d'urgence, le véhicule concerné et la date/le kilométrage visés.
class ReminderTile extends StatelessWidget {
  const ReminderTile({super.key, required this.reminder, required this.vehicle});

  final Reminder reminder;
  final Vehicle vehicle;

  Color _urgencyColor(ColorScheme colorScheme) => switch (reminder.urgency) {
    ReminderUrgency.overdue => colorScheme.error,
    ReminderUrgency.dueSoon => colorScheme.tertiary,
    ReminderUrgency.upcoming => colorScheme.outline,
  };

  String get _dueLabel {
    final parts = <String>[];
    final date = reminder.dueDate;
    if (date != null) {
      final d = date.day.toString().padLeft(2, '0');
      final m = date.month.toString().padLeft(2, '0');
      parts.add('$d/$m/${date.year}');
    }
    if (reminder.dueMileage != null) {
      parts.add('${reminder.dueMileage} km');
    }
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final urgencyColor = _urgencyColor(colorScheme);

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        radius: 6,
        backgroundColor: urgencyColor,
      ),
      title: Text(reminder.type.label),
      subtitle: Text('${vehicle.customName} · $_dueLabel'),
    );
  }
}
