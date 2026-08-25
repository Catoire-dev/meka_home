// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'document.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Document _$DocumentFromJson(Map<String, dynamic> json) => Document(
  id: json['id'] as String,
  vehicleId: json['vehicle_id'] as String,
  type: $enumDecode(_$DocumentTypeEnumMap, json['type']),
  filename: json['filename'] as String,
  maintenanceId: json['maintenance_id'] as String?,
  comment: json['comment'] as String?,
  uploadedAt: json['uploaded_at'] == null
      ? null
      : DateTime.parse(json['uploaded_at'] as String),
);

Map<String, dynamic> _$DocumentToJson(Document instance) => <String, dynamic>{
  'id': instance.id,
  'vehicle_id': instance.vehicleId,
  'maintenance_id': instance.maintenanceId,
  'type': _$DocumentTypeEnumMap[instance.type]!,
  'filename': instance.filename,
  'comment': instance.comment,
  'uploaded_at': instance.uploadedAt?.toIso8601String(),
};

const _$DocumentTypeEnumMap = {
  DocumentType.carteGrise: 'carte_grise',
  DocumentType.assurance: 'assurance',
  DocumentType.controleTechnique: 'controle_technique',
  DocumentType.facture: 'facture',
  DocumentType.entretien: 'entretien',
  DocumentType.autre: 'autre',
};
