import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/result.dart';
import '../../models/vehicle/vehicle.dart';
import '../../models/vehicle/vehicle_category.dart';
import '../../models/vehicle/vehicle_energy.dart';
import '../../models/vehicle/vehicle_status.dart';
import '../../repositories/api_vehicle_repository.dart';
import '../home/home_providers.dart';
import 'vehicles_providers.dart';

/// Formulaire d'ajout ou de modification d'un véhicule. Mode édition si
/// [vehicleId] est fourni, sinon création.
class VehicleFormScreen extends ConsumerStatefulWidget {
  const VehicleFormScreen({super.key, this.vehicleId});

  final String? vehicleId;

  bool get isEditing => vehicleId != null;

  @override
  ConsumerState<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends ConsumerState<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _customNameController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _licensePlateController = TextEditingController();
  final _vinController = TextEditingController();
  final _fiscalPowerController = TextEditingController();
  final _powerHpController = TextEditingController();
  final _weightKgController = TextEditingController();
  final _colorController = TextEditingController();
  final _mileageController = TextEditingController(text: '0');
  final _commentController = TextEditingController();

  VehicleCategory _category = VehicleCategory.voiture;
  VehicleStatus _status = VehicleStatus.current;
  VehicleEnergy? _energy;
  DateTime? _firstRegistrationDate;

  Vehicle? _existing;
  bool _loading = false;
  bool _saving = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    if (widget.isEditing) {
      _loading = true;
      _loadVehicle();
    }
  }

  Future<void> _loadVehicle() async {
    final result = await ref
        .read(vehicleRepositoryProvider)
        .getVehicle(widget.vehicleId!);
    if (!mounted) return;

    switch (result) {
      case Success(:final data):
        _customNameController.text = data.customName;
        _brandController.text = data.brand;
        _modelController.text = data.model;
        _licensePlateController.text = data.licensePlate ?? '';
        _vinController.text = data.vin ?? '';
        _fiscalPowerController.text = data.fiscalPower?.toString() ?? '';
        _powerHpController.text = data.powerHp?.toString() ?? '';
        _weightKgController.text = data.weightKg?.toString() ?? '';
        _colorController.text = data.color ?? '';
        _mileageController.text = data.mileage.toString();
        _commentController.text = data.comment ?? '';
        setState(() {
          _existing = data;
          _category = data.category;
          _status = data.status;
          _energy = data.energy;
          _firstRegistrationDate = data.firstRegistrationDate;
          _loading = false;
        });
      case FailureResult(:final failure):
        setState(() {
          _loadError = failure.message;
          _loading = false;
        });
    }
  }

  @override
  void dispose() {
    _customNameController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _licensePlateController.dispose();
    _vinController.dispose();
    _fiscalPowerController.dispose();
    _powerHpController.dispose();
    _weightKgController.dispose();
    _colorController.dispose();
    _mileageController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  int? _parseIntOrNull(String value) =>
      value.trim().isEmpty ? null : int.tryParse(value.trim());

  String? _nullIfEmpty(String value) =>
      value.trim().isEmpty ? null : value.trim();

  Future<void> _pickFirstRegistrationDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _firstRegistrationDate ?? DateTime.now(),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _firstRegistrationDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    final vehicle = Vehicle(
      id: _existing?.id ?? '',
      customName: _customNameController.text.trim(),
      category: _category,
      status: _status,
      brand: _brandController.text.trim(),
      model: _modelController.text.trim(),
      licensePlate: _nullIfEmpty(_licensePlateController.text),
      vin: _nullIfEmpty(_vinController.text),
      firstRegistrationDate: _firstRegistrationDate,
      energy: _energy,
      fiscalPower: _parseIntOrNull(_fiscalPowerController.text),
      powerHp: _parseIntOrNull(_powerHpController.text),
      weightKg: _parseIntOrNull(_weightKgController.text),
      color: _nullIfEmpty(_colorController.text),
      mileage: int.tryParse(_mileageController.text.trim()) ?? 0,
      comment: _nullIfEmpty(_commentController.text),
      photoFilename: _existing?.photoFilename,
    );

    final repository = ref.read(vehicleRepositoryProvider);
    final result = widget.isEditing
        ? await repository.updateVehicle(vehicle)
        : await repository.createVehicle(vehicle);

    if (!mounted) return;
    setState(() => _saving = false);

    switch (result) {
      case Success():
        ref.invalidate(allVehiclesProvider);
        ref.invalidate(currentVehiclesProvider);
        ref.invalidate(upcomingRemindersProvider);
        if (widget.isEditing) {
          ref.invalidate(vehicleByIdProvider(vehicle.id));
        }
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
          widget.isEditing ? 'Modifier le véhicule' : 'Nouveau véhicule',
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
          ? Center(child: Text(_loadError!))
          : _buildForm(context),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: _customNameController,
            decoration: const InputDecoration(labelText: 'Nom personnalisé'),
            validator: (value) =>
                (value == null || value.trim().isEmpty) ? 'Requis' : null,
          ),
          const SizedBox(height: 16),
          SegmentedButton<VehicleCategory>(
            segments: [
              for (final category in VehicleCategory.values)
                ButtonSegment(value: category, label: Text(category.label)),
            ],
            selected: {_category},
            onSelectionChanged: (value) =>
                setState(() => _category = value.first),
          ),
          const SizedBox(height: 16),
          SegmentedButton<VehicleStatus>(
            segments: [
              for (final status in VehicleStatus.values)
                ButtonSegment(value: status, label: Text(status.label)),
            ],
            selected: {_status},
            onSelectionChanged: (value) =>
                setState(() => _status = value.first),
          ),
          const SizedBox(height: 24),
          Text('Carte grise', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          TextFormField(
            controller: _brandController,
            decoration: const InputDecoration(labelText: 'Marque'),
            validator: (value) =>
                (value == null || value.trim().isEmpty) ? 'Requis' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _modelController,
            decoration: const InputDecoration(labelText: 'Modèle'),
            validator: (value) =>
                (value == null || value.trim().isEmpty) ? 'Requis' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _licensePlateController,
            decoration: const InputDecoration(labelText: 'Immatriculation'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _vinController,
            decoration: const InputDecoration(labelText: 'VIN'),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Date de 1ère immatriculation'),
            subtitle: Text(
              _firstRegistrationDate == null
                  ? 'Non renseignée'
                  : '${_firstRegistrationDate!.day.toString().padLeft(2, '0')}/'
                        '${_firstRegistrationDate!.month.toString().padLeft(2, '0')}/'
                        '${_firstRegistrationDate!.year}',
            ),
            trailing: Wrap(
              spacing: 4,
              children: [
                if (_firstRegistrationDate != null)
                  IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () =>
                        setState(() => _firstRegistrationDate = null),
                  ),
                IconButton(
                  icon: const Icon(Icons.calendar_today_outlined),
                  onPressed: _pickFirstRegistrationDate,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<VehicleEnergy?>(
            initialValue: _energy,
            decoration: const InputDecoration(labelText: 'Énergie'),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Non renseignée'),
              ),
              for (final energy in VehicleEnergy.values)
                DropdownMenuItem(value: energy, child: Text(energy.label)),
            ],
            onChanged: (value) => setState(() => _energy = value),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _fiscalPowerController,
                  decoration: const InputDecoration(
                    labelText: 'Puissance fiscale (CV)',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _powerHpController,
                  decoration: const InputDecoration(
                    labelText: 'Puissance (CH)',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _weightKgController,
                  decoration: const InputDecoration(labelText: 'Poids (kg)'),
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: _colorController,
                  decoration: const InputDecoration(labelText: 'Couleur'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: _mileageController,
            decoration: const InputDecoration(labelText: 'Kilométrage'),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Requis';
              return int.tryParse(value.trim()) == null
                  ? 'Nombre invalide'
                  : null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _commentController,
            decoration: const InputDecoration(labelText: 'Commentaire'),
            maxLines: 3,
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }
}
