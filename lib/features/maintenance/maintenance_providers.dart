import '../../core/network/result.dart';
import '../../core/network/sticky_result_provider.dart';
import '../../models/maintenance/maintenance.dart';
import '../../models/maintenance/maintenance_schedule.dart';
import '../../models/maintenance/maintenance_type.dart';
import '../../models/reminder/reminder.dart';
import '../../models/vehicle/vehicle.dart';
import '../../repositories/api_maintenance_repository.dart';
import '../vehicles/vehicles_providers.dart';

/// Interventions réalisées sur le véhicule, les plus récentes en premier.
final vehicleMaintenancesProvider =
    stickyResultProviderFamily<List<Maintenance>, String>((
      ref,
      vehicleId,
    ) async {
      final result = await ref
          .watch(maintenanceRepositoryProvider)
          .getMaintenances(vehicleId);
      return switch (result) {
        Success(:final data) => Result.success(
          data.toList()..sort((a, b) => b.date.compareTo(a.date)),
        ),
        FailureResult(:final failure) => Result.failure(failure),
      };
    });

/// Échéances planifiées du véhicule, telles que renvoyées par le backend.
/// Source unique partagée par la fiche véhicule, l'accueil et les
/// formulaires : l'invalider suffit à rafraîchir tous les rappels.
final vehicleSchedulesProvider =
    stickyResultProviderFamily<List<MaintenanceSchedule>, String>(
      (ref, vehicleId) => ref
          .watch(maintenanceRepositoryProvider)
          .getMaintenanceSchedules(vehicleId),
    );

/// Types d'entretien indexés par identifiant.
Map<int, MaintenanceType> indexMaintenanceTypes(List<MaintenanceType> types) =>
    {for (final type in types) type.id: type};

/// Échéances d'entretien planifiées pour ce véhicule, triées par urgence.
final vehicleScheduleRemindersProvider =
    stickyResultProviderFamily<List<Reminder>, String>((ref, vehicleId) async {
      final vehicleResult = await ref.watch(
        vehicleByIdProvider(vehicleId).future,
      );
      if (vehicleResult is FailureResult<Vehicle>) {
        return Result.failure(vehicleResult.failure);
      }
      final vehicle = (vehicleResult as Success<Vehicle>).data;

      final typesResult = await ref.watch(maintenanceTypesProvider.future);
      if (typesResult is FailureResult<List<MaintenanceType>>) {
        return Result.failure(typesResult.failure);
      }
      final types = (typesResult as Success<List<MaintenanceType>>).data;

      final schedulesResult = await ref.watch(
        vehicleSchedulesProvider(vehicleId).future,
      );
      if (schedulesResult is FailureResult<List<MaintenanceSchedule>>) {
        return Result.failure(schedulesResult.failure);
      }

      return Result.success(
        Reminder.fromSchedules(
          schedules:
              (schedulesResult as Success<List<MaintenanceSchedule>>).data,
          typeById: indexMaintenanceTypes(types),
          currentMileage: vehicle.mileage,
        ),
      );
    });
