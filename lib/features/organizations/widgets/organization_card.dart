import 'package:flutter/material.dart';

import '../../../models/organization/organization.dart';
import 'organization_avatar.dart';

/// Carte d'une organisation dans la liste « Mes garages » : nom, type,
/// catégories prises en charge et coordonnées principales, avec raccourcis
/// de modification et d'archivage.
class OrganizationCard extends StatelessWidget {
  const OrganizationCard({
    super.key,
    required this.organization,
    this.onTap,
    this.onEdit,
    this.onToggleArchived,
  });

  final Organization organization;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  /// Archive le garage actif, ou désarchive le garage archivé.
  final VoidCallback? onToggleArchived;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final contact = [
      ?organization.mobile,
      ?organization.phone,
      ?organization.address?.singleLine,
    ];

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Opacity(
                  opacity: organization.isArchived ? 0.6 : 1,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OrganizationAvatar(organization: organization),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              organization.name,
                              style: theme.textTheme.titleMedium,
                            ),
                            Text(
                              [
                                organization.isMine
                                    ? 'Moi-même'
                                    : organization.type?.name ?? '—',
                                if (organization.isArchived) 'Archivé',
                              ].join(' · '),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (contact.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(contact.join(' · ')),
                            ],
                            if (organization.categories.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  for (final category
                                      in organization.categories)
                                    Chip(
                                      label: Text(category.name),
                                      visualDensity: VisualDensity.compact,
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Modifier',
                icon: const Icon(Icons.edit_outlined),
                onPressed: onEdit,
              ),
              IconButton(
                tooltip: organization.isArchived ? 'Désarchiver' : 'Archiver',
                icon: Icon(
                  organization.isArchived
                      ? Icons.unarchive_outlined
                      : Icons.archive_outlined,
                ),
                onPressed: onToggleArchived,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
