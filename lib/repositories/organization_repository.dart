import '../core/network/result.dart';
import '../models/organization/organization.dart';
import '../models/organization/organization_type.dart';

/// Contrat d'accès aux organisations (garages / intervenants), indépendant
/// du backend qui l'implémente.
abstract interface class OrganizationRepository {
  Future<Result<List<OrganizationType>>> getOrganizationTypes();

  Future<Result<List<Organization>>> getOrganizations();

  /// Enregistre aussi l'adresse portée par [organization], le cas échéant.
  Future<Result<Organization>> createOrganization(Organization organization);

  /// Enregistre aussi l'adresse portée par [organization], le cas échéant.
  Future<Result<Organization>> updateOrganization(Organization organization);
  Future<Result<void>> deleteOrganization(String id);
}
