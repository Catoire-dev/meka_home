import 'package:flutter/widgets.dart';

import '../../../core/utils/number_format.dart';
import '../../../models/maintenance/schedule_interval.dart';
import '../../../models/maintenance/schedule_interval_unit.dart';

/// Façon de saisir une échéance : relativement à une référence (« dans
/// 6000 km », « dans 3 mois ») ou en valeur fixe (« à 48000 km », « le
/// 05/01/2027 »).
enum DueInputMode { relative, absolute }

/// État de la saisie d'une échéance en temps et en kilométrage, chacun en
/// mode relatif ou fixe. Les valeurs relatives sont converties en date et
/// kilométrage absolus à partir d'une référence (aujourd'hui / kilométrage
/// actuel, ou date et kilométrage de l'intervention).
class ScheduleDueController extends ChangeNotifier {
  ScheduleDueController() {
    mileageController.addListener(notifyListeners);
    durationController.addListener(notifyListeners);
  }

  /// Kilométrage : distance restante (relatif) ou kilométrage visé (fixe).
  final mileageController = TextEditingController();

  /// Durée restante dans l'unité [unit] (mode relatif uniquement).
  final durationController = TextEditingController();

  ScheduleIntervalUnit _unit = ScheduleIntervalUnit.months;
  DueInputMode _dateMode = DueInputMode.relative;
  DueInputMode _mileageMode = DueInputMode.relative;
  DateTime? _absoluteDate;

  ScheduleIntervalUnit get unit => _unit;
  set unit(ScheduleIntervalUnit value) {
    _unit = value;
    notifyListeners();
  }

  DueInputMode get dateMode => _dateMode;
  DueInputMode get mileageMode => _mileageMode;

  /// Date visée en mode fixe.
  DateTime? get absoluteDate => _absoluteDate;
  set absoluteDate(DateTime? value) {
    _absoluteDate = value;
    notifyListeners();
  }

  int? get mileageValue => parseUserInt(mileageController.text);
  int? get durationAmount => parseUserInt(durationController.text);

  /// Au moins une échéance (en temps ou en kilométrage) est définie.
  bool get hasAnyDue =>
      mileageValue != null ||
      switch (_dateMode) {
        DueInputMode.relative => durationAmount != null,
        DueInputMode.absolute => _absoluteDate != null,
      };

  /// Réinitialise la saisie. Chaque dimension présente dans [interval] est
  /// reprise en mode relatif (une durée multiple de 12 mois est exprimée en
  /// années) ; à défaut, la valeur existante éventuelle ([dueDate],
  /// [dueMileage]) est reprise en mode fixe, pour être conservée telle
  /// quelle.
  void reset({
    DateTime? dueDate,
    int? dueMileage,
    ScheduleInterval interval = const ScheduleInterval(),
  }) {
    durationController.clear();
    _unit = ScheduleIntervalUnit.months;
    _absoluteDate = null;
    _dateMode = DueInputMode.relative;
    if (interval.months case final months?) {
      final inYears = months % 12 == 0;
      _unit = inYears
          ? ScheduleIntervalUnit.years
          : ScheduleIntervalUnit.months;
      durationController.text = '${inYears ? months ~/ 12 : months}';
    } else if (dueDate != null) {
      _absoluteDate = dueDate;
      _dateMode = DueInputMode.absolute;
    }
    final mileage = interval.mileage ?? dueMileage;
    _mileageMode = interval.mileage == null && dueMileage != null
        ? DueInputMode.absolute
        : DueInputMode.relative;
    mileageController.text = mileage?.toString() ?? '';
    notifyListeners();
  }

  /// Réinitialise la saisie en mode relatif, pré-remplie avec [interval]
  /// (ex. l'intervalle de l'échéance précédente).
  void prefill(ScheduleInterval interval) => reset(interval: interval);

  /// Change le mode de saisie de la date, en reprenant la date déjà
  /// calculée lors du passage en mode fixe.
  void setDateMode(DueInputMode mode, DateTime reference) {
    if (mode == _dateMode) return;
    if (mode == DueInputMode.absolute) {
      _absoluteDate = resolveDueDate(reference);
      durationController.clear();
    } else {
      _absoluteDate = null;
    }
    _dateMode = mode;
    notifyListeners();
  }

  /// Change le mode de saisie du kilométrage en convertissant la valeur
  /// saisie quand la référence est connue.
  void setMileageMode(DueInputMode mode, int? reference) {
    if (mode == _mileageMode) return;
    final value = mileageValue;
    _mileageMode = mode;
    if (value == null) {
      notifyListeners();
      return;
    }
    final converted = switch (mode) {
      DueInputMode.absolute => reference != null ? reference + value : null,
      DueInputMode.relative =>
        reference != null && value > reference ? value - reference : null,
    };
    // Met aussi à jour les écouteurs via le contrôleur de texte.
    mileageController.text = converted?.toString() ?? '';
  }

  /// Intervalle saisi en mode relatif, à conserver avec l'échéance ; les
  /// dimensions saisies en valeur fixe sont nulles.
  ScheduleInterval get relativeInterval => ScheduleInterval(
    mileage: _mileageMode == DueInputMode.relative ? mileageValue : null,
    months: switch ((_dateMode, durationAmount)) {
      (DueInputMode.relative, final amount?) =>
        _unit == ScheduleIntervalUnit.years ? amount * 12 : amount,
      _ => null,
    },
  );

  DateTime? resolveDueDate(DateTime reference) => switch (_dateMode) {
    DueInputMode.absolute => _absoluteDate,
    DueInputMode.relative => switch (durationAmount) {
      final amount? => _unit.addTo(reference, amount),
      null => null,
    },
  };

  int? resolveDueMileage(int? reference) {
    final value = mileageValue;
    if (value == null) return null;
    return switch (_mileageMode) {
      DueInputMode.absolute => value,
      DueInputMode.relative => reference != null ? reference + value : null,
    };
  }

  @override
  void dispose() {
    mileageController.dispose();
    durationController.dispose();
    super.dispose();
  }
}
