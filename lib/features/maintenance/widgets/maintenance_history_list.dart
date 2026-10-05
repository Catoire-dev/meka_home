import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/utils/date_format.dart';
import '../../../core/utils/number_format.dart';
import '../../../core/widgets/empty_hint.dart';
import '../../../models/maintenance/maintenance.dart';
import '../../../models/maintenance/maintenance_type.dart';
import '../../../models/organization/organization.dart';

/// Historique chronologique des interventions d'un véhicule (les plus
/// récentes en premier). Toucher une intervention ouvre son détail.
class MaintenanceHistoryList extends StatelessWidget {
  const MaintenanceHistoryList({
    super.key,
    required this.maintenances,
    required this.typeById,
    required this.organizationById,
  });

  final List<Maintenance> maintenances;
  final Map<int, MaintenanceType> typeById;
  final Map<String, Organization> organizationById;

  @override
  Widget build(BuildContext context) {
    if (maintenances.isEmpty) {
      return const EmptyHint('Aucun entretien enregistré.');
    }

    return Column(
      children: [
        for (final maintenance in maintenances)
          ListTile(
            contentPadding: EdgeInsets.zero,
            onTap: () => context.push(
              '/vehicles/${maintenance.vehicleId}/maintenances/${maintenance.id}',
            ),
            title: Text(
              typeById[maintenance.maintenanceTypeId]?.label ?? 'Entretien',
            ),
            subtitle: Text(
              [
                formatDate(maintenance.date),
                if (maintenance.mileage != null) '${maintenance.mileage} km',
                ?organizationById[maintenance.organizationId]?.name,
              ].join(' · '),
            ),
            trailing: maintenance.cost != null
                ? Text(formatEuros(maintenance.cost!))
                : null,
          ),
      ],
    );
  }
}
