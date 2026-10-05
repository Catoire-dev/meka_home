import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/errors/failure.dart';
import '../../core/network/result.dart';
import '../../core/widgets/error_retry_view.dart';
import '../../core/widgets/vehicle_category_icon.dart';
import '../../core/widgets/vehicle_summary_card.dart';
import '../../models/vehicle/vehicle.dart';
import '../../models/vehicle/vehicle_category.dart';
import '../../models/vehicle/vehicle_status.dart';
import '../../repositories/api_vehicle_repository.dart';
import 'vehicles_providers.dart';

class VehiclesScreen extends ConsumerWidget {
  const VehiclesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehiclesAsync = ref.watch(filteredVehiclesProvider);
    final sort = ref.watch(vehicleSortOptionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Véhicules'),
            const SizedBox(width: 16),
            Flexible(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 280),
                child: const _SearchField(),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Recharger',
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(allVehiclesProvider);
              ref.invalidate(vehicleCategoriesProvider);
            },
          ),
          PopupMenuButton<VehicleSortOption>(
            icon: const Icon(Icons.sort),
            initialValue: sort,
            onSelected: (value) =>
                ref.read(vehicleSortOptionProvider.notifier).state = value,
            itemBuilder: (context) => [
              for (final option in VehicleSortOption.values)
                PopupMenuItem(
                  value: option,
                  child: Text('Trier par ${option.label}'),
                ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/vehicles/new'),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [_CategoryFilter(), _StatusFilter()],
              ),
            ),
          ),
          Expanded(
            child: vehiclesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stackTrace) => ErrorRetryView(
                failure: UnknownFailure('$error'),
                onRetry: () => ref.invalidate(allVehiclesProvider),
              ),
              data: (result) => switch (result) {
                FailureResult(:final failure) => ErrorRetryView(
                  failure: failure,
                  onRetry: () => ref.invalidate(allVehiclesProvider),
                ),
                Success(:final data) => _VehiclesList(vehicles: data),
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchField extends ConsumerStatefulWidget {
  const _SearchField();

  @override
  ConsumerState<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends ConsumerState<_SearchField> {
  late final TextEditingController _controller = TextEditingController(
    text: ref.read(vehicleSearchQueryProvider),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setQuery(String value) =>
      ref.read(vehicleSearchQueryProvider.notifier).state = value;

  void _clear() {
    _controller.clear();
    _setQuery('');
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _controller,
      builder: (context, value, _) => TextField(
        controller: _controller,
        onChanged: _setQuery,
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: 'Rechercher...',
          prefixIcon: const Icon(Icons.search, size: 20),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
          suffixIcon: value.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Effacer',
                  icon: const Icon(Icons.close, size: 18),
                  visualDensity: VisualDensity.compact,
                  onPressed: _clear,
                ),
          suffixIconConstraints: const BoxConstraints(
            minWidth: 36,
            minHeight: 36,
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 8,
            horizontal: 8,
          ),
        ),
      ),
    );
  }
}

class _CategoryFilter extends ConsumerWidget {
  const _CategoryFilter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(vehicleCategoryFilterProvider);
    // Sans la liste des catégories, le filtre se limite à « Tout ».
    final categories = switch (ref.watch(vehicleCategoriesProvider).value) {
      Success(:final data) => data,
      _ => const <VehicleCategory>[],
    };

    return SegmentedButton<VehicleCategory?>(
      segments: [
        const ButtonSegment(
          value: null,
          label: Text('Tout'),
          icon: Icon(Icons.apps),
        ),
        for (final category in categories)
          ButtonSegment(
            value: category,
            label: Text(category.name),
            icon: Icon(vehicleCategoryIcon(category)),
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
      itemBuilder: (context, index) {
        final vehicle = vehicles[index];
        return VehicleSummaryCard(
          vehicle: vehicle,
          onTap: () => context.push('/vehicles/${vehicle.id}'),
        );
      },
    );
  }
}
