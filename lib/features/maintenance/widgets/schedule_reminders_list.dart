import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/empty_hint.dart';
import '../../../core/widgets/reminder_tile.dart';
import '../../../models/reminder/reminder.dart';

/// Échéances d'un véhicule, les retards regroupés en tête. Toucher une
/// échéance l'ouvre en édition ; le bouton ✓ enregistre l'intervention
/// correspondante.
class ScheduleRemindersList extends StatelessWidget {
  const ScheduleRemindersList({
    super.key,
    required this.vehicleId,
    required this.reminders,
  });

  final String vehicleId;

  /// Rappels déjà triés par urgence.
  final List<Reminder> reminders;

  @override
  Widget build(BuildContext context) {
    if (reminders.isEmpty) {
      return const EmptyHint('Aucune échéance planifiée.');
    }

    final overdue = reminders
        .where((r) => r.urgency == ReminderUrgency.overdue)
        .toList();
    final upcoming = reminders
        .where((r) => r.urgency != ReminderUrgency.overdue)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (overdue.isNotEmpty) ...[
          _GroupLabel(
            ReminderUrgency.overdue.label,
            color: Theme.of(context).colorScheme.error,
          ),
          for (final reminder in overdue) _tile(context, reminder),
        ],
        if (upcoming.isNotEmpty) ...[
          if (overdue.isNotEmpty) const _GroupLabel('À venir'),
          for (final reminder in upcoming) _tile(context, reminder),
        ],
      ],
    );
  }

  Widget _tile(BuildContext context, Reminder reminder) => ReminderTile(
    reminder: reminder,
    onTap: () => context.push(
      '/vehicles/$vehicleId/schedules/${reminder.scheduleId}/edit',
    ),
    trailing: IconButton(
      tooltip: 'Marquer comme réalisé',
      icon: const Icon(Icons.check_circle_outline),
      onPressed: () => context.push(
        '/vehicles/$vehicleId/maintenances/new?scheduleId=${reminder.scheduleId}',
      ),
    ),
  );
}

class _GroupLabel extends StatelessWidget {
  const _GroupLabel(this.label, {this.color});

  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: color ?? theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
