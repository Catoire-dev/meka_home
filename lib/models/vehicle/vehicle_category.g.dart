// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle_category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VehicleCategory _$VehicleCategoryFromJson(Map<String, dynamic> json) =>
    VehicleCategory(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      isDefault: json['is_default'] == null
          ? false
          : parseBool(json['is_default']),
    );

Map<String, dynamic> _$VehicleCategoryToJson(VehicleCategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'is_default': boolToInt(instance.isDefault),
    };
