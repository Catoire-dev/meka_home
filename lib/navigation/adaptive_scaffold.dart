import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/breakpoints.dart';

class _NavDestination {
  const _NavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

const _destinations = [
  _NavDestination(
    icon: Icons.home_outlined,
    selectedIcon: Icons.home,
    label: 'Accueil',
  ),
  _NavDestination(
    icon: Icons.directions_car_outlined,
    selectedIcon: Icons.directions_car,
    label: 'Véhicules',
  ),
];

/// Coquille de navigation adaptative : NavigationRail à gauche à partir de
/// la classe de fenêtre `medium`, NavigationBar en bas en dessous.
///
/// S'appuie sur un [StatefulNavigationShell] de go_router pour préserver
/// l'état de chaque branche lors du changement d'onglet.
class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _onDestinationSelected(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final useSideNav = AppBreakpoints.usesSideNavigation(width);

    if (!useSideNav) {
      return Scaffold(
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: navigationShell.currentIndex,
          onDestinationSelected: _onDestinationSelected,
          destinations: [
            for (final d in _destinations)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label,
              ),
          ],
        ),
      );
    }

    final extended = width >= AppBreakpoints.expanded;

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: navigationShell.currentIndex,
            onDestinationSelected: _onDestinationSelected,
            extended: extended,
            labelType: extended ? null : NavigationRailLabelType.all,
            destinations: [
              for (final d in _destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: Text(d.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: navigationShell),
        ],
      ),
    );
  }
}
