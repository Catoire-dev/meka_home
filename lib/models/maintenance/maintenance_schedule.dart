import 'package:json_annotation/json_annotation.dart';

part 'maintenance_schedule.g.dart';

/// Prochaine échéance d'entretien planifiée pour un véhicule, en date
/// et/ou en kilométrage. [intervalMonths] / [intervalMileage] conservent
/// l'intervalle saisi en mode « dans », pour le reproposer à la
/// replanification (null si la valeur a été saisie en fixe).
@JsonSerializable(fieldRename: FieldRename.snake)
class MaintenanceSchedule {
  const MaintenanceSchedule({
    required this.id,
    required this.vehicleId,
    required this.maintenanceTypeId,
    this.dueDate,
    this.dueMileage,
    this.lastMaintenanceId,
    this.comment,
    this.intervalMonths,
    this.intervalMileage,
  });

  final String id;
  final String vehicleId;
  final int maintenanceTypeId;

  final DateTime? dueDate;
  final int? dueMileage;
  final String? lastMaintenanceId;
  final String? comment;
  final int? intervalMonths;
  final int? intervalMileage;

  factory MaintenanceSchedule.fromJson(Map<String, dynamic> json) =>
      _$MaintenanceScheduleFromJson(json);

  Map<String, dynamic> toJson() => _$MaintenanceScheduleToJson(this);

  MaintenanceSchedule copyWith({
    int? maintenanceTypeId,
    DateTime? dueDate,
    int? dueMileage,
    String? lastMaintenanceId,
    String? comment,
    int? intervalMonths,
    int? intervalMileage,
  }) {
    return MaintenanceSchedule(
      id: id,
      vehicleId: vehicleId,
      maintenanceTypeId: maintenanceTypeId ?? this.maintenanceTypeId,
      dueDate: dueDate ?? this.dueDate,
      dueMileage: dueMileage ?? this.dueMileage,
      lastMaintenanceId: lastMaintenanceId ?? this.lastMaintenanceId,
      comment: comment ?? this.comment,
      intervalMonths: intervalMonths ?? this.intervalMonths,
      intervalMileage: intervalMileage ?? this.intervalMileage,
    );
  }
}
