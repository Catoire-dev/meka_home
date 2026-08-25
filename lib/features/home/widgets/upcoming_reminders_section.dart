import 'package:flutter/material.dart';

import '../../../models/reminder/reminder.dart';
import '../../../models/vehicle/vehicle.dart';
import 'reminder_tile.dart';

/// Bloc "prochaines échéances" : liste des rappels d'entretien triés par
/// urgence, tous véhicules actuels confondus. [limit] restreint le nombre
/// de lignes affichées (aperçu mobile) ; `null` affiche tout.
class UpcomingRemindersSection extends StatelessWidget {
  const UpcomingRemindersSection({
    super.key,
    required this.reminders,
    required this.vehiclesById,
    this.limit,
  });

  final List<Reminder> reminders;
  final Map<String, Vehicle> vehiclesById;
  final int? limit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shown = limit != null && reminders.length > limit!
        ? reminders.take(limit!).toList()
        : reminders;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Prochaines échéances', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (shown.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Aucune échéance à venir.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              for (final reminder in shown)
                if (vehiclesById[reminder.vehicleId] case final vehicle?)
                  ReminderTile(reminder: reminder, vehicle: vehicle),
          ],
        ),
      ),
    );
  }
}
