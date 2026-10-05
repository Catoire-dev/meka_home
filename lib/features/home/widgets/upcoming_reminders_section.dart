import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/empty_hint.dart';
import '../../../core/widgets/reminder_tile.dart';
import '../../../models/reminder/reminder.dart';
import '../../../models/vehicle/vehicle.dart';

/// Bloc "prochaines échéances" : liste des rappels d'entretien triés par
/// urgence. [limit] restreint le nombre de lignes affichées (`null` affiche
/// tout) ; [onOpen] rend le bloc cliquable pour ouvrir la liste complète.
class UpcomingRemindersSection extends StatelessWidget {
  const UpcomingRemindersSection({
    super.key,
    required this.reminders,
    required this.vehiclesById,
    this.limit,
    this.onOpen,
  });

  final List<Reminder> reminders;
  final Map<String, Vehicle> vehiclesById;
  final int? limit;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shown = limit != null && reminders.length > limit!
        ? reminders.take(limit!).toList()
        : reminders;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Prochaines échéances',
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  if (onOpen != null) ...[
                    Text(
                      'Tout voir (${reminders.length})',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Icon(Icons.chevron_right, color: theme.colorScheme.primary),
                  ],
                ],
              ),
              const SizedBox(height: 8),
              if (shown.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: EmptyHint('Aucune échéance à venir.'),
                )
              else
                for (final reminder in shown)
                  if (vehiclesById[reminder.vehicleId] case final vehicle?)
                    ReminderTile(
                      reminder: reminder,
                      vehicleName: vehicle.customName,
                      onTap: () => context.push('/vehicles/${vehicle.id}'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
