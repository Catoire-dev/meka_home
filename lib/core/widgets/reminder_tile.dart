import 'package:flutter/material.dart';

import '../../models/reminder/reminder.dart';
import '../utils/date_format.dart';

extension ReminderUrgencyDisplay on ReminderUrgency {
  String get label => switch (this) {
    ReminderUrgency.overdue => 'En retard',
    ReminderUrgency.dueSoon => 'Bientôt',
    ReminderUrgency.upcoming => 'À venir',
  };

  Color color(ColorScheme colorScheme) => switch (this) {
    ReminderUrgency.overdue => colorScheme.error,
    ReminderUrgency.dueSoon => colorScheme.tertiary,
    ReminderUrgency.upcoming => colorScheme.outline,
  };
}

/// Date et/ou kilométrage visés par une échéance, ex. `12/03/2027 · 45000 km`.
String reminderDueLabel(Reminder reminder) => [
  if (reminder.dueDate != null) formatDate(reminder.dueDate!),
  if (reminder.dueMileage != null) '${reminder.dueMileage} km',
].join(' · ');

/// Ligne représentant une échéance d'entretien, avec son niveau d'urgence
/// et la date/le kilométrage visés. [vehicleName] préfixe le sous-titre
/// lorsque la liste mélange plusieurs véhicules.
class ReminderTile extends StatelessWidget {
  const ReminderTile({
    super.key,
    required this.reminder,
    this.vehicleName,
    this.onTap,
    this.trailing,
  });

  final Reminder reminder;
  final String? vehicleName;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final subtitle = [
      ?vehicleName,
      reminderDueLabel(reminder),
    ].where((part) => part.isNotEmpty).join(' · ');

    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Tooltip(
        message: reminder.urgency.label,
        child: CircleAvatar(
          radius: 6,
          backgroundColor: reminder.urgency.color(colorScheme),
        ),
      ),
      title: Text(reminder.type.label),
      subtitle: Text(subtitle),
      trailing: trailing,
    );
  }
}
