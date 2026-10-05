import 'package:flutter_test/flutter_test.dart';
import 'package:meka_home/core/utils/date_math.dart';
import 'package:meka_home/models/maintenance/maintenance.dart';
import 'package:meka_home/models/maintenance/maintenance_schedule.dart';
import 'package:meka_home/models/maintenance/schedule_interval.dart';

void main() {
  Maintenance maintenance(String id, DateTime date, int? mileage) =>
      Maintenance(
        id: id,
        vehicleId: 'v1',
        maintenanceTypeId: 1,
        date: date,
        organizationId: 'o1',
        mileage: mileage,
      );

  MaintenanceSchedule schedule({String? lastMaintenanceId}) =>
      MaintenanceSchedule(
        id: 's1',
        vehicleId: 'v1',
        maintenanceTypeId: 1,
        dueDate: DateTime(2027, 3, 10),
        dueMileage: 48000,
        lastMaintenanceId: lastMaintenanceId,
      );

  test('monthsBetween arrondit au mois le plus proche', () {
    expect(monthsBetween(DateTime(2026, 3, 10), DateTime(2027, 3, 10)), 12);
    expect(monthsBetween(DateTime(2026, 1, 31), DateTime(2026, 2, 28)), 1);
    expect(monthsBetween(DateTime(2026, 3, 10), DateTime(2026, 6, 1)), 3);
  });

  test("reprend l'intervalle depuis l'intervention liée", () {
    final interval =
        ScheduleInterval.ofSchedule(schedule(lastMaintenanceId: 'm1'), [
          maintenance('m1', DateTime(2026, 3, 10), 42000),
          maintenance('m2', DateTime(2026, 9, 1), 45000),
        ]);
    expect(interval.mileage, 6000);
    expect(interval.months, 12);
  });

  test("à défaut, part de la dernière intervention du même type", () {
    final interval = ScheduleInterval.ofSchedule(schedule(), [
      maintenance('m1', DateTime(2025, 3, 10), 36000),
      maintenance('m2', DateTime(2026, 9, 10), 45000),
    ]);
    expect(interval.mileage, 3000);
    expect(interval.months, 6);
  });

  test('vide sans intervention de référence', () {
    expect(ScheduleInterval.ofSchedule(schedule(), const []).isEmpty, isTrue);
  });
}
