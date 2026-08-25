import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../core/network/result.dart';
import '../../models/vehicle/vehicle.dart';
import '../../models/vehicle/vehicle_category.dart';
import '../../models/vehicle/vehicle_status.dart';
import '../../repositories/api_vehicle_repository.dart';

enum VehicleSortOption { name, brand, mileage }

extension VehicleSortOptionLabel on VehicleSortOption {
  String get label => switch (this) {
    VehicleSortOption.name => 'Nom',
    VehicleSortOption.brand => 'Marque',
    VehicleSortOption.mileage => 'Kilométrage',
  };
}

final allVehiclesProvider = FutureProvider<Result<List<Vehicle>>>((ref) {
  final repo = ref.watch(vehicleRepositoryProvider);
  return repo.getVehicles();
});

final vehicleByIdProvider = FutureProvider.family<Result<Vehicle>, String>(
  (ref, id) => ref.watch(vehicleRepositoryProvider).getVehicle(id),
);

final vehicleCategoryFilterProvider = StateProvider<VehicleCategory>(
  (ref) => VehicleCategory.moto,
);

final vehicleStatusFilterProvider = StateProvider<VehicleStatus>(
  (ref) => VehicleStatus.current,
);

final vehicleSearchQueryProvider = StateProvider<String>((ref) => '');

final vehicleSortOptionProvider = StateProvider<VehicleSortOption>(
  (ref) => VehicleSortOption.name,
);

Comparator<Vehicle> _comparatorFor(VehicleSortOption sort) => switch (sort) {
  VehicleSortOption.name => (a, b) => a.customName.compareTo(b.customName),
  VehicleSortOption.brand => (a, b) => a.brand.compareTo(b.brand),
  VehicleSortOption.mileage => (a, b) => b.mileage.compareTo(a.mileage),
};

List<Vehicle> _applyFilters(
  List<Vehicle> vehicles, {
  required VehicleCategory category,
  required VehicleStatus status,
  required String query,
  required VehicleSortOption sort,
}) {
  final normalizedQuery = query.trim().toLowerCase();

  final filtered = vehicles.where((vehicle) {
    if (vehicle.category != category || vehicle.status != status) {
      return false;
    }
    if (normalizedQuery.isEmpty) return true;
    return vehicle.customName.toLowerCase().contains(normalizedQuery) ||
        vehicle.brand.toLowerCase().contains(normalizedQuery) ||
        vehicle.model.toLowerCase().contains(normalizedQuery) ||
        (vehicle.licensePlate?.toLowerCase().contains(normalizedQuery) ??
            false);
  }).toList();

  filtered.sort(_comparatorFor(sort));
  return filtered;
}

/// Véhicules filtrés (catégorie, statut, recherche texte) et triés selon
/// les critères sélectionnés sur l'écran Véhicules.
final filteredVehiclesProvider = Provider<AsyncValue<Result<List<Vehicle>>>>((
  ref,
) {
  final vehiclesAsync = ref.watch(allVehiclesProvider);
  final category = ref.watch(vehicleCategoryFilterProvider);
  final status = ref.watch(vehicleStatusFilterProvider);
  final query = ref.watch(vehicleSearchQueryProvider);
  final sort = ref.watch(vehicleSortOptionProvider);

  return vehiclesAsync.whenData(
    (result) => switch (result) {
      FailureResult(:final failure) => Result.failure(failure),
      Success(:final data) => Result.success(
        _applyFilters(
          data,
          category: category,
          status: status,
          query: query,
          sort: sort,
        ),
      ),
    },
  );
});
