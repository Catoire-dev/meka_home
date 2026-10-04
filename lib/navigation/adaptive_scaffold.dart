import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/breakpoints.dart';
import 'hover_navigation_rail.dart';
import 'nav_destination.dart';

/// Coquille de navigation adaptative : NavigationRail à gauche à partir de
/// la classe de fenêtre `medium` (replié, étendu au survol), NavigationBar en
/// bas en dessous.
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
            for (final d in appDestinations)
              NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.selectedIcon),
                label: d.label,
              ),
          ],
        ),
      );
    }

    // Le rail est superposé au contenu : le survol l'étend par-dessus la page
    // sans la décaler, seule la largeur repliée est réservée.
    return Scaffold(
      body: Stack(
        children: [
          Padding(
            padding: EdgeInsetsDirectional.only(
              start: HoverNavigationRail.compactWidth(context),
            ),
            child: navigationShell,
          ),
          PositionedDirectional(
            start: 0,
            top: 0,
            bottom: 0,
            child: HoverNavigationRail(
              destinations: appDestinations,
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: _onDestinationSelected,
            ),
          ),
        ],
      ),
    );
  }
}
