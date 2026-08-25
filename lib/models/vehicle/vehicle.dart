import 'package:json_annotation/json_annotation.dart';

import 'vehicle_category.dart';
import 'vehicle_energy.dart';
import 'vehicle_status.dart';

part 'vehicle.g.dart';

/// Véhicule du parc — champs administratifs basés sur la carte grise
/// française, complétés par les informations d'usage personnel.
@JsonSerializable(fieldRename: FieldRename.snake)
class Vehicle {
  const Vehicle({
    required this.id,
    required this.customName,
    required this.category,
    required this.status,
    required this.brand,
    required this.model,
    this.licensePlate,
    this.vin,
    this.firstRegistrationDate,
    this.energy,
    this.fiscalPower,
    this.powerHp,
    this.weightKg,
    this.color,
    this.mileage = 0,
    this.comment,
    this.photoFilename,
  });

  final String id;
  final String customName;
  final VehicleCategory category;
  final VehicleStatus status;

  final String brand;
  final String model;
  final String? licensePlate;
  final String? vin;
  final DateTime? firstRegistrationDate;

  final VehicleEnergy? energy;
  final int? fiscalPower;
  final int? powerHp;
  final int? weightKg;
  final String? color;

  final int mileage;
  final String? comment;
  final String? photoFilename;

  bool get isCurrent => status == VehicleStatus.current;
  bool get isHistorical => status == VehicleStatus.historical;

  factory Vehicle.fromJson(Map<String, dynamic> json) =>
      _$VehicleFromJson(json);

  Map<String, dynamic> toJson() => _$VehicleToJson(this);

  Vehicle copyWith({
    String? customName,
    VehicleCategory? category,
    VehicleStatus? status,
    String? brand,
    String? model,
    String? licensePlate,
    String? vin,
    DateTime? firstRegistrationDate,
    VehicleEnergy? energy,
    int? fiscalPower,
    int? powerHp,
    int? weightKg,
    String? color,
    int? mileage,
    String? comment,
    String? photoFilename,
  }) {
    return Vehicle(
      id: id,
      customName: customName ?? this.customName,
      category: category ?? this.category,
      status: status ?? this.status,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      licensePlate: licensePlate ?? this.licensePlate,
      vin: vin ?? this.vin,
      firstRegistrationDate:
          firstRegistrationDate ?? this.firstRegistrationDate,
      energy: energy ?? this.energy,
      fiscalPower: fiscalPower ?? this.fiscalPower,
      powerHp: powerHp ?? this.powerHp,
      weightKg: weightKg ?? this.weightKg,
      color: color ?? this.color,
      mileage: mileage ?? this.mileage,
      comment: comment ?? this.comment,
      photoFilename: photoFilename ?? this.photoFilename,
    );
  }
}
