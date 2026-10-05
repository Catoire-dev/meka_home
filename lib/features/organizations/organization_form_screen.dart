import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/failure.dart';
import '../../core/network/result.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/error_retry_view.dart';
import '../../core/widgets/form_submit_button.dart';
import '../../models/organization/address.dart';
import '../../models/organization/organization.dart';
import '../../models/organization/organization_type.dart';
import '../../models/vehicle/vehicle_category.dart';
import '../../repositories/api_organization_repository.dart';
import '../../repositories/api_vehicle_repository.dart';
import 'organization_actions.dart';
import 'widgets/vehicle_categories_field.dart';

/// Formulaire d'ajout ou de modification d'une organisation. Mode édition
/// si [organizationId] est fourni. À l'enregistrement, l'écran se ferme en
/// renvoyant l'[Organization] enregistrée (pour pré-sélection par
/// l'appelant).
class OrganizationFormScreen extends ConsumerStatefulWidget {
  const OrganizationFormScreen({super.key, this.organizationId});

  final String? organizationId;

  bool get isEditing => organizationId != null;

  @override
  ConsumerState<OrganizationFormScreen> createState() =>
      _OrganizationFormScreenState();
}

class _OrganizationFormScreenState
    extends ConsumerState<OrganizationFormScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _mobileController = TextEditingController();
  final _websiteController = TextEditingController();
  final _streetController = TextEditingController();
  final _complementController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _cityController = TextEditingController();
  final _commentController = TextEditingController();

  List<OrganizationType> _types = const [];
  List<VehicleCategory> _availableCategories = const [];
  int? _typeId;
  Set<VehicleCategory> _categories = {};
  bool _isMine = false;
  bool _isArchived = false;

  Organization? _existing;
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
    _nameController.dispose();
    _phoneController.dispose();
    _mobileController.dispose();
    _websiteController.dispose();
    _streetController.dispose();
    _complementController.dispose();
    _postalCodeController.dispose();
    _cityController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _retryLoad() {
    ref.invalidate(organizationsProvider);
    ref.invalidate(organizationTypesProvider);
    ref.invalidate(vehicleCategoriesProvider);
    setState(() {
      _loading = true;
      _loadError = null;
    });
    _load();
  }

  /// Renvoie la donnée d'un [Result], ou `null` (échec mémorisé).
  Future<T?> _unwrap<T>(Future<Result<T>> future) async {
    switch (await future) {
      case Success(:final data):
        return data;
      case FailureResult(:final failure):
        _loadError ??= failure;
        return null;
    }
  }

  Future<void> _load() async {
    final types = await _unwrap(ref.read(organizationTypesProvider.future));
    final categories = await _unwrap(
      ref.read(vehicleCategoriesProvider.future),
    );
    final organizations = widget.isEditing
        ? await _unwrap(ref.read(organizationsProvider.future))
        : null;
    if (!mounted) return;

    setState(() {
      _loading = false;
      if (_loadError != null) return;
      _types = types!;
      _availableCategories = categories!;
      _typeId = _types.firstOrNull?.id;
      if (organizations == null) return;

      final existing = organizations
          .where((o) => o.id == widget.organizationId)
          .firstOrNull;
      if (existing == null) {
        _loadError = const NotFoundFailure('Garage introuvable.');
        return;
      }
      _existing = existing;
      _nameController.text = existing.name;
      _phoneController.text = existing.phone ?? '';
      _mobileController.text = existing.mobile ?? '';
      _websiteController.text = existing.website ?? '';
      _streetController.text = existing.address?.street ?? '';
      _complementController.text = existing.address?.complement ?? '';
      _postalCodeController.text = existing.address?.postalCode ?? '';
      _cityController.text = existing.address?.city ?? '';
      _commentController.text = existing.comment ?? '';
      _typeId = existing.type?.id;
      _categories = existing.categories.toSet();
      _isMine = existing.isMine;
      _isArchived = existing.isArchived;
    });
  }

  String? _nullIfEmpty(String value) =>
      value.trim().isEmpty ? null : value.trim();

  bool get _hasAddressInput => [
    _streetController,
    _complementController,
    _postalCodeController,
    _cityController,
  ].any((controller) => controller.text.trim().isNotEmpty);

  /// Adresse saisie, en conservant l'identifiant et les champs non éditables
  /// (région, pays, coordonnées) de l'adresse existante. `null` si vide.
  Address? _buildAddress() {
    if (!_hasAddressInput) return null;
    final street = _streetController.text.trim();
    final complement = _nullIfEmpty(_complementController.text);
    final postalCode = _postalCodeController.text.trim();
    final city = _cityController.text.trim();
    return _existing?.address?.copyWith(
          street: street,
          complement: complement,
          postalCode: postalCode,
          city: city,
        ) ??
        Address(
          street: street,
          complement: complement,
          postalCode: postalCode,
          city: city,
        );
  }

  /// Rue, code postal et ville sont requis dès qu'une adresse est saisie.
  String? _validateAddressPart(String? value) =>
      _hasAddressInput && (value ?? '').trim().isEmpty ? 'Requis' : null;

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);

    // « Moi-même » n'a ni type, ni coordonnées, ni restriction de catégorie.
    final organization = Organization(
      id: _existing?.id ?? '',
      name: _nameController.text.trim(),
      type: _isMine
          ? null
          : _types.where((type) => type.id == _typeId).firstOrNull,
      phone: _isMine ? null : _nullIfEmpty(_phoneController.text),
      mobile: _isMine ? null : _nullIfEmpty(_mobileController.text),
      website: _isMine ? null : _nullIfEmpty(_websiteController.text),
      address: _isMine ? null : _buildAddress(),
      comment: _nullIfEmpty(_commentController.text),
      categories: _isMine
          ? const []
          : [
              for (final category in _availableCategories)
                if (_categories.contains(category)) category,
            ],
      isArchived: _isArchived,
      isMine: _isMine,
    );

    final result = await ref
        .read(organizationActionsProvider)
        .save(organization);
    if (!mounted) return;
    setState(() => _saving = false);

    switch (result) {
      case Success(:final data):
        Navigator.of(context).pop(data);
      case FailureResult(:final failure):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  Future<void> _delete() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Supprimer le garage ?',
      message:
          "Impossible s'il est lié à des interventions : archivez-le "
          'plutôt pour le masquer des listes.',
    );
    if (!confirmed || !mounted) return;

    final result = await ref
        .read(organizationActionsProvider)
        .delete(_existing!);
    if (!mounted) return;
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
        title: Text(widget.isEditing ? 'Modifier le garage' : 'Nouveau garage'),
        actions: [
          if (_existing != null)
            IconButton(
              tooltip: 'Supprimer',
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
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
    final sectionStyle = Theme.of(context).textTheme.titleSmall;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Moi-même'),
            subtitle: const Text('Pour les entretiens réalisés soi-même'),
            value: _isMine,
            onChanged: (value) => setState(() => _isMine = value),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Nom'),
            validator: (value) =>
                (value == null || value.trim().isEmpty) ? 'Requis' : null,
          ),
          if (!_isMine) ...[
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _typeId,
              decoration: const InputDecoration(labelText: 'Type'),
              items: [
                for (final type in _types)
                  DropdownMenuItem(value: type.id, child: Text(type.name)),
              ],
              onChanged: (value) => setState(() => _typeId = value),
              validator: (value) => value == null ? 'Requis' : null,
            ),
            const SizedBox(height: 16),
            VehicleCategoriesField(
              title: 'Véhicules pris en charge',
              categories: _availableCategories,
              value: _categories,
              onChanged: (value) => setState(() => _categories = value),
            ),
            const SizedBox(height: 16),
            Text('Contact', style: sectionStyle),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(labelText: 'Téléphone'),
                    keyboardType: TextInputType.phone,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _mobileController,
                    decoration: const InputDecoration(labelText: 'Mobile'),
                    keyboardType: TextInputType.phone,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _websiteController,
              decoration: const InputDecoration(labelText: 'Site web'),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 24),
            Text('Adresse', style: sectionStyle),
            const SizedBox(height: 8),
            TextFormField(
              controller: _streetController,
              decoration: const InputDecoration(labelText: 'Rue'),
              validator: _validateAddressPart,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _complementController,
              decoration: const InputDecoration(labelText: 'Complément'),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 120,
                  child: TextFormField(
                    controller: _postalCodeController,
                    decoration: const InputDecoration(labelText: 'Code postal'),
                    keyboardType: TextInputType.number,
                    validator: _validateAddressPart,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(labelText: 'Ville'),
                    validator: _validateAddressPart,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          TextFormField(
            controller: _commentController,
            decoration: const InputDecoration(labelText: 'Commentaire'),
            maxLines: 3,
          ),
          if (widget.isEditing) ...[
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Archivé'),
              subtitle: const Text(
                "N'est plus proposé lors de la saisie d'un entretien",
              ),
              value: _isArchived,
              onChanged: (value) => setState(() => _isArchived = value),
            ),
          ],
          const SizedBox(height: 24),
          FormSubmitButton(saving: _saving, onPressed: _submit),
        ],
      ),
    );
  }
}
