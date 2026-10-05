import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/failure.dart';
import '../../core/network/result.dart';
import '../../core/utils/number_format.dart';
import '../../core/widgets/date_picker_field.dart';
import '../../core/widgets/error_retry_view.dart';
import '../../core/widgets/form_submit_button.dart';
import '../../models/maintenance/maintenance.dart';
import '../../models/maintenance/maintenance_schedule.dart';
import '../../models/maintenance/maintenance_type.dart';
import '../../models/maintenance/schedule_interval.dart';
import '../../models/organization/organization.dart';
import '../../models/vehicle/vehicle_category.dart';
import '../../repositories/api_maintenance_repository.dart';
import '../../repositories/api_organization_repository.dart';
import '../vehicles/vehicles_providers.dart';
import 'maintenance_actions.dart';
import 'maintenance_providers.dart';
import 'widgets/maintenance_type_field.dart';
import 'widgets/next_schedule_fields.dart';
import 'widgets/organization_field.dart';
import 'widgets/schedule_due_controller.dart';

/// Formulaire d'ajout ou de modification d'une intervention. Mode édition
/// si [maintenanceId] est fourni. En création, [fromScheduleId] indique
/// l'échéance validée (« marquer comme réalisée ») : son type et son
/// kilométrage prévu pré-remplissent le formulaire, et c'est elle qui est
/// replanifiée.
class MaintenanceFormScreen extends ConsumerStatefulWidget {
  const MaintenanceFormScreen({
    super.key,
    required this.vehicleId,
    this.maintenanceId,
    this.fromScheduleId,
  });

  final String vehicleId;
  final String? maintenanceId;
  final String? fromScheduleId;

  bool get isEditing => maintenanceId != null;

  @override
  ConsumerState<MaintenanceFormScreen> createState() =>
      _MaintenanceFormScreenState();
}

class _MaintenanceFormScreenState extends ConsumerState<MaintenanceFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _mileageController = TextEditingController();
  final _costController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _commentController = TextEditingController();
  final _nextDue = ScheduleDueController();

  int? _typeId;
  String? _organizationId;
  DateTime _date = DateUtils.dateOnly(DateTime.now());

  bool _planNext = false;
  MaintenanceSchedule? _matchingSchedule;

  List<MaintenanceType> _types = const [];
  List<Organization> _organizations = const [];
  VehicleCategory? _vehicleCategory;
  List<MaintenanceSchedule> _schedules = const [];
  List<Maintenance> _maintenances = const [];
  int? _vehicleMileage;
  Maintenance? _existing;

  bool _loading = true;
  bool _saving = false;
  Failure? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _mileageController.dispose();
    _costController.dispose();
    _descriptionController.dispose();
    _commentController.dispose();
    _nextDue.dispose();
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
    ref.invalidate(organizationsProvider);
    ref.invalidate(vehicleByIdProvider(widget.vehicleId));
    ref.invalidate(vehicleSchedulesProvider(widget.vehicleId));
    ref.invalidate(vehicleMaintenancesProvider(widget.vehicleId));
    setState(() {
      _loading = true;
      _loadError = null;
    });
    _load();
  }

  Future<void> _load() async {
    final vehicleId = widget.vehicleId;
    final types = await _unwrap(ref.read(maintenanceTypesProvider.future));
    final organizations = await _unwrap(ref.read(organizationsProvider.future));
    // Le véhicule ne sert qu'à pré-remplir le kilométrage actuel et à
    // filtrer les garages par catégorie.
    final vehicle = await _unwrap(
      ref.read(vehicleByIdProvider(vehicleId).future),
      required: false,
    );
    // Les échéances ne servent qu'à proposer la replanification.
    final schedules = await _unwrap(
      ref.read(vehicleSchedulesProvider(vehicleId).future),
      required: false,
    );

    // Requis en modification ; en création, ne sert qu'à retrouver
    // l'intervalle de l'échéance replanifiée.
    final maintenances = await _unwrap(
      ref.read(vehicleMaintenancesProvider(vehicleId).future),
      required: widget.isEditing,
    );

    Maintenance? existing;
    if (widget.isEditing) {
      existing = maintenances
          ?.where((m) => m.id == widget.maintenanceId)
          .firstOrNull;
      if (maintenances != null && existing == null) {
        _loadError ??= const NotFoundFailure('Intervention introuvable.');
      }
    }
    if (!mounted) return;

    setState(() {
      _loading = false;
      if (_loadError != null) return;
      _types = types!;
      _organizations = organizations!;
      _vehicleCategory = vehicle?.category;
      _schedules = schedules ?? const [];
      _maintenances = maintenances ?? const [];
      _vehicleMileage = vehicle?.mileage;

      if (existing != null) {
        _existing = existing;
        _typeId = existing.maintenanceTypeId;
        _organizationId = existing.organizationId;
        _date = existing.date;
        _mileageController.text = existing.mileage?.toString() ?? '';
        _costController.text =
            existing.cost?.toStringAsFixed(2).replaceAll('.', ',') ?? '';
        _descriptionController.text = existing.description ?? '';
        _commentController.text = existing.comment ?? '';
      } else {
        // Validation d'une échéance : l'intervention reprend son type et le
        // kilométrage auquel elle était prévue, plutôt que celui de la fiche.
        final fromSchedule = _schedules
            .where((s) => s.id == widget.fromScheduleId)
            .firstOrNull;
        _mileageController.text =
            (fromSchedule?.dueMileage ?? vehicle?.mileage)?.toString() ?? '';
        _selectType(fromSchedule?.maintenanceTypeId, schedule: fromSchedule);
      }
    });
  }

  /// Sélectionne le type et, en création, propose de replanifier
  /// [schedule] ou, à défaut, l'échéance existante de ce type, pré-remplie
  /// avec le même intervalle que la précédente.
  void _selectType(int? typeId, {MaintenanceSchedule? schedule}) {
    _typeId = _types.any((t) => t.id == typeId) ? typeId : null;
    if (widget.isEditing) return;
    _matchingSchedule =
        schedule ??
        _schedules.where((s) => s.maintenanceTypeId == _typeId).firstOrNull;
    _planNext = _matchingSchedule != null;
    _nextDue.prefill(
      _matchingSchedule != null
          ? ScheduleInterval.ofSchedule(_matchingSchedule!, _maintenances)
          : const ScheduleInterval(),
    );
  }

  /// Garages proposés : non archivés et prenant en charge la catégorie du
  /// véhicule, plus celui déjà sélectionné (même archivé) en modification.
  List<Organization> get _availableOrganizations => [
    for (final organization in _organizations)
      if (organization.id == _organizationId ||
          (!organization.isArchived &&
              (_vehicleCategory == null ||
                  organization.handles(_vehicleCategory!))))
        organization,
  ];

  /// Ouvre la création d'un garage puis le sélectionne au retour.
  Future<void> _createOrganization() async {
    final created = await context.push<Organization>('/garages/new');
    if (created == null || !mounted) return;
    final organizations = await _unwrap(
      ref.read(organizationsProvider.future),
      required: false,
    );
    if (!mounted) return;
    setState(() {
      _organizations = organizations ?? [..._organizations, created];
      _organizationId = created.id;
    });
  }

  String? _nullIfEmpty(String value) =>
      value.trim().isEmpty ? null : value.trim();

  /// Kilométrage de l'intervention, à défaut celui du véhicule : base de
  /// calcul de la prochaine échéance.
  int? get _referenceMileage =>
      parseUserInt(_mileageController.text) ?? _vehicleMileage;

  MaintenanceSchedule? _buildNextSchedule() {
    if (widget.isEditing || !_planNext) return null;
    return MaintenanceSchedule(
      id: _matchingSchedule?.id ?? '',
      vehicleId: widget.vehicleId,
      maintenanceTypeId: _typeId!,
      dueDate: _nextDue.resolveDueDate(_date),
      dueMileage: _nextDue.resolveDueMileage(_referenceMileage),
      comment: _matchingSchedule?.comment,
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    final maintenance = Maintenance(
      id: _existing?.id ?? '',
      vehicleId: widget.vehicleId,
      maintenanceTypeId: _typeId!,
      date: _date,
      organizationId: _organizationId!,
      mileage: parseUserInt(_mileageController.text),
      description: _nullIfEmpty(_descriptionController.text),
      cost: parseUserDouble(_costController.text),
      comment: _nullIfEmpty(_commentController.text),
    );

    final outcome = await ref
        .read(maintenanceActionsProvider)
        .saveMaintenance(maintenance, nextSchedule: _buildNextSchedule());

    if (!mounted) return;
    setState(() => _saving = false);
    final messenger = ScaffoldMessenger.of(context);

    switch (outcome.maintenance) {
      case Success():
        Navigator.of(context).pop();
        if (outcome.warnings.isNotEmpty) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                'Intervention enregistrée. ${outcome.warnings.join(' ')}',
              ),
            ),
          );
        }
      case FailureResult(:final failure):
        messenger.showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isEditing
              ? "Modifier l'intervention"
              : 'Nouvelle intervention',
        ),
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
            onChanged: (value) => setState(() => _selectType(value)),
          ),
          const SizedBox(height: 12),
          DatePickerField(
            label: "Date de l'intervention",
            value: _date,
            onChanged: (value) {
              if (value != null) setState(() => _date = value);
            },
            firstDate: DateTime(1950),
            lastDate: DateTime.now(),
            clearable: false,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: _mileageController,
                  decoration: const InputDecoration(
                    labelText: 'Kilométrage',
                    suffixText: 'km',
                    helperText: 'Met à jour le véhicule si supérieur',
                    helperMaxLines: 2,
                  ),
                  keyboardType: TextInputType.number,
                  // L'aperçu de la prochaine échéance en dépend.
                  onChanged: (_) => setState(() {}),
                  validator: (value) =>
                      (value ?? '').trim().isNotEmpty &&
                          parseUserInt(value!) == null
                      ? 'Nombre invalide'
                      : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _costController,
                  decoration: const InputDecoration(
                    labelText: 'Coût',
                    suffixText: '€',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: (value) =>
                      (value ?? '').trim().isNotEmpty &&
                          parseUserDouble(value!) == null
                      ? 'Montant invalide'
                      : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OrganizationField(
            organizations: _availableOrganizations,
            value: _organizationId,
            onChanged: (value) => setState(() => _organizationId = value),
            onCreate: _createOrganization,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(labelText: 'Description'),
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _commentController,
            decoration: const InputDecoration(labelText: 'Commentaire'),
            maxLines: 2,
          ),
          if (!widget.isEditing && _typeId != null) ...[
            const SizedBox(height: 16),
            NextScheduleFields(
              enabled: _planNext,
              onEnabledChanged: (value) => setState(() => _planNext = value),
              controller: _nextDue,
              referenceDate: _date,
              referenceMileage: _referenceMileage,
              replacedSchedule: _matchingSchedule,
            ),
          ],
          const SizedBox(height: 24),
          FormSubmitButton(saving: _saving, onPressed: _submit),
        ],
      ),
    );
  }
}
