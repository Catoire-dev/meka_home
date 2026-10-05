import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/failure.dart';
import '../../core/network/result.dart';
import '../../core/utils/date_math.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/error_retry_view.dart';
import '../../core/widgets/form_submit_button.dart';
import '../../models/maintenance/maintenance_schedule.dart';
import '../../models/maintenance/maintenance_type.dart';
import '../../models/maintenance/schedule_interval.dart';
import '../../repositories/api_maintenance_repository.dart';
import '../vehicles/vehicles_providers.dart';
import 'maintenance_actions.dart';
import 'maintenance_providers.dart';
import 'widgets/maintenance_type_field.dart';
import 'widgets/schedule_due_controller.dart';
import 'widgets/schedule_due_fields.dart';

/// Formulaire d'ajout ou de modification d'une échéance d'entretien (date
/// et/ou kilométrage). Mode édition si [scheduleId] est fourni.
class ScheduleFormScreen extends ConsumerStatefulWidget {
  const ScheduleFormScreen({
    super.key,
    required this.vehicleId,
    this.scheduleId,
  });

  final String vehicleId;
  final String? scheduleId;

  bool get isEditing => scheduleId != null;

  @override
  ConsumerState<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends ConsumerState<ScheduleFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _due = ScheduleDueController();
  final _commentController = TextEditingController();

  int? _typeId;

  List<MaintenanceType> _types = const [];
  int? _vehicleMileage;
  MaintenanceSchedule? _existing;

  bool _loading = true;
  bool _saving = false;
  Failure? _loadError;

  /// Échéance modifiée dont au moins une valeur a été saisie en relatif.
  bool get _keepsStoredInterval =>
      _existing?.intervalMonths != null || _existing?.intervalMileage != null;

  /// Référence des valeurs « dans » : en modification d'une échéance saisie
  /// en relatif, la date / le kilométrage de sa planification (déduits de
  /// l'intervalle conservé), pour que l'échéance reste inchangée ;
  /// sinon aujourd'hui et le kilométrage actuel.
  DateTime get _referenceDate {
    final existing = _existing;
    final today = DateUtils.dateOnly(DateTime.now());
    if (existing?.dueDate case final dueDate?) {
      if (existing!.intervalMonths case final months?) {
        return addMonths(dueDate, -months);
      }
    }
    return today;
  }

  int? get _referenceMileage {
    final existing = _existing;
    if (existing?.dueMileage case final dueMileage?) {
      if (existing!.intervalMileage case final mileage?) {
        return dueMileage - mileage;
      }
    }
    return _vehicleMileage;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _due.dispose();
    _commentController.dispose();
    super.dispose();
  }

  /// Renvoie la donnée d'un [Result], ou `null` en cas d'échec. Un échec
  /// n'empêche l'affichage du formulaire que si la donnée est [required].
  Future<T?> _unwrap<T>(
    Future<Result<T>> future, {
    bool required = true,
  }) async {
    switch (await future) {
      case Success(:final data):
        return data;
      case FailureResult(:final failure):
        if (required) _loadError ??= failure;
        return null;
    }
  }

  void _retryLoad() {
    ref.invalidate(maintenanceTypesProvider);
    ref.invalidate(vehicleByIdProvider(widget.vehicleId));
    ref.invalidate(vehicleSchedulesProvider(widget.vehicleId));
    setState(() {
      _loading = true;
      _loadError = null;
    });
    _load();
  }

  Future<void> _load() async {
    final vehicleId = widget.vehicleId;
    final types = await _unwrap(ref.read(maintenanceTypesProvider.future));
    // Le véhicule ne sert qu'à afficher/pré-remplir le kilométrage actuel.
    final vehicle = await _unwrap(
      ref.read(vehicleByIdProvider(vehicleId).future),
      required: false,
    );

    MaintenanceSchedule? existing;
    if (widget.isEditing) {
      final schedules = await _unwrap(
        ref.read(vehicleSchedulesProvider(vehicleId).future),
      );
      existing = schedules?.where((s) => s.id == widget.scheduleId).firstOrNull;
      if (schedules != null && existing == null) {
        _loadError ??= const NotFoundFailure('Échéance introuvable.');
      }
    }
    if (!mounted) return;

    setState(() {
      _loading = false;
      if (_loadError != null) return;
      _types = types!;
      _vehicleMileage = vehicle?.mileage;
      if (existing != null) {
        _existing = existing;
        _typeId = existing.maintenanceTypeId;
        _due.reset(
          dueDate: existing.dueDate,
          dueMileage: existing.dueMileage,
          interval: ScheduleInterval(
            months: existing.dueDate != null ? existing.intervalMonths : null,
            mileage: existing.dueMileage != null
                ? existing.intervalMileage
                : null,
          ),
        );
        _commentController.text = existing.comment ?? '';
      }
    });
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final comment = _commentController.text.trim();
    final interval = _due.relativeInterval;
    final existing = _existing;
    // Un intervalle relatif inchangé conserve l'échéance d'origine (évite
    // un décalage d'arrondi en fin de mois).
    final dueDate =
        existing != null &&
            interval.months != null &&
            interval.months == existing.intervalMonths
        ? existing.dueDate
        : _due.resolveDueDate(_referenceDate);
    final dueMileage = _due.resolveDueMileage(_referenceMileage);
    final schedule = MaintenanceSchedule(
      id: _existing?.id ?? '',
      vehicleId: widget.vehicleId,
      maintenanceTypeId: _typeId!,
      dueDate: dueDate,
      dueMileage: dueMileage,
      lastMaintenanceId: existing?.lastMaintenanceId,
      comment: comment.isEmpty ? null : comment,
      intervalMonths:
          interval.months ??
          (existing != null && dueDate == existing.dueDate
              ? existing.intervalMonths
              : null),
      intervalMileage:
          interval.mileage ??
          (existing != null && dueMileage == existing.dueMileage
              ? existing.intervalMileage
              : null),
    );

    final result = await ref
        .read(maintenanceActionsProvider)
        .saveSchedule(schedule);

    if (!mounted) return;
    setState(() => _saving = false);

    switch (result) {
      case Success():
        Navigator.of(context).pop();
      case FailureResult(:final failure):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  Future<void> _delete() async {
    final schedule = _existing;
    if (schedule == null) return;
    final confirmed = await showConfirmDialog(
      context,
      title: "Supprimer l'échéance ?",
      message: 'Cette échéance ne sera plus suivie.',
    );
    if (!confirmed || !mounted) return;

    setState(() => _saving = true);
    final result = await ref
        .read(maintenanceActionsProvider)
        .deleteSchedule(schedule);
    if (!mounted) return;
    setState(() => _saving = false);

    switch (result) {
      case Success():
        Navigator.of(context).pop();
      case FailureResult(:final failure):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing ? "Modifier l'échéance" : 'Nouvelle échéance',
        ),
        actions: [
          if (_existing != null)
            IconButton(
              tooltip: 'Supprimer',
              icon: const Icon(Icons.delete_outline),
              onPressed: _saving ? null : _delete,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? ErrorRetryView(failure: _loadError!, onRetry: _retryLoad)
          : _buildForm(context),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          MaintenanceTypeField(
            types: _types,
            value: _typeId,
            onChanged: (value) => setState(() => _typeId = value),
          ),
          const SizedBox(height: 12),
          ScheduleDueFields(
            controller: _due,
            referenceDate: _referenceDate,
            referenceMileage: _referenceMileage,
            referenceLabel: _keepsStoredInterval
                ? 'la planification'
                : "aujourd'hui",
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _commentController,
            decoration: const InputDecoration(labelText: 'Commentaire'),
            maxLines: 2,
          ),
          const SizedBox(height: 24),
          FormSubmitButton(saving: _saving, onPressed: _submit),
        ],
      ),
    );
  }
}
