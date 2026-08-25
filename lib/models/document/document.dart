import 'package:json_annotation/json_annotation.dart';

import 'document_type.dart';

part 'document.g.dart';

/// Document lié à un véhicule (et éventuellement à une intervention
/// d'entretien précise) : carte grise, assurance, facture...
@JsonSerializable(fieldRename: FieldRename.snake)
class Document {
  const Document({
    required this.id,
    required this.vehicleId,
    required this.type,
    required this.filename,
    this.maintenanceId,
    this.comment,
    this.uploadedAt,
  });

  final String id;
  final String vehicleId;
  final String? maintenanceId;

  final DocumentType type;
  final String filename;
  final String? comment;
  final DateTime? uploadedAt;

  factory Document.fromJson(Map<String, dynamic> json) =>
      _$DocumentFromJson(json);

  Map<String, dynamic> toJson() => _$DocumentToJson(this);
}
