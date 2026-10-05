import 'package:json_annotation/json_annotation.dart';

import '../../core/utils/json_parsing.dart';

part 'address.g.dart';

/// Adresse postale, ressource à part entière côté backend, référencée par
/// les organisations.
@JsonSerializable(fieldRename: FieldRename.snake)
class Address {
  const Address({
    this.id = '',
    required this.street,
    this.complement,
    required this.postalCode,
    required this.city,
    this.region,
    this.country,
    this.latitude,
    this.longitude,
  });

  /// Vide tant que l'adresse n'a pas été créée côté backend.
  @JsonKey(includeToJson: false)
  final String id;
  final String street;
  final String? complement;
  final String postalCode;
  final String city;
  final String? region;
  final String? country;
  @JsonKey(fromJson: parseNullableDouble)
  final double? latitude;
  @JsonKey(fromJson: parseNullableDouble)
  final double? longitude;

  /// Adresse sur une ligne : « 12 rue X, 75001 Paris ».
  String get singleLine =>
      [street, ?complement, '$postalCode $city'].join(', ');

  factory Address.fromJson(Map<String, dynamic> json) =>
      _$AddressFromJson(json);

  Map<String, dynamic> toJson() => _$AddressToJson(this);

  Address copyWith({
    String? street,
    String? complement,
    String? postalCode,
    String? city,
  }) {
    return Address(
      id: id,
      street: street ?? this.street,
      complement: complement ?? this.complement,
      postalCode: postalCode ?? this.postalCode,
      city: city ?? this.city,
      region: region,
      country: country,
      latitude: latitude,
      longitude: longitude,
    );
  }
}
