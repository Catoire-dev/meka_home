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
}
