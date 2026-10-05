import '../../core/utils/date_math.dart';

/// Unité d'un intervalle de temps saisi pour une échéance (« dans 3 mois »,
/// « dans 1 an »).
enum ScheduleIntervalUnit {
  months,
  years;

  String get label => switch (this) {
    ScheduleIntervalUnit.months => 'Mois',
    ScheduleIntervalUnit.years => 'Ans',
  };

  /// Date atteinte [amount] unités après [reference].
  DateTime addTo(DateTime reference, int amount) => switch (this) {
    ScheduleIntervalUnit.months => addMonths(reference, amount),
    ScheduleIntervalUnit.years => addMonths(reference, amount * 12),
  };
}
