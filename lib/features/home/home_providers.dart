import '../../core/network/result.dart';
import '../../core/network/sticky_result_provider.dart';
import '../../models/maintenance/maintenance_type.dart';
import '../../models/reminder/reminder.dart';
import '../../models/vehicle/vehicle.dart';
import '../../repositories/api_maintenance_repository.dart';
import '../../repositories/api_vehicle_repository.dart';
import '../maintenance/maintenance_providers.dart';

/// Véhicules actuellement en service, triés par nom personnalisé.
final currentVehiclesProvider = stickyResultProvider<List<Vehicle>>((
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

/// Prochaines échéances d'entretien, toutes véhicules actuels confondus,
/// triées par urgence puis par proximité de la date/du kilométrage.
final upcomingRemindersProvider = stickyResultProvider<List<Reminder>>((
  ref,
) async {
  final vehiclesResult = await ref.watch(currentVehiclesProvider.future);
  if (vehiclesResult is FailureResult<List<Vehicle>>) {
    return Result.failure(vehiclesResult.failure);
  }
  final vehicles = (vehiclesResult as Success<List<Vehicle>>).data;

  final typesResult = await ref.watch(maintenanceTypesProvider.future);
  if (typesResult is FailureResult<List<MaintenanceType>>) {
    return Result.failure(typesResult.failure);
  }
  final typeById = indexMaintenanceTypes(
    (typesResult as Success<List<MaintenanceType>>).data,
  );

  final schedulesResults = await Future.wait([
    for (final vehicle in vehicles)
      ref.watch(vehicleSchedulesProvider(vehicle.id).future),
  ]);

  final reminders = <Reminder>[];
  for (final (index, schedulesResult) in schedulesResults.indexed) {
    switch (schedulesResult) {
      case FailureResult(:final failure):
        return Result.failure(failure);
      case Success(:final data):
        reminders.addAll(
          Reminder.fromSchedules(
            schedules: data,
            typeById: typeById,
            currentMileage: vehicles[index].mileage,
          ),
        );
    }
  }

  reminders.sort(Reminder.compareByUrgency);
  return Result.success(reminders);
});
