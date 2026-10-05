import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/failure.dart';
import '../../core/network/result.dart';
import '../../core/widgets/empty_hint.dart';
import '../../core/widgets/error_retry_view.dart';
import '../../models/organization/organization.dart';
import '../../repositories/api_organization_repository.dart';
import 'widgets/organization_card.dart';

/// Écran « Mes garages » : liste des organisations (garages, intervenants,
/// « Moi-même »), archivées masquées par défaut.
class OrganizationsScreen extends ConsumerStatefulWidget {
  const OrganizationsScreen({super.key});

  @override
  ConsumerState<OrganizationsScreen> createState() =>
      _OrganizationsScreenState();
}

class _OrganizationsScreenState extends ConsumerState<OrganizationsScreen> {
  bool _showArchived = false;

  @override
  Widget build(BuildContext context) {
    final organizationsAsync = ref.watch(organizationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes garages'),
        actions: [
          IconButton(
            tooltip: _showArchived
                ? 'Masquer les archivés'
                : 'Afficher les archivés',
            isSelected: _showArchived,
            icon: const Icon(Icons.inventory_2_outlined),
            selectedIcon: const Icon(Icons.inventory_2),
            onPressed: () => setState(() => _showArchived = !_showArchived),
          ),
          IconButton(
            tooltip: 'Recharger',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(organizationsProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Nouveau garage',
        onPressed: () => context.push('/garages/new'),
        child: const Icon(Icons.add),
      ),
      body: organizationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ErrorRetryView(
          failure: UnknownFailure('$error'),
          onRetry: () => ref.invalidate(organizationsProvider),
        ),
        data: (result) => switch (result) {
          FailureResult(:final failure) => ErrorRetryView(
            failure: failure,
            onRetry: () => ref.invalidate(organizationsProvider),
          ),
          Success(:final data) => _OrganizationsList(
            organizations: _showArchived
                ? data
                : data.where((o) => !o.isArchived).toList(),
          ),
        },
      ),
    );
  }
}

class _OrganizationsList extends StatelessWidget {
  const _OrganizationsList({required this.organizations});

  final List<Organization> organizations;

  @override
  Widget build(BuildContext context) {
    if (organizations.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: EmptyHint('Aucun garage enregistré.'),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: organizations.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final organization = organizations[index];
        return OrganizationCard(
          organization: organization,
          onTap: () => context.push('/garages/${organization.id}/edit'),
        );
      },
    );
  }
}
