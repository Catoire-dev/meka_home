import 'package:flutter_test/flutter_test.dart';
import 'package:meka_home/core/utils/date_math.dart';
import 'package:meka_home/models/maintenance/schedule_interval_unit.dart';

void main() {
  test('addMonths ajoute des mois simples et change d\'année', () {
    expect(addMonths(DateTime(2026, 10, 5), 3), DateTime(2027, 1, 5));
    expect(addMonths(DateTime(2026, 1, 15), -2), DateTime(2025, 11, 15));
  });

  test('addMonths ramène au dernier jour du mois si besoin', () {
    expect(addMonths(DateTime(2026, 1, 31), 1), DateTime(2026, 2, 28));
    expect(addMonths(DateTime(2027, 12, 31), 2), DateTime(2028, 2, 29));
  });

  test('ScheduleIntervalUnit.addTo gère mois et années', () {
    final ref = DateTime(2026, 10, 5);
    expect(ScheduleIntervalUnit.months.addTo(ref, 6), DateTime(2027, 4, 5));
    expect(ScheduleIntervalUnit.years.addTo(ref, 2), DateTime(2028, 10, 5));
  });
}
