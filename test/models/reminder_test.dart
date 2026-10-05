import 'package:flutter_test/flutter_test.dart';
import 'package:meka_home/models/maintenance/maintenance_schedule.dart';
import 'package:meka_home/models/maintenance/maintenance_type.dart';
import 'package:meka_home/models/reminder/reminder.dart';

void main() {
  const vidange = MaintenanceType(id: 1, code: 'vidange', label: 'Vidange');
  const pneus = MaintenanceType(id: 2, code: 'pneus', label: 'Pneus');
  final now = DateTime(2026, 6, 1);

  MaintenanceSchedule schedule({
    String id = 's1',
    int typeId = 1,
    DateTime? dueDate,
    int? dueMileage,
  }) => MaintenanceSchedule(
    id: id,
    vehicleId: 'v1',
    maintenanceTypeId: typeId,
    dueDate: dueDate,
    dueMileage: dueMileage,
  );

  ReminderUrgency urgencyOf(MaintenanceSchedule s, {int mileage = 10000}) =>
      Reminder.fromSchedule(
        schedule: s,
        type: vidange,
        currentMileage: mileage,
        now: now,
      ).urgency;

  group('Reminder.fromSchedule', () {
    test('date dépassée ou atteinte → en retard', () {
      expect(
        urgencyOf(schedule(dueDate: DateTime(2026, 5, 1))),
        ReminderUrgency.overdue,
      );
      expect(urgencyOf(schedule(dueDate: now)), ReminderUrgency.overdue);
    });

    test('kilométrage atteint → en retard', () {
      expect(urgencyOf(schedule(dueMileage: 10000)), ReminderUrgency.overdue);
    });

    test('dans le seuil de 30 jours → bientôt', () {
      expect(
        urgencyOf(schedule(dueDate: DateTime(2026, 6, 20))),
        ReminderUrgency.dueSoon,
      );
    });

    test('dans le seuil de 1000 km → bientôt', () {
      expect(urgencyOf(schedule(dueMileage: 10800)), ReminderUrgency.dueSoon);
    });

    test('au-delà des seuils → à venir', () {
      expect(
        urgencyOf(schedule(dueDate: DateTime(2026, 12, 1), dueMileage: 20000)),
        ReminderUrgency.upcoming,
      );
    });

    test('le critère le plus urgent l\'emporte (date ou km)', () {
      expect(
        urgencyOf(schedule(dueDate: DateTime(2027, 1, 1), dueMileage: 9000)),
        ReminderUrgency.overdue,
      );
    });

    test('seuils personnalisables', () {
      final reminder = Reminder.fromSchedule(
        schedule: schedule(dueMileage: 12000),
        type: vidange,
        currentMileage: 10000,
        now: now,
        mileageWarningThreshold: 3000,
      );
      expect(reminder.urgency, ReminderUrgency.dueSoon);
    });
  });

  group('Reminder.fromSchedules', () {
    test('ignore les types inconnus et trie par urgence', () {
      final reminders = Reminder.fromSchedules(
        schedules: [
          schedule(id: 'upcoming', dueDate: DateTime(2027, 1, 1)),
          schedule(id: 'unknown', typeId: 99, dueMileage: 1),
          schedule(id: 'overdue', typeId: 2, dueMileage: 5000),
          schedule(id: 'soon', dueDate: DateTime(2026, 6, 10)),
        ],
        typeById: {1: vidange, 2: pneus},
        currentMileage: 10000,
        now: now,
      );

      expect(reminders.map((r) => r.scheduleId), [
        'overdue',
        'soon',
        'upcoming',
      ]);
      expect(reminders.first.type, pneus);
    });
  });

  group('Reminder.compareByUrgency', () {
    Reminder reminder(String id, {DateTime? dueDate, int? dueMileage}) =>
        Reminder(
          scheduleId: id,
          vehicleId: 'v1',
          type: vidange,
          urgency: ReminderUrgency.upcoming,
          dueDate: dueDate,
          dueMileage: dueMileage,
        );

    test('à urgence égale : date la plus proche, puis échéances datées '
        'avant celles en km, puis km le plus bas', () {
      final sorted = [
        reminder('km-high', dueMileage: 50000),
        reminder('date-late', dueDate: DateTime(2027, 6, 1)),
        reminder('km-low', dueMileage: 20000),
        reminder('date-early', dueDate: DateTime(2027, 1, 1)),
      ]..sort(Reminder.compareByUrgency);

      expect(sorted.map((r) => r.scheduleId), [
        'date-early',
        'date-late',
        'km-low',
        'km-high',
      ]);
    });
  });
}
