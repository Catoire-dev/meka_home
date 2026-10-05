import 'package:flutter_test/flutter_test.dart';
import 'package:meka_home/features/maintenance/widgets/schedule_due_controller.dart';
import 'package:meka_home/models/maintenance/schedule_interval.dart';
import 'package:meka_home/models/maintenance/schedule_interval_unit.dart';

void main() {
  final ref = DateTime(2026, 10, 5);

  test('mode relatif : calcule à partir de la référence', () {
    final controller = ScheduleDueController();
    controller.mileageController.text = '6 000';
    controller.durationController.text = '1';
    controller.unit = ScheduleIntervalUnit.years;

    expect(controller.resolveDueMileage(42000), 48000);
    expect(controller.resolveDueDate(ref), DateTime(2027, 10, 5));
    controller.dispose();
  });

  test('mode fixe : renvoie les valeurs saisies telles quelles', () {
    final controller = ScheduleDueController()
      ..setDateMode(DueInputMode.absolute, ref)
      ..setMileageMode(DueInputMode.absolute, 42000)
      ..absoluteDate = DateTime(2027, 3, 1);
    controller.mileageController.text = '50000';

    expect(controller.resolveDueDate(ref), DateTime(2027, 3, 1));
    expect(controller.resolveDueMileage(42000), 50000);
    controller.dispose();
  });

  test('reset reprend les valeurs existantes en mode fixe', () {
    final controller = ScheduleDueController()
      ..reset(dueDate: DateTime(2027, 3, 1), dueMileage: 50000);

    expect(controller.dateMode, DueInputMode.absolute);
    expect(controller.mileageMode, DueInputMode.absolute);
    expect(controller.resolveDueDate(ref), DateTime(2027, 3, 1));
    expect(controller.resolveDueMileage(42000), 50000);
    controller.dispose();
  });

  test("reset reprend en mode relatif les dimensions d'intervalle connu", () {
    final controller = ScheduleDueController()
      ..reset(
        dueDate: DateTime(2027, 3, 1),
        dueMileage: 50000,
        interval: const ScheduleInterval(months: 24),
      );

    expect(controller.dateMode, DueInputMode.relative);
    expect(controller.unit, ScheduleIntervalUnit.years);
    expect(controller.durationController.text, '2');
    expect(controller.mileageMode, DueInputMode.absolute);
    expect(controller.resolveDueMileage(42000), 50000);
    controller.dispose();
  });

  test('changer de mode convertit la valeur déjà saisie', () {
    final controller = ScheduleDueController();
    controller.mileageController.text = '6000';
    controller.durationController.text = '3';

    controller.setMileageMode(DueInputMode.absolute, 42000);
    expect(controller.mileageController.text, '48000');
    controller.setMileageMode(DueInputMode.relative, 42000);
    expect(controller.mileageController.text, '6000');

    controller.setDateMode(DueInputMode.absolute, ref);
    expect(controller.absoluteDate, DateTime(2027, 1, 5));
    controller.dispose();
  });

  test('hasAnyDue est faux sans aucune échéance', () {
    final controller = ScheduleDueController()
      ..setDateMode(DueInputMode.absolute, ref);
    expect(controller.hasAnyDue, isFalse);
    controller.absoluteDate = DateTime(2027);
    expect(controller.hasAnyDue, isTrue);
    controller.dispose();
  });

  test("relativeInterval n'inclut que les valeurs saisies en mode « dans »", () {
    final controller = ScheduleDueController()
      ..unit = ScheduleIntervalUnit.years
      ..setMileageMode(DueInputMode.absolute, 42000);
    controller.durationController.text = '2';
    controller.mileageController.text = '50000';

    expect(controller.relativeInterval.months, 24);
    expect(controller.relativeInterval.mileage, isNull);
    controller.dispose();
  });

  test('prefill exprime 12 mois en années, en mode relatif', () {
    final controller = ScheduleDueController()
      ..prefill(const ScheduleInterval(mileage: 6000, months: 12));

    expect(controller.dateMode, DueInputMode.relative);
    expect(controller.unit, ScheduleIntervalUnit.years);
    expect(controller.durationController.text, '1');
    expect(controller.resolveDueMileage(42000), 48000);
    controller.dispose();
  });
}
