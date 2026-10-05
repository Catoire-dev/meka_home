import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/result.dart';
import '../../models/organization/organization.dart';
import '../../repositories/api_organization_repository.dart';
import '../../repositories/organization_repository.dart';

final organizationActionsProvider = Provider<OrganizationActions>(
  OrganizationActions.new,
);

/// Opérations d'écriture sur les organisations : délègue au repository puis
/// invalide la liste partagée (écran « Mes garages » et entretiens).
class OrganizationActions {
  OrganizationActions(this._ref);

  final Ref _ref;

  OrganizationRepository get _repository =>
      _ref.read(organizationRepositoryProvider);

  /// Crée ([Organization.id] vide) ou met à jour une organisation.
  Future<Result<Organization>> save(Organization organization) async {
    final result = organization.id.isEmpty
        ? await _repository.createOrganization(organization)
        : await _repository.updateOrganization(organization);
    if (result is Success<Organization>) _ref.invalidate(organizationsProvider);
    return result;
  }

  /// Échoue côté backend si des interventions y font référence : archiver
  /// l'organisation est alors l'alternative.
  Future<Result<void>> delete(Organization organization) async {
    final result = await _repository.deleteOrganization(organization.id);
    if (result is Success<void>) _ref.invalidate(organizationsProvider);
    return result;
  }
}
