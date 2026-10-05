/// Conversions tolérantes pour les champs dont l'encodage JSON
/// côté backend peut varier (ex. DECIMAL parfois sérialisé en chaîne).
double? parseNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

/// Booléen tolérant : accepte `true/false`, `0/1` (TINYINT MySQL) et leurs
/// équivalents en chaîne. Toute autre valeur vaut `false`.
bool parseBool(dynamic value) => switch (value) {
  bool() => value,
  num() => value != 0,
  String() => value == '1' || value.toLowerCase() == 'true',
  _ => false,
};

/// Booléen encodé en `0/1`, format attendu par le backend (TINYINT).
int boolToInt(bool value) => value ? 1 : 0;
