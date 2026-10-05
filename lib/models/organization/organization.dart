import 'package:json_annotation/json_annotation.dart';

import '../../core/utils/json_parsing.dart';
import '../vehicle/vehicle_category.dart';
import 'address.dart';
import 'organization_type.dart';

part 'organization.g.dart';

/// Garage ou intervenant chez qui sont réalisés les entretiens. [isMine]
/// désigne l'entrée « Moi-même » (entretiens réalisés soi-même).
///
/// En lecture, le type, l'adresse et les catégories arrivent sous forme
/// d'objets ; en écriture, ils sont envoyés par identifiant.
@JsonSerializable(fieldRename: FieldRename.snake)
class Organization {
  const Organization({
    required this.id,
    required this.name,
    this.type,
    this.phone,
    this.mobile,
    this.website,
    this.address,
    this.comment,
    this.categories = const [],
    this.isArchived = false,
    this.isMine = false,
  });

  final String id;
  final String name;

  /// Absent pour l'entrée « Moi-même ».
  @JsonKey(includeToJson: false)
  final OrganizationType? type;
  final String? phone;
  final String? mobile;
  final String? website;
  @JsonKey(includeToJson: false)
  final Address? address;
  final String? comment;

  /// Catégories de véhicules prises en charge.
  @JsonKey(includeToJson: false)
  final List<VehicleCategory> categories;

  @JsonKey(fromJson: parseBool, toJson: boolToInt)
  final bool isArchived;
  @JsonKey(fromJson: parseBool, toJson: boolToInt)
  final bool isMine;

  /// Proposable pour un entretien sur un véhicule de [vehicleCategory] :
  /// l'entrée « Moi-même » l'est toujours.
  bool handles(VehicleCategory vehicleCategory) =>
      isMine || categories.contains(vehicleCategory);

  factory Organization.fromJson(Map<String, dynamic> json) =>
      _$OrganizationFromJson(json);

  Map<String, dynamic> toJson() => {
    ..._$OrganizationToJson(this),
    'organization_type_id': type?.id,
    'address_id': (address?.id.isEmpty ?? true) ? null : address!.id,
    'category_ids': [for (final category in categories) category.id],
  };

  Organization copyWith({Address? address, bool? isArchived}) {
    return Organization(
      id: id,
      name: name,
      type: type,
      phone: phone,
      mobile: mobile,
      website: website,
      address: address ?? this.address,
      comment: comment,
      categories: categories,
      isArchived: isArchived ?? this.isArchived,
      isMine: isMine,
    );
  }
}
