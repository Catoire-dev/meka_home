import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/failure.dart';
import '../../core/network/result.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/empty_hint.dart';
import '../../core/widgets/error_retry_view.dart';
import '../../core/widgets/info_row.dart';
import '../../models/organization/organization.dart';
import '../../repositories/api_organization_repository.dart';
import 'organization_actions.dart';
import 'organization_archive.dart';
import 'widgets/organization_avatar.dart';

/// Fiche d'une organisation (garage / intervenant) en lecture, avec accès à
/// la modification et à l'archivage. La suppression n'est proposée qu'une
/// fois le garage archivé.
class OrganizationDetailScreen extends ConsumerWidget {
  const OrganizationDetailScreen({super.key, required this.organizationId});

  final String organizationId;

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Organization organization,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Supprimer le garage ?',
      message:
          'Le garage sera définitivement supprimé. Impossible s\'il est '
          'lié à des interventions : il restera alors archivé.',
    );
    if (!confirmed || !context.mounted) return;

    final result = await ref
        .read(organizationActionsProvider)
        .delete(organization);
    if (!context.mounted) return;

    switch (result) {
      case Success():
        context.pop();
      case FailureResult(:final failure):
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organizationsAsync = ref.watch(organizationsProvider);
    final organization = switch (organizationsAsync.value) {
      Success(:final data) =>
        data.where((o) => o.id == organizationId).firstOrNull,
      _ => null,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(organization?.name ?? 'Garage'),
        actions: [
          IconButton(
            tooltip: 'Recharger',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(organizationsProvider),
          ),
          if (organization != null) ...[
            IconButton(
              tooltip: 'Modifier',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push('/garages/$organizationId/edit'),
            ),
            if (organization.isArchived) ...[
              IconButton(
                tooltip: 'Désarchiver',
                icon: const Icon(Icons.unarchive_outlined),
                onPressed: () => setOrganizationArchived(
                  context,
                  ref,
                  organization,
                  archived: false,
                ),
              ),
              IconButton(
                tooltip: 'Supprimer',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _delete(context, ref, organization),
              ),
            ] else
              IconButton(
                tooltip: 'Archiver',
                icon: const Icon(Icons.archive_outlined),
                onPressed: () => setOrganizationArchived(
                  context,
                  ref,
                  organization,
                  archived: true,
                ),
              ),
          ],
        ],
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
          Success() when organization == null => const Center(
            child: Text('Garage introuvable.'),
          ),
          Success() => _OrganizationDetailBody(organization: organization!),
        },
      ),
    );
  }
}

class _OrganizationDetailBody extends StatelessWidget {
  const _OrganizationDetailBody({required this.organization});

  final Organization organization;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _HeaderCard(organization: organization),
        if (!organization.isMine) ...[
          const SizedBox(height: 16),
          _ContactCard(organization: organization),
        ],
        const SizedBox(height: 16),
        _SectionCard(
          title: 'Commentaire',
          child: organization.comment != null
              ? Text(organization.comment!)
              : const EmptyHint('Aucun commentaire.'),
        ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({required this.organization});

  final Organization organization;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OrganizationAvatar(organization: organization, radius: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(organization.name, style: theme.textTheme.titleLarge),
                  Text(
                    organization.isMine
                        ? 'Moi-même'
                        : organization.type?.name ?? 'Type non renseigné',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final category in organization.categories)
                        Chip(label: Text(category.name)),
                      if (organization.isArchived)
                        const Chip(
                          avatar: Icon(Icons.inventory_2_outlined),
                          label: Text('Archivé'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.organization});

  final Organization organization;

  @override
  Widget build(BuildContext context) {
    final address = organization.address;
    final hasContact =
        organization.phone != null ||
        organization.mobile != null ||
        organization.website != null ||
        address != null;

    return _SectionCard(
      title: 'Contact',
      child: !hasContact
          ? const EmptyHint('Aucune coordonnée renseignée.')
          : Column(
              children: [
                if (organization.phone != null)
                  InfoRow(label: 'Téléphone', value: organization.phone!),
                if (organization.mobile != null)
                  InfoRow(label: 'Mobile', value: organization.mobile!),
                if (organization.website != null)
                  InfoRow(label: 'Site web', value: organization.website!),
                if (address != null)
                  InfoRow(
                    label: 'Adresse',
                    value: [
                      address.street,
                      ?address.complement,
                      '${address.postalCode} ${address.city}',
                      ?address.country,
                    ].join('\n'),
                  ),
              ],
            ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
