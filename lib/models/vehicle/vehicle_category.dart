enum VehicleCategory { moto, voiture, autre }

extension VehicleCategoryLabel on VehicleCategory {
  String get label => switch (this) {
    VehicleCategory.moto => 'Moto',
    VehicleCategory.voiture => 'Voiture',
    VehicleCategory.autre => 'Autre',
  };
}
