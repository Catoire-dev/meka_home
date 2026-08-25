import '../maintenance/maintenance_schedule.dart';
import '../maintenance/maintenance_type.dart';

/// Niveau d'urgence d'une échéance, déterminé par rapport à la date et au
/// kilométrage actuels.
enum ReminderUrgency { upcoming, dueSoon, overdue }

/// Rappel d'entretien à venir pour un véhicule.
///
/// Modèle dérivé, construit côté application à partir d'un
/// [MaintenanceSchedule] et du kilométrage actuel du véhicule — il n'est
/// pas nécessairement sérialisé tel quel par le backend.
class Reminder {
  const Reminder({
    required this.scheduleId,
    required this.vehicleId,
    required this.type,
    required this.urgency,
    this.dueDate,
    this.dueMileage,
  });

  final String scheduleId;
  final String vehicleId;
  final MaintenanceType type;
  final ReminderUrgency urgency;
  final DateTime? dueDate;
  final int? dueMileage;

  /// Détermine l'urgence d'une échéance : en retard si la date ou le
  /// kilométrage sont dépassés, proche si l'un des deux seuils
  /// d'avertissement est atteint, sinon à venir.
  factory Reminder.fromSchedule({
    required MaintenanceSchedule schedule,
    required MaintenanceType type,
    required int currentMileage,
    DateTime? now,
    int mileageWarningThreshold = 1000,
    int dayWarningThreshold = 30,
  }) {
    final today = now ?? DateTime.now();

    final isDateOverdue =
        schedule.dueDate != null && !schedule.dueDate!.isAfter(today);
    final isMileageOverdue =
        schedule.dueMileage != null && currentMileage >= schedule.dueMileage!;

    final isDateSoon =
        schedule.dueDate != null &&
        schedule.dueDate!.difference(today).inDays <= dayWarningThreshold;
    final isMileageSoon =
        schedule.dueMileage != null &&
        (schedule.dueMileage! - currentMileage) <= mileageWarningThreshold;

    final urgency = (isDateOverdue || isMileageOverdue)
        ? ReminderUrgency.overdue
        : (isDateSoon || isMileageSoon)
        ? ReminderUrgency.dueSoon
        : ReminderUrgency.upcoming;

    return Reminder(
      scheduleId: schedule.id,
      vehicleId: schedule.vehicleId,
      type: type,
      urgency: urgency,
      dueDate: schedule.dueDate,
      dueMileage: schedule.dueMileage,
    );
  }

  static int _urgencyRank(ReminderUrgency urgency) => switch (urgency) {
    ReminderUrgency.overdue => 0,
    ReminderUrgency.dueSoon => 1,
    ReminderUrgency.upcoming => 2,
  };

  /// Trie par urgence (en retard d'abord), puis par proximité de la date
  /// ou du kilométrage.
  static int compareByUrgency(Reminder a, Reminder b) {
    final urgencyCompare = _urgencyRank(
      a.urgency,
    ).compareTo(_urgencyRank(b.urgency));
    if (urgencyCompare != 0) return urgencyCompare;

    if (a.dueDate != null && b.dueDate != null) {
      return a.dueDate!.compareTo(b.dueDate!);
    }
    if (a.dueDate != null) return -1;
    if (b.dueDate != null) return 1;

    if (a.dueMileage != null && b.dueMileage != null) {
      return a.dueMileage!.compareTo(b.dueMileage!);
    }
    if (a.dueMileage != null) return -1;
    if (b.dueMileage != null) return 1;
    return 0;
  }
}
