// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vehicle.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Vehicle _$VehicleFromJson(Map<String, dynamic> json) => Vehicle(
  id: json['id'] as String,
  customName: json['custom_name'] as String,
  category: $enumDecode(_$VehicleCategoryEnumMap, json['category']),
  status: $enumDecode(_$VehicleStatusEnumMap, json['status']),
  brand: json['brand'] as String,
  model: json['model'] as String,
  licensePlate: json['license_plate'] as String?,
  vin: json['vin'] as String?,
  firstRegistrationDate: json['first_registration_date'] == null
      ? null
      : DateTime.parse(json['first_registration_date'] as String),
  energy: $enumDecodeNullable(_$VehicleEnergyEnumMap, json['energy']),
  fiscalPower: (json['fiscal_power'] as num?)?.toInt(),
  powerHp: (json['power_hp'] as num?)?.toInt(),
  weightKg: (json['weight_kg'] as num?)?.toInt(),
  color: json['color'] as String?,
  mileage: (json['mileage'] as num?)?.toInt() ?? 0,
  comment: json['comment'] as String?,
  photoFilename: json['photo_filename'] as String?,
);

Map<String, dynamic> _$VehicleToJson(Vehicle instance) => <String, dynamic>{
  'id': instance.id,
  'custom_name': instance.customName,
  'category': _$VehicleCategoryEnumMap[instance.category]!,
  'status': _$VehicleStatusEnumMap[instance.status]!,
  'brand': instance.brand,
  'model': instance.model,
  'license_plate': instance.licensePlate,
  'vin': instance.vin,
  'first_registration_date': instance.firstRegistrationDate?.toIso8601String(),
  'energy': _$VehicleEnergyEnumMap[instance.energy],
  'fiscal_power': instance.fiscalPower,
  'power_hp': instance.powerHp,
  'weight_kg': instance.weightKg,
  'color': instance.color,
  'mileage': instance.mileage,
  'comment': instance.comment,
  'photo_filename': instance.photoFilename,
};

const _$VehicleCategoryEnumMap = {
  VehicleCategory.moto: 'moto',
  VehicleCategory.voiture: 'voiture',
  VehicleCategory.autre: 'autre',
};

const _$VehicleStatusEnumMap = {
  VehicleStatus.current: 'current',
  VehicleStatus.historical: 'historical',
};

const _$VehicleEnergyEnumMap = {
  VehicleEnergy.essence: 'essence',
  VehicleEnergy.diesel: 'diesel',
  VehicleEnergy.electrique: 'electrique',
  VehicleEnergy.hybride: 'hybride',
  VehicleEnergy.gpl: 'gpl',
  VehicleEnergy.autre: 'autre',
};
