import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/result.dart';
import '../../core/widgets/async_result_view.dart';
import '../../core/widgets/empty_hint.dart';
import '../../core/widgets/reminder_tile.dart';
import 'home_providers.dart';

/// Liste complète (sans limite) des échéances des véhicules favoris,
/// ouverte depuis le bloc « Prochaines échéances » de l'accueil.
class UpcomingRemindersScreen extends ConsumerWidget {
  const UpcomingRemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(favoriteRemindersProvider);
    final vehiclesById = switch (ref.watch(favoriteVehiclesProvider).value) {
      Success(:final data) => {for (final v in data) v.id: v},
      _ => const {},
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Prochaines échéances')),
      body: AsyncResultView(
        value: remindersAsync,
        builder: (reminders) => reminders.isEmpty
            ? const Center(child: EmptyHint('Aucune échéance à venir.'))
            : ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                children: [
                  for (final reminder in reminders)
                    if (vehiclesById[reminder.vehicleId] case final vehicle?)
                      ReminderTile(
                        reminder: reminder,
                        vehicleName: vehicle.customName,
                        onTap: () => context.push('/vehicles/${vehicle.id}'),
                      ),
                ],
              ),
      ),
    );
  }
}
