enum VehicleEnergy { essence, diesel, electrique, hybride, gpl, autre }

extension VehicleEnergyLabel on VehicleEnergy {
  String get label => switch (this) {
    VehicleEnergy.essence => 'Essence',
    VehicleEnergy.diesel => 'Diesel',
    VehicleEnergy.electrique => 'Électrique',
    VehicleEnergy.hybride => 'Hybride',
    VehicleEnergy.gpl => 'GPL',
    VehicleEnergy.autre => 'Autre',
  };
}
