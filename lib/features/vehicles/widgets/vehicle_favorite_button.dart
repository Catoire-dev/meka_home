import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/result.dart';
import '../../../models/vehicle/vehicle.dart';
import '../vehicle_actions.dart';

/// Cœur permettant d'épingler un véhicule sur l'accueil. Désactivé pendant
/// l'enregistrement ; un échec est signalé par un message.
class VehicleFavoriteButton extends ConsumerStatefulWidget {
  const VehicleFavoriteButton({super.key, required this.vehicle});

  final Vehicle vehicle;

  @override
  ConsumerState<VehicleFavoriteButton> createState() =>
      _VehicleFavoriteButtonState();
}

class _VehicleFavoriteButtonState extends ConsumerState<VehicleFavoriteButton> {
  bool _saving = false;

  Future<void> _toggle() async {
    setState(() => _saving = true);
    final result = await ref
        .read(vehicleActionsProvider)
        .setFavorite(widget.vehicle, !widget.vehicle.isFavorite);
    if (!mounted) return;
    setState(() => _saving = false);
    if (result case FailureResult(:final failure)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFavorite = widget.vehicle.isFavorite;
    return IconButton(
      tooltip: isFavorite ? 'Retirer des favoris' : 'Ajouter aux favoris',
      isSelected: isFavorite,
      icon: const Icon(Icons.favorite_border),
      selectedIcon: Icon(
        Icons.favorite,
        color: Theme.of(context).colorScheme.error,
      ),
      onPressed: _saving ? null : _toggle,
    );
  }
}
