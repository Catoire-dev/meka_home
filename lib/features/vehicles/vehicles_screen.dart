import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/result.dart';
import '../../core/widgets/vehicle_summary_card.dart';
import '../../models/vehicle/vehicle.dart';
import '../../models/vehicle/vehicle_category.dart';
import '../../models/vehicle/vehicle_status.dart';
import 'vehicles_providers.dart';

class VehiclesScreen extends ConsumerWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(filteredVehiclesProvider);
    final sort = ref.watch(vehicleSortOptionProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Véhicules'),
        actions: [
          PopupMenuButton<VehicleSortOption>(
            icon: const Icon(Icons.sort),
            initialValue: sort,
            onSelected: (value) =>
                ref.read(vehicleSortOptionProvider.notifier).state = value,
            itemBuilder: (context) => [
              for (final option in VehicleSortOption.values)
                PopupMenuItem(value: option, child: Text('Trier par ${option.label}')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: _SearchField(),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: _CategoryFilter(),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: _StatusFilter(),
          ),
          Expanded(
            child: vehiclesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => Center(child: Text('$error')),
              data: (result) => switch (result) {
                FailureResult(:final failure) =>
                  Center(child: Text(failure.message)),
                Success(:final data) => _VehiclesList(vehicles: data),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends ConsumerWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextField(
      onChanged: (value) =>
          ref.read(vehicleSearchQueryProvider.notifier).state = value,
      decoration: const InputDecoration(
        hintText: 'Rechercher un véhicule...',
        prefixIcon: Icon(Icons.search),
      ),
    );
  }
}

class _CategoryFilter extends ConsumerWidget {
  const _CategoryFilter();

  IconData _icon(VehicleCategory category) => switch (category) {
    VehicleCategory.moto => Icons.two_wheeler,
    VehicleCategory.voiture => Icons.directions_car,
    VehicleCategory.autre => Icons.category_outlined,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(vehicleCategoryFilterProvider);

    return SegmentedButton<VehicleCategory>(
      segments: [
        for (final category in VehicleCategory.values)
          ButtonSegment(
            value: category,
            label: Text(category.label),
            icon: Icon(_icon(category)),
          ),
      ],
      selected: {selected},
      onSelectionChanged: (value) =>
          ref.read(vehicleCategoryFilterProvider.notifier).state = value.first,
    );
  }
}

class _StatusFilter extends ConsumerWidget {
  const _StatusFilter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(vehicleStatusFilterProvider);

    return SegmentedButton<VehicleStatus>(
      segments: [
        for (final status in VehicleStatus.values)
          ButtonSegment(value: status, label: Text(status.label)),
      ],
      selected: {selected},
      onSelectionChanged: (value) =>
          ref.read(vehicleStatusFilterProvider.notifier).state = value.first,
    );
  }
}

class _VehiclesList extends StatelessWidget {
  const _VehiclesList({required this.vehicles});

  final List<Vehicle> vehicles;

  @override
  Widget build(BuildContext context) {
    if (vehicles.isEmpty) {
      final theme = Theme.of(context);
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Aucun véhicule ne correspond à ces filtres.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: vehicles.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) =>
          VehicleSummaryCard(vehicle: vehicles[index]),
    );
  }
}
