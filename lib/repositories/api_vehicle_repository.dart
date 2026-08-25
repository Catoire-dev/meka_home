import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../core/network/api_guard.dart';
import '../core/network/result.dart';
import '../models/vehicle/vehicle.dart';
import '../services/api/vehicle_api_service.dart';
import 'vehicle_repository.dart';

final vehicleRepositoryProvider = Provider<VehicleRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ApiVehicleRepository(VehicleApiService(client), client);
});

/// Implémentation [VehicleRepository] pour le backend HTTP actuel.
/// Seule cette classe connaîtrait un futur backend de remplacement.
class ApiVehicleRepository implements VehicleRepository {
  ApiVehicleRepository(this._service, this._client);

  final VehicleApiService _service;
  final ApiClient _client;

  @override
  Future<Result<List<Vehicle>>> getVehicles() => apiGuard(_client, () async {
    final json = await _service.fetchVehicles();
    return json.map((e) => Vehicle.fromJson(e as Map<String, dynamic>)).toList();
  });

  @override
  Future<Result<Vehicle>> getVehicle(String id) => apiGuard(_client, () async {
    final json = await _service.fetchVehicle(id);
    return Vehicle.fromJson(json);
  });

  @override
  Future<Result<Vehicle>> createVehicle(Vehicle vehicle) =>
      apiGuard(_client, () async {
        final json = await _service.createVehicle(vehicle.toJson());
        return Vehicle.fromJson(json);
      });

  @override
  Future<Result<Vehicle>> updateVehicle(Vehicle vehicle) =>
      apiGuard(_client, () async {
        final json = await _service.updateVehicle(vehicle.id, vehicle.toJson());
        return Vehicle.fromJson(json);
      });

  @override
  Future<Result<void>> deleteVehicle(String id) =>
      apiGuard(_client, () => _service.deleteVehicle(id));

  @override
  Future<Result<Vehicle>> uploadPhoto({
    required String vehicleId,
    required List<int> bytes,
    required String filename,
  }) => apiGuard(_client, () async {
    final json = await _service.uploadPhoto(
      id: vehicleId,
      bytes: bytes,
      filename: filename,
    );
    return Vehicle.fromJson(json);
  });
}
