// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'maintenance_schedule.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MaintenanceSchedule _$MaintenanceScheduleFromJson(Map<String, dynamic> json) =>
    MaintenanceSchedule(
      id: json['id'] as String,
      vehicleId: json['vehicle_id'] as String,
      maintenanceTypeId: (json['maintenance_type_id'] as num).toInt(),
      dueDate: json['due_date'] == null
          ? null
          : DateTime.parse(json['due_date'] as String),
      dueMileage: (json['due_mileage'] as num?)?.toInt(),
      lastMaintenanceId: json['last_maintenance_id'] as String?,
      comment: json['comment'] as String?,
    );

Map<String, dynamic> _$MaintenanceScheduleToJson(
  MaintenanceSchedule instance,
) => <String, dynamic>{
  'id': instance.id,
  'vehicle_id': instance.vehicleId,
  'maintenance_type_id': instance.maintenanceTypeId,
  'due_date': instance.dueDate?.toIso8601String(),
  'due_mileage': instance.dueMileage,
  'last_maintenance_id': instance.lastMaintenanceId,
  'comment': instance.comment,
};
