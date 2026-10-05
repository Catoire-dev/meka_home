import 'package:flutter/material.dart';

import '../../../models/organization/organization.dart';

/// Carte d'une organisation dans la liste « Mes garages » : nom, type,
/// catégories prises en charge et coordonnées principales.
class OrganizationCard extends StatelessWidget {
  const OrganizationCard({super.key, required this.organization, this.onTap});

  final Organization organization;
  final VoidCallback? onTap;

  /// Les types étant gérés côté backend, l'icône est déduite de leur nom.
  IconData get _icon {
    if (organization.isMine) return Icons.person_outline;
    final type = organization.type?.name.toLowerCase() ?? '';
    if (type.contains('contrôle') || type.contains('controle')) {
      return Icons.fact_check_outlined;
    }
    if (type.contains('concession')) return Icons.storefront_outlined;
    if (type.contains('assurance')) return Icons.shield_outlined;
    if (type.contains('garage')) return Icons.build_outlined;
    return Icons.handyman_outlined;
  }

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
        child: Opacity(
          opacity: organization.isArchived ? 0.6 : 1,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.secondaryContainer,
                  foregroundColor: colorScheme.onSecondaryContainer,
                  child: Icon(_icon),
                ),
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
                            for (final category in organization.categories)
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
      ),
    );
  }
}
