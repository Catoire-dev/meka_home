import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/failure.dart';
import '../../core/network/result.dart';
import '../../models/reminder/reminder.dart';
import '../../models/vehicle/vehicle.dart';
import '../../core/widgets/error_retry_view.dart';
import '../../core/widgets/vehicle_summary_card.dart';
import '../../repositories/api_maintenance_repository.dart';
import '../maintenance/maintenance_providers.dart';
import '../vehicles/widgets/vehicle_favorite_button.dart';
import 'home_providers.dart';
import 'widgets/upcoming_reminders_section.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _refresh(WidgetRef ref) {
    ref.invalidate(maintenanceTypesProvider);
    ref.invalidate(currentVehiclesProvider);
    ref.invalidate(vehicleSchedulesProvider);
    ref.invalidate(upcomingRemindersProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(favoriteVehiclesProvider);
    final remindersAsync = ref.watch(favoriteRemindersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accueil'),
        actions: [
          IconButton(
            tooltip: 'Recharger',
            icon: const Icon(Icons.refresh),
            onPressed: () => _refresh(ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          _refresh(ref);
          await ref.read(upcomingRemindersProvider.future);
        },
        child: vehiclesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => ErrorRetryView(
            failure: UnknownFailure('$error'),
            onRetry: () => _refresh(ref),
          ),
          data: (vehiclesResult) => switch (vehiclesResult) {
            FailureResult(:final failure) => ErrorRetryView(
              failure: failure,
              onRetry: () => _refresh(ref),
            ),
            Success(:final data) => _HomeBody(
              vehicles: data,
              remindersAsync: remindersAsync,
            ),
          },
        ),
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.vehicles, required this.remindersAsync});

  final List<Vehicle> vehicles;
  final AsyncValue<Result<List<Reminder>>> remindersAsync;

  List<Reminder> get _reminders => switch (remindersAsync) {
    AsyncData(:final value) => switch (value) {
      Success(:final data) => data,
      FailureResult() => const <Reminder>[],
    },
    _ => const <Reminder>[],
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reminders = _reminders;
    final vehiclesById = {for (final v in vehicles) v.id: v};
    final firstReminderByVehicle = <String, Reminder>{};
    for (final reminder in reminders) {
      firstReminderByVehicle.putIfAbsent(reminder.vehicleId, () => reminder);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        UpcomingRemindersSection(
          reminders: reminders,
          vehiclesById: vehiclesById,
          limit: 3,
          onOpen: () => context.push('/reminders'),
        ),
        const SizedBox(height: 16),
        Text('Véhicules favoris', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (vehicles.isEmpty)
          const _EmptyVehicles()
        else
          for (final vehicle in vehicles)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: VehicleSummaryCard(
                vehicle: vehicle,
                nextReminder: firstReminderByVehicle[vehicle.id],
                onTap: () => context.push('/vehicles/${vehicle.id}'),
                trailing: VehicleFavoriteButton(vehicle: vehicle),
              ),
            ),
      ],
    );
  }
}

class _EmptyVehicles extends StatelessWidget {
  const _EmptyVehicles();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Aucun véhicule favori. Ajoutez-en depuis l\'écran Véhicules '
          'avec l\'icône cœur.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
