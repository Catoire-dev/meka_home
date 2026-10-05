import 'package:flutter/material.dart';

import '../../../models/organization/organization.dart';

/// Pastille d'icône d'une organisation : « Moi-même », ou icône déduite du
/// nom de son type (les types étant gérés côté backend).
class OrganizationAvatar extends StatelessWidget {
  const OrganizationAvatar({
    super.key,
    required this.organization,
    this.radius,
  });

  final Organization organization;
  final double? radius;

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
    final colorScheme = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: radius,
      backgroundColor: colorScheme.secondaryContainer,
      foregroundColor: colorScheme.onSecondaryContainer,
      child: Icon(_icon, size: radius),
    );
  }
}
