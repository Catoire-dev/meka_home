import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/breakpoints.dart';
import '../../core/errors/failure.dart';
import '../../core/network/result.dart';
import '../../models/reminder/reminder.dart';
import '../../models/vehicle/vehicle.dart';
import '../../core/widgets/error_retry_view.dart';
import '../../core/widgets/vehicle_summary_card.dart';
import '../../repositories/api_maintenance_repository.dart';
import '../maintenance/maintenance_providers.dart';
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
    final vehiclesAsync = ref.watch(currentVehiclesProvider);
    final remindersAsync = ref.watch(upcomingRemindersProvider);

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
    final reminders = _reminders;
    final vehiclesById = {for (final v in vehicles) v.id: v};
    final firstReminderByVehicle = <String, Reminder>{};
    for (final reminder in reminders) {
      firstReminderByVehicle.putIfAbsent(reminder.vehicleId, () => reminder);
    }

    final vehicleCards = [
      for (final vehicle in vehicles)
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: VehicleSummaryCard(
            vehicle: vehicle,
            nextReminder: firstReminderByVehicle[vehicle.id],
            onTap: () => context.push('/vehicles/${vehicle.id}'),
          ),
        ),
    ];

    final remindersSection = UpcomingRemindersSection(
      reminders: reminders,
      vehiclesById: vehiclesById,
      limit: AppBreakpoints.usesSideNavigation(MediaQuery.sizeOf(context).width)
          ? null
          : 3,
    );

    final width = MediaQuery.sizeOf(context).width;
    final isExpanded =
        AppBreakpoints.classify(width) == AppWindowClass.expanded;

    if (isExpanded) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: vehicleCards.isEmpty
                  ? const _EmptyVehicles()
                  : Column(children: vehicleCards),
            ),
          ),
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(0, 16, 16, 16),
              child: remindersSection,
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (vehicleCards.isEmpty) const _EmptyVehicles() else ...vehicleCards,
        const SizedBox(height: 4),
        remindersSection,
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
          'Aucun véhicule en cours pour le moment.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
