import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/result.dart';
import '../../models/organization/organization.dart';
import 'organization_actions.dart';

/// Archive ou désarchive [organization] puis confirme par un message,
/// depuis la fiche comme depuis la liste « Mes garages ». Le message
/// propose d'annuler l'action (rétablit l'état précédent).
Future<void> setOrganizationArchived(
  BuildContext context,
  WidgetRef ref,
  Organization organization, {
  required bool archived,
}) async {
  // Capturés avant l'appel : l'annulation peut survenir après la
  // disparition du widget appelant (ex. carte masquée par le filtre).
  final actions = ref.read(organizationActionsProvider);
  final messenger = ScaffoldMessenger.of(context);

  final result = await actions.setArchived(organization, archived);

  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(switch (result) {
      // Un SnackBar avec action persiste par défaut dans les versions
      // récentes de Flutter : on force sa disparition après `duration`.
      Success() => SnackBar(
        persist: false,
        duration: const Duration(seconds: 5),
        showCloseIcon: true,
        content: Text(
          '« ${organization.name} » ${archived ? 'archivé' : 'désarchivé'}.',
        ),
        action: SnackBarAction(
          label: 'Annuler',
          onPressed: () async {
            final undo = await actions.setArchived(organization, !archived);
            if (undo case FailureResult(:final failure)) {
              messenger.showSnackBar(SnackBar(content: Text(failure.message)));
            }
          },
        ),
      ),
      FailureResult(:final failure) => SnackBar(content: Text(failure.message)),
    });
}
