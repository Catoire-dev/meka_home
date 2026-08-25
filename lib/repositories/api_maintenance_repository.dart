import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../core/network/api_guard.dart';
import '../core/network/result.dart';
import '../models/maintenance/maintenance.dart';
import '../models/maintenance/maintenance_schedule.dart';
import '../models/maintenance/maintenance_type.dart';
import '../services/api/maintenance_api_service.dart';
import 'maintenance_repository.dart';

final maintenanceRepositoryProvider = Provider<MaintenanceRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ApiMaintenanceRepository(MaintenanceApiService(client), client);
});

class ApiMaintenanceRepository implements MaintenanceRepository {
  ApiMaintenanceRepository(this._service, this._client);

  final MaintenanceApiService _service;
  final ApiClient _client;

  @override
  Future<Result<List<MaintenanceType>>> getMaintenanceTypes() =>
      apiGuard(_client, () async {
        final json = await _service.fetchMaintenanceTypes();
        return json
            .map((e) => MaintenanceType.fromJson(e as Map<String, dynamic>))
            .toList();
      });

  @override
  Future<Result<List<Maintenance>>> getMaintenances(String vehicleId) =>
      apiGuard(_client, () async {
        final json = await _service.fetchMaintenances(vehicleId);
        return json
            .map((e) => Maintenance.fromJson(e as Map<String, dynamic>))
            .toList();
      });

  @override
  Future<Result<Maintenance>> createMaintenance(Maintenance maintenance) =>
      apiGuard(_client, () async {
        final json = await _service.createMaintenance(
          maintenance.vehicleId,
          maintenance.toJson(),
        );
        return Maintenance.fromJson(json);
      });

  @override
  Future<Result<Maintenance>> updateMaintenance(Maintenance maintenance) =>
      apiGuard(_client, () async {
        final json = await _service.updateMaintenance(
          maintenance.id,
          maintenance.toJson(),
        );
        return Maintenance.fromJson(json);
      });

  @override
  Future<Result<void>> deleteMaintenance(String id) =>
      apiGuard(_client, () => _service.deleteMaintenance(id));

  @override
  Future<Result<List<MaintenanceSchedule>>> getMaintenanceSchedules(
    String vehicleId,
  ) => apiGuard(_client, () async {
    final json = await _service.fetchMaintenanceSchedules(vehicleId);
    return json
        .map((e) => MaintenanceSchedule.fromJson(e as Map<String, dynamic>))
        .toList();
  });

  @override
  Future<Result<MaintenanceSchedule>> createMaintenanceSchedule(
    MaintenanceSchedule schedule,
  ) => apiGuard(_client, () async {
    final json = await _service.createMaintenanceSchedule(
      schedule.vehicleId,
      schedule.toJson(),
    );
    return MaintenanceSchedule.fromJson(json);
  });

  @override
  Future<Result<MaintenanceSchedule>> updateMaintenanceSchedule(
    MaintenanceSchedule schedule,
  ) => apiGuard(_client, () async {
    final json = await _service.updateMaintenanceSchedule(
      schedule.id,
      schedule.toJson(),
    );
    return MaintenanceSchedule.fromJson(json);
  });

  @override
  Future<Result<void>> deleteMaintenanceSchedule(String id) =>
      apiGuard(_client, () => _service.deleteMaintenanceSchedule(id));
}
