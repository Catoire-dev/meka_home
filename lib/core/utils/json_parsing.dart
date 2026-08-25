/// Conversions numériques tolérantes pour les champs dont l'encodage JSON
/// côté backend peut varier (ex. DECIMAL parfois sérialisé en chaîne).
double? parseNullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}
