import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/result.dart';
import '../../models/vehicle/vehicle.dart';
import '../../repositories/api_vehicle_repository.dart';
import '../../repositories/vehicle_repository.dart';
import '../home/home_providers.dart';
import 'vehicles_providers.dart';

final vehicleActionsProvider = Provider<VehicleActions>(VehicleActions.new);

/// Opérations d'écriture sur les véhicules : délègue au repository puis
/// invalide les listes (écran Véhicules, accueil) et la fiche concernée.
class VehicleActions {
  VehicleActions(this._ref);

  final Ref _ref;

  VehicleRepository get _repository => _ref.read(vehicleRepositoryProvider);

  /// Crée ([Vehicle.id] vide) ou met à jour un véhicule.
  Future<Result<Vehicle>> save(Vehicle vehicle) async {
    final result = vehicle.id.isEmpty
        ? await _repository.createVehicle(vehicle)
        : await _repository.updateVehicle(vehicle);
    if (result is Success<Vehicle>) _invalidate(vehicle.id);
    return result;
  }

  /// Épingle (ou retire) le véhicule de l'accueil.
  Future<Result<Vehicle>> setFavorite(Vehicle vehicle, bool favorite) =>
      save(vehicle.copyWith(isFavorite: favorite));

  void _invalidate(String vehicleId) {
    // Les rappels de l'accueil dépendent de currentVehiclesProvider et sont
    // recalculés avec lui.
    _ref.invalidate(allVehiclesProvider);
    _ref.invalidate(currentVehiclesProvider);
    if (vehicleId.isNotEmpty) _ref.invalidate(vehicleByIdProvider(vehicleId));
  }
}
