import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/widgets/async_result_view.dart';
import '../../../repositories/api_maintenance_repository.dart';
import '../maintenance_providers.dart';
import 'maintenance_history_list.dart';
import 'schedule_reminders_list.dart';

/// Section « Entretiens » de la fiche véhicule : échéances (en retard puis
/// à venir) et historique des interventions réalisées.
class VehicleMaintenanceSection extends ConsumerWidget {
  const VehicleMaintenanceSection({super.key, required this.vehicleId});

  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final remindersAsync = ref.watch(
      vehicleScheduleRemindersProvider(vehicleId),
    );
    final maintenancesAsync = ref.watch(vehicleMaintenancesProvider(vehicleId));
    final typesAsync = ref.watch(maintenanceTypesProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Entretiens', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            _SubsectionHeader(
              title: 'Échéances',
              actionLabel: 'Planifier',
              onAction: () =>
                  context.push('/vehicles/$vehicleId/schedules/new'),
            ),
            AsyncResultView(
              value: remindersAsync,
              builder: (reminders) => ScheduleRemindersList(
                vehicleId: vehicleId,
                reminders: reminders,
              ),
            ),
            const SizedBox(height: 16),
            _SubsectionHeader(
              title: 'Réalisés',
              actionLabel: 'Ajouter',
              onAction: () =>
                  context.push('/vehicles/$vehicleId/maintenances/new'),
            ),
            AsyncResultView(
              value: typesAsync,
              builder: (types) => AsyncResultView(
                value: maintenancesAsync,
                builder: (maintenances) => MaintenanceHistoryList(
                  maintenances: maintenances,
                  typeById: indexMaintenanceTypes(types),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubsectionHeader extends StatelessWidget {
  const _SubsectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onAction,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.labelLarge),
        ),
        TextButton.icon(
          onPressed: onAction,
          icon: const Icon(Icons.add, size: 18),
          label: Text(actionLabel),
        ),
      ],
    );
  }
}
