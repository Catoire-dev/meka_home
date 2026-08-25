enum VehicleStatus { current, historical }

extension VehicleStatusLabel on VehicleStatus {
  String get label => switch (this) {
    VehicleStatus.current => 'En cours',
    VehicleStatus.historical => 'Historique',
  };
}
