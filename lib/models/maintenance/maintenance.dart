import 'package:json_annotation/json_annotation.dart';

import '../../core/utils/json_parsing.dart';

part 'maintenance.g.dart';

/// Intervention réalisée sur un véhicule (historique d'entretien).
@JsonSerializable(fieldRename: FieldRename.snake)
class Maintenance {
  const Maintenance({
    required this.id,
    required this.vehicleId,
    required this.maintenanceTypeId,
    required this.date,
    this.mileage,
    this.description,
    this.cost,
    this.provider,
    this.comment,
  });

  final String id;
  final String vehicleId;
  final int maintenanceTypeId;

  final DateTime date;
  final int? mileage;
  final String? description;

  @JsonKey(fromJson: parseNullableDouble)
  final double? cost;

  final String? provider;
  final String? comment;

  factory Maintenance.fromJson(Map<String, dynamic> json) =>
      _$MaintenanceFromJson(json);

  Map<String, dynamic> toJson() => _$MaintenanceToJson(this);
}
