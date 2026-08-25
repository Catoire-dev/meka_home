import 'package:json_annotation/json_annotation.dart';

part 'maintenance_type.g.dart';

/// Type d'entretien (vidange, pneus, révision...). Liste extensible :
/// pré-remplie par le backend, ou ajoutée par l'utilisateur (`isCustom`).
@JsonSerializable(fieldRename: FieldRename.snake)
class MaintenanceType {
  const MaintenanceType({
    required this.id,
    required this.code,
    required this.label,
    this.icon,
    this.isCustom = false,
  });

  final int id;
  final String code;
  final String label;
  final String? icon;
  final bool isCustom;

  factory MaintenanceType.fromJson(Map<String, dynamic> json) =>
      _$MaintenanceTypeFromJson(json);

  Map<String, dynamic> toJson() => _$MaintenanceTypeToJson(this);
}
