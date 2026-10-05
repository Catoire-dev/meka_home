import '../../core/utils/date_math.dart';
import 'maintenance.dart';
import 'maintenance_schedule.dart';

/// Intervalle entre une intervention et l'échéance suivante (« tous les
/// 6000 km », « tous les 12 mois »), déduit des données existantes : le
/// backend ne stocke que des échéances absolues.
class ScheduleInterval {
  const ScheduleInterval({this.mileage, this.months});

  final int? mileage;
  final int? months;

  bool get isEmpty => mileage == null && months == null;

  /// Intervalle prévu entre l'intervention [base] et l'échéance [schedule].
  /// Seuls les écarts strictement positifs sont retenus.
  factory ScheduleInterval.between(
    Maintenance base,
    MaintenanceSchedule schedule,
  ) {
    final baseMileage = base.mileage;
    final dueMileage = schedule.dueMileage;
    final mileage = baseMileage != null && dueMileage != null
        ? dueMileage - baseMileage
        : null;

    final dueDate = schedule.dueDate;
    final months = dueDate != null ? monthsBetween(base.date, dueDate) : null;

    return ScheduleInterval(
      mileage: mileage != null && mileage > 0 ? mileage : null,
      months: months != null && months > 0 ? months : null,
    );
  }

  /// Intervalle de l'échéance [schedule] : celui saisi à sa planification
  /// s'il a été conservé, sinon calculé depuis l'intervention qui l'a
  /// planifiée (`lastMaintenanceId`) ou, à défaut, depuis la plus récente
  /// intervention du même type. Vide si rien ne permet de le déduire.
  factory ScheduleInterval.ofSchedule(
    MaintenanceSchedule schedule,
    List<Maintenance> maintenances,
  ) {
    final stored = ScheduleInterval(
      mileage: schedule.intervalMileage,
      months: schedule.intervalMonths,
    );
    if (stored.mileage != null && stored.months != null) return stored;
    final derived = ScheduleInterval._derived(schedule, maintenances);
    return ScheduleInterval(
      mileage: stored.mileage ?? derived.mileage,
      months: stored.months ?? derived.months,
    );
  }

  factory ScheduleInterval._derived(
    MaintenanceSchedule schedule,
    List<Maintenance> maintenances,
  ) {
    final linked = maintenances
        .where((m) => m.id == schedule.lastMaintenanceId)
        .firstOrNull;
    final sameType =
        maintenances
            .where((m) => m.maintenanceTypeId == schedule.maintenanceTypeId)
            .toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    final base = linked ?? sameType.firstOrNull;
    return base != null
        ? ScheduleInterval.between(base, schedule)
        : const ScheduleInterval();
  }
}
