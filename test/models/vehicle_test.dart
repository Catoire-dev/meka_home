import 'package:flutter_test/flutter_test.dart';
import 'package:meka_home/models/vehicle/vehicle.dart';
import 'package:meka_home/models/vehicle/vehicle_category.dart';
import 'package:meka_home/models/vehicle/vehicle_status.dart';

void main() {
  test('Vehicle.fromJson / toJson round-trip avec champs snake_case', () {
    final json = {
      'id': 'v1',
      'custom_name': 'La Twingo',
      'category': 'voiture',
      'status': 'current',
      'brand': 'Renault',
      'model': 'Twingo',
      'license_plate': 'AB-123-CD',
      'vin': null,
      'first_registration_date': '2015-03-12',
      'energy': 'essence',
      'fiscal_power': 4,
      'power_hp': 65,
      'weight_kg': 850,
      'color': 'rouge',
      'mileage': 98000,
      'comment': null,
      'photo_filename': null,
    };

    final vehicle = Vehicle.fromJson(json);

    expect(vehicle.customName, 'La Twingo');
    expect(vehicle.category, VehicleCategory.voiture);
    expect(vehicle.status, VehicleStatus.current);
    expect(vehicle.powerHp, 65);
    expect(vehicle.weightKg, 850);
    expect(vehicle.isCurrent, isTrue);

    final roundTripped = Vehicle.fromJson(vehicle.toJson());
    expect(roundTripped.id, vehicle.id);
    expect(roundTripped.mileage, vehicle.mileage);
  });
}
