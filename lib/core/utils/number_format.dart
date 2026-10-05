/// Formate un montant en euros avec la virgule décimale française,
/// ex. `129,90 €`.
String formatEuros(double amount) =>
    '${amount.toStringAsFixed(2).replaceAll('.', ',')} €';

/// Lit un nombre décimal saisi par l'utilisateur, en acceptant la virgule
/// comme séparateur. Renvoie `null` si la saisie est vide ou invalide.
double? parseUserDouble(String input) {
  final normalized = input.trim().replaceAll(' ', '').replaceAll(',', '.');
  return normalized.isEmpty ? null : double.tryParse(normalized);
}

/// Lit un entier saisi par l'utilisateur (espaces tolérés). Renvoie `null`
/// si la saisie est vide ou invalide.
int? parseUserInt(String input) {
  final normalized = input.trim().replaceAll(' ', '');
  return normalized.isEmpty ? null : int.tryParse(normalized);
}
