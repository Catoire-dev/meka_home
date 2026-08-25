import 'package:json_annotation/json_annotation.dart';

part 'maintenance_schedule.g.dart';

/// Prochaine échéance d'entretien planifiée pour un véhicule, en date
/// et/ou en kilométrage.
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
  });

  final String id;
  final String vehicleId;
  final int maintenanceTypeId;

  final DateTime? dueDate;
  final int? dueMileage;
  final String? lastMaintenanceId;
  final String? comment;

  factory MaintenanceSchedule.fromJson(Map<String, dynamic> json) =>
      _$MaintenanceScheduleFromJson(json);

  Map<String, dynamic> toJson() => _$MaintenanceScheduleToJson(this);
}
