import 'package:flutter_test/flutter_test.dart';
import 'package:meka_home/models/maintenance/maintenance_type.dart';

void main() {
  test('is_custom accepte un TINYINT MySQL (0/1) comme un booléen', () {
    MaintenanceType parse(dynamic isCustom) => MaintenanceType.fromJson({
      'id': 1,
      'code': 'vidange',
      'label': 'Vidange',
      'icon': null,
      'is_custom': isCustom,
    });

    expect(parse(0).isCustom, isFalse);
    expect(parse(1).isCustom, isTrue);
    expect(parse('1').isCustom, isTrue);
    expect(parse(true).isCustom, isTrue);
    expect(parse(null).isCustom, isFalse);
  });
}
