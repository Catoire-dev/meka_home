import 'package:flutter/material.dart';

/// Destination principale de l'application, partagée entre la
/// [NavigationBar] (mobile) et le [NavigationRail] (tablette/desktop).
class NavDestination {
  const NavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

const appDestinations = [
  NavDestination(
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
    label: 'Accueil',
  ),
  NavDestination(
    icon: Icons.directions_car_outlined,
    selectedIcon: Icons.directions_car,
    label: 'Véhicules',
  ),
  NavDestination(
    icon: Icons.storefront_outlined,
    selectedIcon: Icons.storefront,
    label: 'Mes garages',
  ),
];
