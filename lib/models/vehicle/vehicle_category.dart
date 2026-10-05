import 'package:json_annotation/json_annotation.dart';

import '../../core/utils/json_parsing.dart';

part 'vehicle_category.g.dart';

/// Catégorie de véhicule (Moto, Voiture, Autre...). Liste de référence
/// gérée côté backend. Un véhicule en a une seule (la catégorie par défaut
/// s'il n'en précise pas), un garage peut en prendre plusieurs en charge.
@JsonSerializable(fieldRename: FieldRename.snake)
class VehicleCategory {
  const VehicleCategory({
    required this.id,
    required this.name,
    this.isDefault = false,
  });

  final int id;
  final String name;

  /// Catégorie par défaut (une seule, « Autre » à l'installation) :
  /// présélectionnée à la création d'un véhicule, affichée en dernier.
  @JsonKey(fromJson: parseBool, toJson: boolToInt)
  final bool isDefault;

  factory VehicleCategory.fromJson(Map<String, dynamic> json) =>
      _$VehicleCategoryFromJson(json);

  Map<String, dynamic> toJson() => _$VehicleCategoryToJson(this);

  @override
  bool operator ==(Object other) => other is VehicleCategory && other.id == id;

  @override
  int get hashCode => id.hashCode;
}
