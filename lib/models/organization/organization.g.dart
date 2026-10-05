// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'organization.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Organization _$OrganizationFromJson(Map<String, dynamic> json) => Organization(
  id: json['id'] as String,
  name: json['name'] as String,
  type: json['type'] == null
      ? null
      : OrganizationType.fromJson(json['type'] as Map<String, dynamic>),
  phone: json['phone'] as String?,
  mobile: json['mobile'] as String?,
  website: json['website'] as String?,
  address: json['address'] == null
      ? null
      : Address.fromJson(json['address'] as Map<String, dynamic>),
  comment: json['comment'] as String?,
  categories:
      (json['categories'] as List<dynamic>?)
          ?.map((e) => VehicleCategory.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  isArchived: json['is_archived'] == null
      ? false
      : parseBool(json['is_archived']),
  isMine: json['is_mine'] == null ? false : parseBool(json['is_mine']),
);

Map<String, dynamic> _$OrganizationToJson(Organization instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'phone': instance.phone,
      'mobile': instance.mobile,
      'website': instance.website,
      'comment': instance.comment,
      'is_archived': boolToInt(instance.isArchived),
      'is_mine': boolToInt(instance.isMine),
    };
