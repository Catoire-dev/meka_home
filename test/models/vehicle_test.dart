import 'package:flutter_test/flutter_test.dart';
import 'package:meka_home/models/vehicle/vehicle.dart';
import 'package:meka_home/models/vehicle/vehicle_category.dart';
import 'package:meka_home/models/vehicle/vehicle_status.dart';

void main() {
  test(
    'Vehicle.fromJson / toJson : snake_case, catégorie en objet puis en id',
    () {
      final json = {
        'id': 'v1',
        'custom_name': 'La Twingo',
        'vehicle_category_id': 2,
        'category': {'id': 2, 'name': 'Voiture', 'is_default': 0},
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
      expect(vehicle.category, const VehicleCategory(id: 2, name: 'Voiture'));
      expect(vehicle.category.isDefault, isFalse);
      expect(vehicle.status, VehicleStatus.current);
      expect(vehicle.powerHp, 65);
      expect(vehicle.weightKg, 850);
      expect(vehicle.isCurrent, isTrue);

      final out = vehicle.toJson();
      expect(out['vehicle_category_id'], 2);
      expect(out.containsKey('category'), isFalse);
      expect(out['custom_name'], 'La Twingo');
      expect(out['mileage'], 98000);
    },
  );
}
