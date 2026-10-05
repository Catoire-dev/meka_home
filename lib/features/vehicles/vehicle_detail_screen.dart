import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/failure.dart';
import '../../core/media/image_url_resolver.dart';
import '../../core/network/result.dart';
import '../../core/utils/date_format.dart';
import '../../core/widgets/async_result_view.dart';
import '../../core/widgets/empty_hint.dart';
import '../../core/widgets/error_retry_view.dart';
import '../../core/widgets/info_row.dart';
import '../../core/widgets/vehicle_placeholder.dart';
import '../../models/document/document.dart';
import '../../models/document/document_type.dart';
import '../../models/vehicle/vehicle.dart';
import '../../models/vehicle/vehicle_energy.dart';
import '../../models/vehicle/vehicle_status.dart';
import '../../repositories/api_maintenance_repository.dart';
import '../maintenance/maintenance_providers.dart';
import '../maintenance/widgets/vehicle_maintenance_section.dart';
import 'vehicle_detail_providers.dart';
import 'vehicles_providers.dart';

class VehicleDetailScreen extends ConsumerWidget {
  const VehicleDetailScreen({super.key, required this.vehicleId});

  final String vehicleId;

  void _refresh(WidgetRef ref) {
    ref.invalidate(maintenanceTypesProvider);
    ref.invalidate(vehicleByIdProvider(vehicleId));
    ref.invalidate(vehicleMaintenancesProvider(vehicleId));
    ref.invalidate(vehicleSchedulesProvider(vehicleId));
    ref.invalidate(vehicleDocumentsProvider(vehicleId));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleAsync = ref.watch(vehicleByIdProvider(vehicleId));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          vehicleAsync.whenOrNull(
                data: (result) => switch (result) {
                  Success(:final data) => data.customName,
                  FailureResult() => 'Véhicule',
                },
              ) ??
              'Véhicule',
        ),
        actions: [
          IconButton(
            tooltip: 'Recharger',
            icon: const Icon(Icons.refresh),
            onPressed: () => _refresh(ref),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/vehicles/$vehicleId/edit'),
          ),
        ],
      ),
      body: vehicleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => ErrorRetryView(
          failure: UnknownFailure('$error'),
          onRetry: () => _refresh(ref),
        ),
        data: (result) => switch (result) {
          FailureResult(:final failure) => ErrorRetryView(
            failure: failure,
            onRetry: () => _refresh(ref),
          ),
          Success(:final data) => _VehicleDetailBody(vehicle: data),
        },
      ),
    );
  }
}

class _VehicleDetailBody extends StatelessWidget {
  const _VehicleDetailBody({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _HeaderCard(vehicle: vehicle),
        const SizedBox(height: 16),
        _GeneralInfoCard(vehicle: vehicle),
        const SizedBox(height: 16),
        _RegistrationCard(vehicle: vehicle),
        const SizedBox(height: 16),
        VehicleMaintenanceSection(vehicleId: vehicle.id),
        const SizedBox(height: 16),
        _DocumentsCard(vehicleId: vehicle.id),
      ],
    );
  }
}

class _HeaderCard extends ConsumerWidget {
  const _HeaderCard({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final photoUrl = ref
        .watch(imageUrlResolverProvider)
        .resolve(vehicle.photoFilename);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 96,
                height: 96,
                child: photoUrl != null
                    ? Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            VehiclePlaceholder(category: vehicle.category),
                      )
                    : VehiclePlaceholder(category: vehicle.category),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vehicle.customName, style: theme.textTheme.titleLarge),
                  Text(
                    '${vehicle.brand} ${vehicle.model}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      Chip(label: Text(vehicle.category.name)),
                      Chip(label: Text(vehicle.status.label)),
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

class _GeneralInfoCard extends StatelessWidget {
  const _GeneralInfoCard({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Informations générales', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Text('${vehicle.mileage} km', style: theme.textTheme.headlineSmall),
            if (vehicle.comment != null && vehicle.comment!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(vehicle.comment!, style: theme.textTheme.bodyMedium),
            ],
          ],
        ),
      ),
    );
  }
}

class _RegistrationCard extends StatelessWidget {
  const _RegistrationCard({required this.vehicle});

  final Vehicle vehicle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = <Widget>[
      if (vehicle.licensePlate != null)
        InfoRow(label: 'Immatriculation', value: vehicle.licensePlate!),
      if (vehicle.vin != null) InfoRow(label: 'VIN', value: vehicle.vin!),
      if (vehicle.firstRegistrationDate != null)
        InfoRow(
          label: '1ère immatriculation',
          value: formatDate(vehicle.firstRegistrationDate!),
        ),
      if (vehicle.energy != null)
        InfoRow(label: 'Énergie', value: vehicle.energy!.label),
      if (vehicle.fiscalPower != null)
        InfoRow(label: 'Puissance fiscale', value: '${vehicle.fiscalPower} CV'),
      if (vehicle.powerHp != null)
        InfoRow(label: 'Puissance', value: '${vehicle.powerHp} CH'),
      if (vehicle.weightKg != null)
        InfoRow(label: 'Poids', value: '${vehicle.weightKg} kg'),
      if (vehicle.color != null)
        InfoRow(label: 'Couleur', value: vehicle.color!),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Carte grise', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            if (rows.isEmpty)
              const EmptyHint('Aucune information renseignée.')
            else
              ...rows,
          ],
        ),
      ),
    );
  }
}

class _DocumentsCard extends ConsumerWidget {
  const _DocumentsCard({required this.vehicleId});

  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final documentsAsync = ref.watch(vehicleDocumentsProvider(vehicleId));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Documents', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            AsyncResultView(
              value: documentsAsync,
              builder: (documents) => _DocumentsList(documents: documents),
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentsList extends StatelessWidget {
  const _DocumentsList({required this.documents});

  final List<Document> documents;

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) return const EmptyHint('Aucun document.');

    return Column(
      children: [
        for (final document in documents)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.description_outlined),
            title: Text(document.type.label),
            subtitle: Text(
              [
                document.filename,
                if (document.uploadedAt != null)
                  formatDate(document.uploadedAt!),
              ].join(' · '),
            ),
          ),
      ],
    );
  }
}
