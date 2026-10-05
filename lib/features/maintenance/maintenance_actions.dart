import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/failure.dart';
import '../../core/network/result.dart';
import '../../models/maintenance/maintenance.dart';
import '../../models/maintenance/maintenance_schedule.dart';
import '../../models/vehicle/vehicle.dart';
import '../../repositories/api_maintenance_repository.dart';
import '../../repositories/api_vehicle_repository.dart';
import '../../repositories/maintenance_repository.dart';
import '../home/home_providers.dart';
import '../vehicles/vehicle_detail_providers.dart';
import '../vehicles/vehicles_providers.dart';
import 'maintenance_providers.dart';

final maintenanceActionsProvider = Provider<MaintenanceActions>(
  MaintenanceActions.new,
);

/// Issue de l'enregistrement d'une intervention : [maintenance] porte le
/// résultat principal ; [warnings] liste les mises à jour annexes
/// (échéance, kilométrage du véhicule) qui ont échoué alors que
/// l'intervention elle-même a bien été enregistrée.
typedef SaveMaintenanceOutcome = ({
  Result<Maintenance> maintenance,
  List<String> warnings,
});

/// Opérations d'écriture sur les entretiens : délègue au repository puis
/// invalide les providers concernés, pour que les écrans n'aient ni à
/// orchestrer les appels ni à connaître les dépendances entre données.
class MaintenanceActions {
  MaintenanceActions(this._ref);

  final Ref _ref;

  MaintenanceRepository get _repository =>
      _ref.read(maintenanceRepositoryProvider);

  /// Crée ([Maintenance.id] vide) ou met à jour une intervention. Si
  /// [nextSchedule] est fourni, l'échéance est ensuite créée ou mise à jour
  /// et rattachée à cette intervention via `lastMaintenanceId`. Si le
  /// kilométrage de l'intervention dépasse celui du véhicule, ce dernier
  /// est mis à jour.
  Future<SaveMaintenanceOutcome> saveMaintenance(
    Maintenance maintenance, {
    MaintenanceSchedule? nextSchedule,
  }) async {
    final result = maintenance.id.isEmpty
        ? await _repository.createMaintenance(maintenance)
        : await _repository.updateMaintenance(maintenance);

    final warnings = <String>[];
    if (result case Success(:final data)) {
      if (nextSchedule != null) {
        final scheduleResult = await _persistSchedule(
          nextSchedule.copyWith(lastMaintenanceId: data.id),
        );
        if (scheduleResult case FailureResult(:final failure)) {
          warnings.add(
            "L'échéance n'a pas pu être mise à jour : ${failure.message}",
          );
        }
        _invalidateSchedules(maintenance.vehicleId);
      }

      if (data.mileage case final mileage?) {
        if (await _syncVehicleMileage(data.vehicleId, mileage)
            case final failure?) {
          warnings.add(
            "Le kilométrage du véhicule n'a pas pu être mis à jour : "
            '${failure.message}',
          );
        }
      }

      _invalidateMaintenances(maintenance.vehicleId);
    }
    return (maintenance: result, warnings: warnings);
  }

  /// Reporte sur le véhicule un kilométrage d'intervention supérieur à son
  /// kilométrage actuel (jamais l'inverse). Renvoie l'échec éventuel.
  Future<Failure?> _syncVehicleMileage(String vehicleId, int mileage) async {
    final vehicleResult = await _ref.read(
      vehicleByIdProvider(vehicleId).future,
    );
    final Vehicle vehicle;
    switch (vehicleResult) {
      case FailureResult(:final failure):
        return failure;
      case Success(:final data):
        vehicle = data;
    }
    if (mileage <= vehicle.mileage) return null;

    final updateResult = await _ref
        .read(vehicleRepositoryProvider)
        .updateVehicle(vehicle.copyWith(mileage: mileage));
    switch (updateResult) {
      case FailureResult(:final failure):
        return failure;
      case Success():
        // Les rappels (fiche et accueil) dépendent de ces providers et sont
        // recalculés avec le nouveau kilométrage.
        _ref.invalidate(vehicleByIdProvider(vehicleId));
        _ref.invalidate(allVehiclesProvider);
        _ref.invalidate(currentVehiclesProvider);
        return null;
    }
  }

  Future<Result<void>> deleteMaintenance(Maintenance maintenance) async {
    final result = await _repository.deleteMaintenance(maintenance);
    if (result is Success<void>) {
      _invalidateMaintenances(maintenance.vehicleId);
      // Côté base, les échéances et documents liés perdent leur référence
      // à l'intervention supprimée (ON DELETE SET NULL).
      _invalidateSchedules(maintenance.vehicleId);
      _ref.invalidate(vehicleDocumentsProvider(maintenance.vehicleId));
    }
    return result;
  }

  /// Crée ([MaintenanceSchedule.id] vide) ou met à jour une échéance.
  Future<Result<MaintenanceSchedule>> saveSchedule(
    MaintenanceSchedule schedule,
  ) async {
    final result = await _persistSchedule(schedule);
    if (result is Success<MaintenanceSchedule>) {
      _invalidateSchedules(schedule.vehicleId);
    }
    return result;
  }

  Future<Result<void>> deleteSchedule(MaintenanceSchedule schedule) async {
    final result = await _repository.deleteMaintenanceSchedule(schedule);
    if (result is Success<void>) _invalidateSchedules(schedule.vehicleId);
    return result;
  }

  Future<Result<MaintenanceSchedule>> _persistSchedule(
    MaintenanceSchedule schedule,
  ) => schedule.id.isEmpty
      ? _repository.createMaintenanceSchedule(schedule)
      : _repository.updateMaintenanceSchedule(schedule);

  void _invalidateMaintenances(String vehicleId) {
    _ref.invalidate(vehicleMaintenancesProvider(vehicleId));
  }

  void _invalidateSchedules(String vehicleId) {
    // Les rappels (fiche véhicule et accueil) dérivent de ce provider.
    _ref.invalidate(vehicleSchedulesProvider(vehicleId));
  }
}
