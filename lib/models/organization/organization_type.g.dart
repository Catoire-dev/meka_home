// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'organization_type.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrganizationType _$OrganizationTypeFromJson(Map<String, dynamic> json) =>
    OrganizationType(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
    );

Map<String, dynamic> _$OrganizationTypeToJson(OrganizationType instance) =>
    <String, dynamic>{'id': instance.id, 'name': instance.name};
