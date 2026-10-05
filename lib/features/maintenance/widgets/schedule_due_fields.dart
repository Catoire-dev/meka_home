import 'package:flutter/material.dart';

import '../../../core/utils/date_format.dart';
import '../../../core/utils/number_format.dart';
import '../../../core/widgets/date_picker_field.dart';
import '../../../models/maintenance/schedule_interval_unit.dart';
import 'schedule_due_controller.dart';

/// Saisie d'une échéance en temps et/ou en kilométrage, chacune au choix
/// relative (« dans 3 mois », « dans 6000 km ») ou fixe (« le 05/01/2027 »,
/// « à 48000 km »). Les valeurs relatives sont calculées à partir de
/// [referenceDate] et [referenceMileage]. Au moins une échéance est requise.
class ScheduleDueFields extends StatelessWidget {
  const ScheduleDueFields({
    super.key,
    required this.controller,
    required this.referenceDate,
    required this.referenceMileage,
    required this.referenceLabel,
  });

  final ScheduleDueController controller;
  final DateTime referenceDate;
  final int? referenceMileage;

  /// Origine du calcul relatif, ex. « aujourd'hui » ou « l'intervention ».
  final String referenceLabel;

  String? _validatePositiveInt(String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    final parsed = parseUserInt(text);
    return parsed == null || parsed <= 0 ? 'Nombre invalide' : null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final captionStyle = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ModeHeader(
            title: 'Échéance en temps',
            absoluteLabel: 'Le',
            mode: controller.dateMode,
            onChanged: (mode) => controller.setDateMode(mode, referenceDate),
          ),
          const SizedBox(height: 8),
          _buildDateInput(),
          const SizedBox(height: 16),
          _ModeHeader(
            title: 'Échéance en kilométrage',
            absoluteLabel: 'À',
            mode: controller.mileageMode,
            onChanged: (mode) =>
                controller.setMileageMode(mode, referenceMileage),
          ),
          const SizedBox(height: 8),
          _buildMileageInput(),
          const SizedBox(height: 8),
          Text(
            'Renseigner une échéance en temps, en kilométrage, ou les deux. '
            'Les valeurs « dans » sont calculées à partir de $referenceLabel '
            '(${formatDate(referenceDate)}'
            '${referenceMileage != null ? ' · $referenceMileage km' : ''}).',
            style: captionStyle,
          ),
        ],
      ),
    );
  }

  Widget _buildDateInput() {
    if (controller.dateMode == DueInputMode.absolute) {
      return DatePickerField(
        label: 'Date prévue',
        value: controller.absoluteDate,
        onChanged: (value) => controller.absoluteDate = value,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
    }

    final dueDate = controller.resolveDueDate(referenceDate);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: controller.durationController,
            decoration: InputDecoration(
              labelText: 'Dans',
              helperText: dueDate != null
                  ? 'Soit le ${formatDate(dueDate)}'
                  : null,
            ),
            keyboardType: TextInputType.number,
            validator: _validatePositiveInt,
          ),
        ),
        const SizedBox(width: 12),
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: SegmentedButton<ScheduleIntervalUnit>(
            showSelectedIcon: false,
            segments: [
              for (final unit in ScheduleIntervalUnit.values)
                ButtonSegment(value: unit, label: Text(unit.label)),
            ],
            selected: {controller.unit},
            onSelectionChanged: (value) => controller.unit = value.first,
          ),
        ),
      ],
    );
  }

  Widget _buildMileageInput() {
    final isRelative = controller.mileageMode == DueInputMode.relative;
    final value = controller.mileageValue;
    final dueMileage = controller.resolveDueMileage(referenceMileage);

    final String? helper;
    if (value == null) {
      helper = referenceMileage != null
          ? 'Kilométrage actuel : $referenceMileage km'
          : null;
    } else if (isRelative) {
      helper = dueMileage != null
          ? 'Soit à $dueMileage km'
          : 'Kilométrage de référence inconnu';
    } else {
      helper = referenceMileage != null && value > referenceMileage!
          ? 'Soit dans ${value - referenceMileage!} km'
          : null;
    }

    return TextFormField(
      controller: controller.mileageController,
      decoration: InputDecoration(
        labelText: isRelative ? 'Dans' : 'Kilométrage prévu',
        suffixText: 'km',
        helperText: helper,
      ),
      keyboardType: TextInputType.number,
      validator: (text) {
        final error = _validatePositiveInt(text);
        if (error != null) return error;
        if (!controller.hasAnyDue) {
          return 'Indiquer une échéance en temps ou en kilométrage';
        }
        if (value != null && dueMileage == null) {
          return 'Kilométrage de référence inconnu';
        }
        return null;
      },
    );
  }
}

/// Titre d'une dimension d'échéance avec le choix « Dans » / valeur fixe.
class _ModeHeader extends StatelessWidget {
  const _ModeHeader({
    required this.title,
    required this.absoluteLabel,
    required this.mode,
    required this.onChanged,
  });

  final String title;
  final String absoluteLabel;
  final DueInputMode mode;
  final ValueChanged<DueInputMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.labelLarge),
        ),
        SegmentedButton<DueInputMode>(
          showSelectedIcon: false,
          style: const ButtonStyle(visualDensity: VisualDensity.compact),
          segments: [
            const ButtonSegment(
              value: DueInputMode.relative,
              label: Text('Dans'),
            ),
            ButtonSegment(
              value: DueInputMode.absolute,
              label: Text(absoluteLabel),
            ),
          ],
          selected: {mode},
          onSelectionChanged: (value) => onChanged(value.first),
        ),
      ],
    );
  }
}
