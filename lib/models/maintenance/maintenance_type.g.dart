// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'maintenance_type.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MaintenanceType _$MaintenanceTypeFromJson(Map<String, dynamic> json) =>
    MaintenanceType(
      id: (json['id'] as num).toInt(),
      code: json['code'] as String,
      label: json['label'] as String,
      icon: json['icon'] as String?,
      isCustom: json['is_custom'] as bool? ?? false,
    );

Map<String, dynamic> _$MaintenanceTypeToJson(MaintenanceType instance) =>
    <String, dynamic>{
      'id': instance.id,
      'code': instance.code,
      'label': instance.label,
      'icon': instance.icon,
      'is_custom': instance.isCustom,
    };
