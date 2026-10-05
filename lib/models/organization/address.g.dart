// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'address.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Address _$AddressFromJson(Map<String, dynamic> json) => Address(
  id: json['id'] as String? ?? '',
  street: json['street'] as String,
  complement: json['complement'] as String?,
  postalCode: json['postal_code'] as String,
  city: json['city'] as String,
  region: json['region'] as String?,
  country: json['country'] as String?,
  latitude: parseNullableDouble(json['latitude']),
  longitude: parseNullableDouble(json['longitude']),
);

Map<String, dynamic> _$AddressToJson(Address instance) => <String, dynamic>{
  'street': instance.street,
  'complement': instance.complement,
  'postal_code': instance.postalCode,
  'city': instance.city,
  'region': instance.region,
  'country': instance.country,
  'latitude': instance.latitude,
  'longitude': instance.longitude,
};
