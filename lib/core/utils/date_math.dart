/// Ajoute [months] mois à [date] (valeur négative acceptée). Le jour est
/// ramené au dernier jour du mois cible s'il n'existe pas (31/01 + 1 mois
/// → 28/02 ou 29/02).
DateTime addMonths(DateTime date, int months) {
  final monthIndex = date.month - 1 + months;
  final year = date.year + (monthIndex / 12).floor();
  final month = monthIndex % 12 + 1;
  final lastDay = DateTime(year, month + 1, 0).day;
  final day = date.day > lastDay ? lastDay : date.day;
  return DateTime(year, month, day);
}

/// Nombre de mois entiers le plus proche entre [from] et [to] (négatif si
/// [to] précède [from]), ex. 31/01 → 28/02 = 1 mois.
int monthsBetween(DateTime from, DateTime to) {
  var months = (to.year - from.year) * 12 + to.month - from.month;
  final gapDays = to.difference(addMonths(from, months)).inDays;
  if (gapDays > 15) months++;
  if (gapDays < -15) months--;
  return months;
}
