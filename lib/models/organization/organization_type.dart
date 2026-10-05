import 'package:json_annotation/json_annotation.dart';

part 'organization_type.g.dart';

/// Type d'organisation (Garage, Concessionnaire, Contrôle technique...).
/// Liste de référence gérée côté backend.
@JsonSerializable(fieldRename: FieldRename.snake)
class OrganizationType {
  const OrganizationType({required this.id, required this.name});

  final int id;
  final String name;

  factory OrganizationType.fromJson(Map<String, dynamic> json) =>
      _$OrganizationTypeFromJson(json);

  Map<String, dynamic> toJson() => _$OrganizationTypeToJson(this);
}
