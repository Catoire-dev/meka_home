import 'package:flutter/material.dart';

import '../../../core/utils/date_format.dart';
import '../../../models/maintenance/maintenance_schedule.dart';
import 'schedule_due_controller.dart';
import 'schedule_due_fields.dart';

/// Section « Prochaine échéance » du formulaire d'intervention : permet de
/// planifier (ou replanifier) l'échéance suivante du même type dans la
/// foulée de l'intervention, relativement à sa date et son kilométrage.
class NextScheduleFields extends StatelessWidget {
  const NextScheduleFields({
    super.key,
    required this.enabled,
    required this.onEnabledChanged,
    required this.controller,
    required this.referenceDate,
    required this.referenceMileage,
    this.replacedSchedule,
  });

  final bool enabled;
  final ValueChanged<bool> onEnabledChanged;
  final ScheduleDueController controller;
  final DateTime referenceDate;
  final int? referenceMileage;

  /// Échéance existante du même type, qui sera mise à jour.
  final MaintenanceSchedule? replacedSchedule;

  String? get _replacedLabel {
    final schedule = replacedSchedule;
    if (schedule == null) return null;
    final due = [
      if (schedule.dueDate != null) formatDate(schedule.dueDate!),
      if (schedule.dueMileage != null) '${schedule.dueMileage} km',
    ].join(' · ');
    return due.isEmpty
        ? "Remplace l'échéance actuelle de ce type."
        : "Remplace l'échéance actuelle de ce type ($due).";
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Planifier la prochaine échéance'),
          subtitle: _replacedLabel != null ? Text(_replacedLabel!) : null,
          value: enabled,
          onChanged: onEnabledChanged,
        ),
        if (enabled)
          ScheduleDueFields(
            controller: controller,
            referenceDate: referenceDate,
            referenceMileage: referenceMileage,
            referenceLabel: "l'intervention",
          ),
      ],
    );
  }
}
