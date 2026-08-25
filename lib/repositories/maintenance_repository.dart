import '../core/network/result.dart';
import '../models/maintenance/maintenance.dart';
import '../models/maintenance/maintenance_schedule.dart';
import '../models/maintenance/maintenance_type.dart';

/// Contrat d'accès aux types d'entretien, aux interventions réalisées et
/// aux échéances planifiées, indépendant du backend qui l'implémente.
abstract interface class MaintenanceRepository {
  Future<Result<List<MaintenanceType>>> getMaintenanceTypes();

  Future<Result<List<Maintenance>>> getMaintenances(String vehicleId);
  Future<Result<Maintenance>> createMaintenance(Maintenance maintenance);
  Future<Result<Maintenance>> updateMaintenance(Maintenance maintenance);
  Future<Result<void>> deleteMaintenance(String id);

  Future<Result<List<MaintenanceSchedule>>> getMaintenanceSchedules(
    String vehicleId,
  );
  Future<Result<MaintenanceSchedule>> createMaintenanceSchedule(
    MaintenanceSchedule schedule,
  );
  Future<Result<MaintenanceSchedule>> updateMaintenanceSchedule(
    MaintenanceSchedule schedule,
  );
  Future<Result<void>> deleteMaintenanceSchedule(String id);
}
