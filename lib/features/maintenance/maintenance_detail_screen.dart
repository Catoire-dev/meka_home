import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/network/result.dart';
import '../../core/utils/date_format.dart';
import '../../core/utils/number_format.dart';
import '../../core/widgets/async_result_view.dart';
import '../../core/widgets/confirm_dialog.dart';
import '../../core/widgets/empty_hint.dart';
import '../../core/widgets/info_row.dart';
import '../../models/document/document.dart';
import '../../models/document/document_type.dart';
import '../../models/maintenance/maintenance.dart';
import '../../models/maintenance/maintenance_type.dart';
import '../../repositories/api_maintenance_repository.dart';
import '../vehicles/vehicle_detail_providers.dart';
import 'maintenance_actions.dart';
import 'maintenance_providers.dart';

/// Détail d'une intervention réalisée : toutes ses informations et les
/// documents qui lui sont associés.
class MaintenanceDetailScreen extends ConsumerWidget {
  const MaintenanceDetailScreen({
    super.key,
    required this.vehicleId,
    required this.maintenanceId,
  });

  final String vehicleId;
  final String maintenanceId;

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Maintenance maintenance,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: "Supprimer l'intervention ?",
      message:
          "L'intervention sera retirée de l'historique. Les documents "
          'associés restent rattachés au véhicule.',
    );
    if (!confirmed || !context.mounted) return;

    final result = await ref
        .read(maintenanceActionsProvider)
        .deleteMaintenance(maintenance);
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
    final maintenancesAsync = ref.watch(vehicleMaintenancesProvider(vehicleId));
    final maintenance = switch (maintenancesAsync.value) {
      Success(:final data) =>
        data.where((m) => m.id == maintenanceId).firstOrNull,
      _ => null,
    };
    final type = switch (ref.watch(maintenanceTypesProvider).value) {
      Success(:final data) => indexMaintenanceTypes(
        data,
      )[maintenance?.maintenanceTypeId],
      _ => null,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(type?.label ?? 'Intervention'),
        actions: [
          if (maintenance != null) ...[
            IconButton(
              tooltip: 'Modifier',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => context.push(
                '/vehicles/$vehicleId/maintenances/$maintenanceId/edit',
              ),
            ),
            IconButton(
              tooltip: 'Supprimer',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _delete(context, ref, maintenance),
            ),
          ],
        ],
      ),
      body: AsyncResultView(
        value: maintenancesAsync,
        builder: (_) => maintenance == null
            ? const Center(child: Text('Intervention introuvable.'))
            : _MaintenanceDetailBody(maintenance: maintenance, type: type),
      ),
    );
  }
}

class _MaintenanceDetailBody extends ConsumerWidget {
  const _MaintenanceDetailBody({required this.maintenance, this.type});

  final Maintenance maintenance;
  final MaintenanceType? type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final documentsAsync = ref.watch(
      vehicleDocumentsProvider(maintenance.vehicleId),
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Intervention', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                InfoRow(label: 'Type', value: type?.label ?? '—'),
                InfoRow(label: 'Date', value: formatDate(maintenance.date)),
                if (maintenance.mileage != null)
                  InfoRow(
                    label: 'Kilométrage',
                    value: '${maintenance.mileage} km',
                  ),
                if (maintenance.cost != null)
                  InfoRow(label: 'Coût', value: formatEuros(maintenance.cost!)),
                if (maintenance.provider != null)
                  InfoRow(
                    label: 'Garage / intervenant',
                    value: maintenance.provider!,
                  ),
                if (maintenance.description != null) ...[
                  const SizedBox(height: 12),
                  Text('Description', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 4),
                  Text(maintenance.description!),
                ],
                if (maintenance.comment != null) ...[
                  const SizedBox(height: 12),
                  Text('Commentaire', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 4),
                  Text(maintenance.comment!),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Documents associés', style: theme.textTheme.titleMedium),
                const SizedBox(height: 8),
                AsyncResultView(
                  value: documentsAsync,
                  builder: (documents) => _LinkedDocuments(
                    documents: documents
                        .where((d) => d.maintenanceId == maintenance.id)
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _LinkedDocuments extends StatelessWidget {
  const _LinkedDocuments({required this.documents});

  final List<Document> documents;

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      return const EmptyHint('Aucun document associé.');
    }
    return Column(
      children: [
        for (final document in documents)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.description_outlined),
            title: Text(document.type.label),
            subtitle: Text(document.comment ?? document.filename),
          ),
      ],
    );
  }
}
