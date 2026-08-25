import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/result.dart';
import '../../models/document/document.dart';
import '../../models/maintenance/maintenance.dart';
import '../../models/maintenance/maintenance_schedule.dart';
import '../../models/maintenance/maintenance_type.dart';
import '../../models/reminder/reminder.dart';
import '../../models/vehicle/vehicle.dart';
import '../../repositories/api_document_repository.dart';
import '../../repositories/api_maintenance_repository.dart';
import 'vehicles_providers.dart';

/// Interventions réalisées sur le véhicule, les plus récentes en premier.
final vehicleMaintenancesProvider =
    FutureProvider.family<Result<List<Maintenance>>, String>((
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

/// Échéances d'entretien planifiées pour ce véhicule, triées par urgence.
final vehicleScheduleRemindersProvider =
    FutureProvider.family<Result<List<Reminder>>, String>((
      ref,
      vehicleId,
    ) async {
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
      final typeById = {
        for (final type in (typesResult as Success<List<MaintenanceType>>).data)
          type.id: type,
      };

      final schedulesResult = await ref
          .watch(maintenanceRepositoryProvider)
          .getMaintenanceSchedules(vehicleId);
      if (schedulesResult is FailureResult<List<MaintenanceSchedule>>) {
        return Result.failure(schedulesResult.failure);
      }

      final reminders = <Reminder>[
        for (final schedule
            in (schedulesResult as Success<List<MaintenanceSchedule>>).data)
          if (typeById[schedule.maintenanceTypeId] case final type?)
            Reminder.fromSchedule(
              schedule: schedule,
              type: type,
              currentMileage: vehicle.mileage,
            ),
      ]..sort(Reminder.compareByUrgency);

      return Result.success(reminders);
    });

final vehicleDocumentsProvider =
    FutureProvider.family<Result<List<Document>>, String>(
      (ref, vehicleId) =>
          ref.watch(documentRepositoryProvider).getDocuments(vehicleId),
    );
