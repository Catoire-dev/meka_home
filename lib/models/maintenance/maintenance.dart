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
    required this.organizationId,
    this.mileage,
    this.description,
    this.cost,
    this.comment,
  });

  final String id;
  final String vehicleId;
  final int maintenanceTypeId;

  final DateTime date;

  /// Garage / intervenant (obligatoire).
  final String organizationId;
  final int? mileage;
  final String? description;

  @JsonKey(fromJson: parseNullableDouble)
  final double? cost;

  final String? comment;

  factory Maintenance.fromJson(Map<String, dynamic> json) =>
      _$MaintenanceFromJson(json);

  Map<String, dynamic> toJson() => _$MaintenanceToJson(this);

  Maintenance copyWith({
    int? maintenanceTypeId,
    DateTime? date,
    String? organizationId,
    int? mileage,
    String? description,
    double? cost,
    String? comment,
  }) {
    return Maintenance(
      id: id,
      vehicleId: vehicleId,
      maintenanceTypeId: maintenanceTypeId ?? this.maintenanceTypeId,
      date: date ?? this.date,
      organizationId: organizationId ?? this.organizationId,
      mileage: mileage ?? this.mileage,
      description: description ?? this.description,
      cost: cost ?? this.cost,
      comment: comment ?? this.comment,
    );
  }
}
