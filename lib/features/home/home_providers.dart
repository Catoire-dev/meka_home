import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/result.dart';
import '../../models/maintenance/maintenance_schedule.dart';
import '../../models/maintenance/maintenance_type.dart';
import '../../models/reminder/reminder.dart';
import '../../models/vehicle/vehicle.dart';
import '../../repositories/api_maintenance_repository.dart';
import '../../repositories/api_vehicle_repository.dart';

/// Véhicules actuellement en service, triés par nom personnalisé.
final currentVehiclesProvider = FutureProvider<Result<List<Vehicle>>>((
  ref,
) async {
  final repo = ref.watch(vehicleRepositoryProvider);
  final result = await repo.getVehicles();
  return switch (result) {
    Success(:final data) => Result.success(
      data.where((v) => v.isCurrent).toList()
        ..sort((a, b) => a.customName.compareTo(b.customName)),
    ),
    FailureResult(:final failure) => Result.failure(failure),
  };
});

int _urgencyRank(ReminderUrgency urgency) => switch (urgency) {
  ReminderUrgency.overdue => 0,
  ReminderUrgency.dueSoon => 1,
  ReminderUrgency.upcoming => 2,
};

int _compareReminders(Reminder a, Reminder b) {
  final urgencyCompare = _urgencyRank(a.urgency).compareTo(_urgencyRank(b.urgency));
  if (urgencyCompare != 0) return urgencyCompare;

  if (a.dueDate != null && b.dueDate != null) {
    return a.dueDate!.compareTo(b.dueDate!);
  }
  if (a.dueDate != null) return -1;
  if (b.dueDate != null) return 1;

  if (a.dueMileage != null && b.dueMileage != null) {
    return a.dueMileage!.compareTo(b.dueMileage!);
  }
  if (a.dueMileage != null) return -1;
  if (b.dueMileage != null) return 1;
  return 0;
}

/// Prochaines échéances d'entretien, toutes véhicules actuels confondus,
/// triées par urgence puis par proximité de la date/du kilométrage.
final upcomingRemindersProvider = FutureProvider<Result<List<Reminder>>>((
  ref,
) async {
  final vehiclesResult = await ref.watch(currentVehiclesProvider.future);
  if (vehiclesResult is FailureResult<List<Vehicle>>) {
    return Result.failure(vehiclesResult.failure);
  }
  final vehicles = (vehiclesResult as Success<List<Vehicle>>).data;

  final maintenanceRepo = ref.watch(maintenanceRepositoryProvider);

  final typesResult = await maintenanceRepo.getMaintenanceTypes();
  if (typesResult is FailureResult<List<MaintenanceType>>) {
    return Result.failure(typesResult.failure);
  }
  final typeById = {
    for (final type in (typesResult as Success<List<MaintenanceType>>).data)
      type.id: type,
  };

  final reminders = <Reminder>[];
  for (final vehicle in vehicles) {
    final schedulesResult = await maintenanceRepo.getMaintenanceSchedules(
      vehicle.id,
    );
    if (schedulesResult is! Success<List<MaintenanceSchedule>>) continue;

    for (final schedule in schedulesResult.data) {
      final type = typeById[schedule.maintenanceTypeId];
      if (type == null) continue;
      reminders.add(
        Reminder.fromSchedule(
          schedule: schedule,
          type: type,
          currentMileage: vehicle.mileage,
        ),
      );
    }
  }

  reminders.sort(_compareReminders);
  return Result.success(reminders);
});
