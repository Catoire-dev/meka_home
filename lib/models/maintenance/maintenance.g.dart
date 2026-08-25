// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'maintenance.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Maintenance _$MaintenanceFromJson(Map<String, dynamic> json) => Maintenance(
  id: json['id'] as String,
  vehicleId: json['vehicle_id'] as String,
  maintenanceTypeId: (json['maintenance_type_id'] as num).toInt(),
  date: DateTime.parse(json['date'] as String),
  mileage: (json['mileage'] as num?)?.toInt(),
  description: json['description'] as String?,
  cost: parseNullableDouble(json['cost']),
  provider: json['provider'] as String?,
  comment: json['comment'] as String?,
);

Map<String, dynamic> _$MaintenanceToJson(Maintenance instance) =>
    <String, dynamic>{
      'id': instance.id,
      'vehicle_id': instance.vehicleId,
      'maintenance_type_id': instance.maintenanceTypeId,
      'date': instance.date.toIso8601String(),
      'mileage': instance.mileage,
      'description': instance.description,
      'cost': instance.cost,
      'provider': instance.provider,
      'comment': instance.comment,
    };
