import 'package:json_annotation/json_annotation.dart';

@JsonEnum(fieldRename: FieldRename.snake)
enum DocumentType {
  carteGrise,
  assurance,
  controleTechnique,
  facture,
  entretien,
  autre,
}

extension DocumentTypeJson on DocumentType {
  /// Valeur snake_case attendue par le backend, pour les appels qui
  /// n'utilisent pas la sérialisation générée de [Document] (upload
  /// multipart notamment).
  String get jsonValue => switch (this) {
    DocumentType.carteGrise => 'carte_grise',
    DocumentType.assurance => 'assurance',
    DocumentType.controleTechnique => 'controle_technique',
    DocumentType.facture => 'facture',
    DocumentType.entretien => 'entretien',
    DocumentType.autre => 'autre',
  };
}
