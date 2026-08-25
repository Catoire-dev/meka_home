import '../../core/network/api_client.dart';

/// Accès HTTP brut aux endpoints d'entretien : types, interventions
/// réalisées, et échéances planifiées.
class MaintenanceApiService {
  MaintenanceApiService(this._client);

  final ApiClient _client;

  Future<List<dynamic>> fetchMaintenanceTypes() async {
    final response = await _client.dio.get('/maintenance-types');
    return response.data as List<dynamic>;
  }

  Future<List<dynamic>> fetchMaintenances(String vehicleId) async {
    final response = await _client.dio.get('/vehicles/$vehicleId/maintenances');
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createMaintenance(
    String vehicleId,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.dio.post(
      '/vehicles/$vehicleId/maintenances',
      data: body,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateMaintenance(
    String id,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.dio.put('/maintenances/$id', data: body);
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteMaintenance(String id) async {
    await _client.dio.delete('/maintenances/$id');
  }

  Future<List<dynamic>> fetchMaintenanceSchedules(String vehicleId) async {
    final response = await _client.dio.get(
      '/vehicles/$vehicleId/maintenance-schedules',
    );
    return response.data as List<dynamic>;
  }

  Future<Map<String, dynamic>> createMaintenanceSchedule(
    String vehicleId,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.dio.post(
      '/vehicles/$vehicleId/maintenance-schedules',
      data: body,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateMaintenanceSchedule(
    String id,
    Map<String, dynamic> body,
  ) async {
    final response = await _client.dio.put(
      '/maintenance-schedules/$id',
      data: body,
    );
    return response.data as Map<String, dynamic>;
  }

  Future<void> deleteMaintenanceSchedule(String id) async {
    await _client.dio.delete('/maintenance-schedules/$id');
  }
}
