import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/reminder/reminder.dart';
import '../../models/vehicle/vehicle.dart';
import '../media/image_url_resolver.dart';
import 'vehicle_placeholder.dart';

/// Carte résumant un véhicule : photo, identité, kilométrage, commentaire
/// et prochaine échéance d'entretien le cas échéant.
class VehicleSummaryCard extends ConsumerWidget {
  const VehicleSummaryCard({
    super.key,
    required this.vehicle,
    this.nextReminder,
  });

  final Vehicle vehicle;
  final Reminder? nextReminder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final photoUrl = ref
        .watch(imageUrlResolverProvider)
        .resolve(vehicle.photoFilename);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 72,
                height: 72,
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
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vehicle.customName, style: theme.textTheme.titleMedium),
                  Text(
                    '${vehicle.brand} ${vehicle.model}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      if (vehicle.licensePlate != null)
                        Text(
                          vehicle.licensePlate!,
                          style: theme.textTheme.bodySmall,
                        ),
                      Text(
                        '${vehicle.mileage} km',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                  if (vehicle.comment != null && vehicle.comment!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      vehicle.comment!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (nextReminder != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.build_outlined,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Prochain entretien : ${nextReminder!.type.label}',
                            style: theme.textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis,
                          ),
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
    );
  }
}
