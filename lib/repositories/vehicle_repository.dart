import '../core/network/result.dart';
import '../models/vehicle/vehicle.dart';

/// Contrat d'accès aux véhicules, indépendant du backend qui l'implémente.
abstract interface class VehicleRepository {
  Future<Result<List<Vehicle>>> getVehicles();
  Future<Result<Vehicle>> getVehicle(String id);
  Future<Result<Vehicle>> createVehicle(Vehicle vehicle);
  Future<Result<Vehicle>> updateVehicle(Vehicle vehicle);
  Future<Result<void>> deleteVehicle(String id);

  Future<Result<Vehicle>> uploadPhoto({
    required String vehicleId,
    required List<int> bytes,
    required String filename,
  });
}
