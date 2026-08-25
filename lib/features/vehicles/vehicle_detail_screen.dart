import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/media/image_url_resolver.dart';
import '../../core/network/result.dart';
import '../../core/widgets/vehicle_placeholder.dart';
import '../../models/document/document.dart';
import '../../models/document/document_type.dart';
import '../../models/maintenance/maintenance.dart';
import '../../models/maintenance/maintenance_type.dart';
import '../../models/reminder/reminder.dart';
import '../../models/vehicle/vehicle.dart';
import '../../models/vehicle/vehicle_category.dart';
import '../../models/vehicle/vehicle_energy.dart';
import '../../models/vehicle/vehicle_status.dart';
import '../../repositories/api_maintenance_repository.dart';
import 'vehicle_detail_providers.dart';
import 'vehicles_providers.dart';

String _formatDate(DateTime date) {
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  return '$d/$m/${date.year}';
}

class VehicleDetailScreen extends ConsumerWidget {
  const VehicleDetailScreen({super.key, required this.vehicleId});

  final String vehicleId;

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
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.push('/vehicles/$vehicleId/edit'),
          ),
        ],
      ),
      body: vehicleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('$error')),
        data: (result) => switch (result) {
          FailureResult(:final failure) => Center(child: Text(failure.message)),
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
        _MaintenanceCard(vehicleId: vehicle.id),
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
                      Chip(label: Text(vehicle.category.label)),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
        ],
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
        _InfoRow(label: 'Immatriculation', value: vehicle.licensePlate!),
      if (vehicle.vin != null) _InfoRow(label: 'VIN', value: vehicle.vin!),
      if (vehicle.firstRegistrationDate != null)
        _InfoRow(
          label: '1ère immatriculation',
          value: _formatDate(vehicle.firstRegistrationDate!),
        ),
      if (vehicle.energy != null)
        _InfoRow(label: 'Énergie', value: vehicle.energy!.label),
      if (vehicle.fiscalPower != null)
        _InfoRow(
          label: 'Puissance fiscale',
          value: '${vehicle.fiscalPower} CV',
        ),
      if (vehicle.powerHp != null)
        _InfoRow(label: 'Puissance', value: '${vehicle.powerHp} CH'),
      if (vehicle.weightKg != null)
        _InfoRow(label: 'Poids', value: '${vehicle.weightKg} kg'),
      if (vehicle.color != null)
        _InfoRow(label: 'Couleur', value: vehicle.color!),
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
              Text(
                'Aucune information renseignée.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...rows,
          ],
        ),
      ),
    );
  }
}

class _MaintenanceCard extends ConsumerWidget {
  const _MaintenanceCard({required this.vehicleId});

  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final remindersAsync = ref.watch(
      vehicleScheduleRemindersProvider(vehicleId),
    );
    final maintenancesAsync = ref.watch(vehicleMaintenancesProvider(vehicleId));
    final typesAsync = ref.watch(maintenanceTypesProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Entretiens', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Text('Échéances', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            remindersAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              ),
              error: (error, stackTrace) => Text('$error'),
              data: (result) => switch (result) {
                FailureResult(:final failure) => Text(failure.message),
                Success(:final data) => _RemindersList(reminders: data),
              },
            ),
            const SizedBox(height: 16),
            Text('Historique', style: theme.textTheme.labelLarge),
            const SizedBox(height: 4),
            _buildHistory(typesAsync, maintenancesAsync),
          ],
        ),
      ),
    );
  }

  Widget _buildHistory(
    AsyncValue<Result<List<MaintenanceType>>> typesAsync,
    AsyncValue<Result<List<Maintenance>>> maintenancesAsync,
  ) {
    if (typesAsync.isLoading || maintenancesAsync.isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(),
      );
    }
    if (typesAsync.hasError) return Text('${typesAsync.error}');
    if (maintenancesAsync.hasError) return Text('${maintenancesAsync.error}');

    final typesResult = typesAsync.value;
    final maintenancesResult = maintenancesAsync.value;
    if (typesResult == null || maintenancesResult == null) {
      return const SizedBox.shrink();
    }
    if (typesResult is FailureResult<List<MaintenanceType>>) {
      return Text(typesResult.failure.message);
    }
    if (maintenancesResult is FailureResult<List<Maintenance>>) {
      return Text(maintenancesResult.failure.message);
    }

    final types = (typesResult as Success<List<MaintenanceType>>).data;
    final maintenances =
        (maintenancesResult as Success<List<Maintenance>>).data;
    return _MaintenancesList(
      maintenances: maintenances,
      typeById: {for (final t in types) t.id: t},
    );
  }
}

class _RemindersList extends StatelessWidget {
  const _RemindersList({required this.reminders});

  final List<Reminder> reminders;

  Color _urgencyColor(ColorScheme colorScheme, ReminderUrgency urgency) =>
      switch (urgency) {
        ReminderUrgency.overdue => colorScheme.error,
        ReminderUrgency.dueSoon => colorScheme.tertiary,
        ReminderUrgency.upcoming => colorScheme.outline,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (reminders.isEmpty) {
      return Text(
        'Aucune échéance planifiée.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      children: [
        for (final reminder in reminders)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              radius: 6,
              backgroundColor: _urgencyColor(
                theme.colorScheme,
                reminder.urgency,
              ),
            ),
            title: Text(reminder.type.label),
            subtitle: Text(
              [
                if (reminder.dueDate != null) _formatDate(reminder.dueDate!),
                if (reminder.dueMileage != null) '${reminder.dueMileage} km',
              ].join(' · '),
            ),
          ),
      ],
    );
  }
}

class _MaintenancesList extends StatelessWidget {
  const _MaintenancesList({required this.maintenances, required this.typeById});

  final List<Maintenance> maintenances;
  final Map<int, MaintenanceType> typeById;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (maintenances.isEmpty) {
      return Text(
        'Aucun entretien enregistré.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Column(
      children: [
        for (final maintenance in maintenances)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              typeById[maintenance.maintenanceTypeId]?.label ?? 'Entretien',
            ),
            subtitle: Text(
              [
                _formatDate(maintenance.date),
                if (maintenance.mileage != null) '${maintenance.mileage} km',
                if (maintenance.provider != null) maintenance.provider!,
              ].join(' · '),
            ),
            trailing: maintenance.cost != null
                ? Text('${maintenance.cost!.toStringAsFixed(2)} €')
                : null,
          ),
      ],
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
            documentsAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              ),
              error: (error, stackTrace) => Text('$error'),
              data: (result) => switch (result) {
                FailureResult(:final failure) => Text(failure.message),
                Success(:final data) => _DocumentsList(documents: data),
              },
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
    final theme = Theme.of(context);
    if (documents.isEmpty) {
      return Text(
        'Aucun document.',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    }

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
                  _formatDate(document.uploadedAt!),
              ].join(' · '),
            ),
          ),
      ],
    );
  }
}
