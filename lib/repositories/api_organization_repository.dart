import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/network/api_client.dart';
import '../core/network/api_guard.dart';
import '../core/network/result.dart';
import '../core/network/sticky_result_provider.dart';
import '../models/organization/address.dart';
import '../models/organization/organization.dart';
import '../models/organization/organization_type.dart';
import '../services/api/organization_api_service.dart';
import 'organization_repository.dart';

final organizationRepositoryProvider = Provider<OrganizationRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ApiOrganizationRepository(OrganizationApiService(client), client);
});

/// Liste de référence des types d'organisation.
final organizationTypesProvider = stickyResultProvider<List<OrganizationType>>(
  (ref) => ref.watch(organizationRepositoryProvider).getOrganizationTypes(),
);

/// Liste de référence des organisations (archivées comprises), partagée
/// par l'écran « Mes garages » et les écrans d'entretien. « Moi-même » en
/// premier, puis par nom.
final organizationsProvider = stickyResultProvider<List<Organization>>((
  ref,
) async {
  final result = await ref
      .watch(organizationRepositoryProvider)
      .getOrganizations();
  return switch (result) {
    Success(:final data) => Result.success(
      data.toList()..sort(
        (a, b) => a.isMine != b.isMine
            ? (a.isMine ? -1 : 1)
            : a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      ),
    ),
    FailureResult(:final failure) => Result.failure(failure),
  };
});

class ApiOrganizationRepository implements OrganizationRepository {
  ApiOrganizationRepository(this._service, this._client);

  final OrganizationApiService _service;
  final ApiClient _client;

  @override
  Future<Result<List<OrganizationType>>> getOrganizationTypes() =>
      apiGuard(_client, () async {
        final json = await _service.fetchOrganizationTypes();
        return json
            .map((e) => OrganizationType.fromJson(e as Map<String, dynamic>))
            .toList();
      });

  @override
  Future<Result<List<Organization>>> getOrganizations() =>
      apiGuard(_client, () async {
        final json = await _service.fetchOrganizations();
        return json
            .map((e) => Organization.fromJson(e as Map<String, dynamic>))
            .toList();
      });

  @override
  Future<Result<Organization>> createOrganization(Organization organization) =>
      apiGuard(_client, () async {
        final saved = await _withSavedAddress(organization);
        final json = await _service.createOrganization(
          saved.toJson()..remove('id'),
        );
        return Organization.fromJson(json);
      });

  @override
  Future<Result<Organization>> updateOrganization(Organization organization) =>
      apiGuard(_client, () async {
        final saved = await _withSavedAddress(organization);
        final json = await _service.updateOrganization(
          saved.id,
          saved.toJson(),
        );
        return Organization.fromJson(json);
      });

  @override
  Future<Result<void>> deleteOrganization(String id) =>
      apiGuard(_client, () => _service.deleteOrganization(id));

  /// Le backend référence l'adresse par `address_id` : elle est créée (ou
  /// mise à jour) d'abord, puis rattachée à l'organisation.
  Future<Organization> _withSavedAddress(Organization organization) async {
    final address = organization.address;
    if (address == null) return organization;
    final json = address.id.isEmpty
        ? await _service.createAddress(address.toJson())
        : await _service.updateAddress(address.id, address.toJson());
    return organization.copyWith(address: Address.fromJson(json));
  }
}
