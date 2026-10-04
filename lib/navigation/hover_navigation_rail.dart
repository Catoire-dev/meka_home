import 'package:flutter/material.dart';

import 'nav_destination.dart';

/// [NavigationRail] compact par défaut, qui s'étend au survol de la souris.
///
/// Prévu pour être superposé au contenu (voir [HoverNavigationRail.compactWidth]) :
/// l'extension ne décale pas la page, elle passe par-dessus. Sur écran tactile
/// (pas de survol), le rail reste compact.
class HoverNavigationRail extends StatefulWidget {
  const HoverNavigationRail({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final List<NavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  static const _defaultMinWidth = 80.0;
  static const _indicatorWidth = 56.0;
  static const _minLabelEndPadding = 20.0;

  /// Largeur occupée par le rail replié (séparateur inclus), à réserver à
  /// gauche du contenu.
  static double compactWidth(BuildContext context) =>
      (Theme.of(context).navigationRailTheme.minWidth ?? _defaultMinWidth) + 1;

  @override
  State<HoverNavigationRail> createState() => _HoverNavigationRailState();
}

class _HoverNavigationRailState extends State<HoverNavigationRail> {
  bool _hovered = false;

  void _setHovered(bool value) {
    if (_hovered != value) setState(() => _hovered = value);
  }

  /// Largeur du rail étendu ajustée au libellé le plus long, pour que toutes
  /// les destinations aient la même largeur sans espace superflu.
  ///
  /// Reproduit la mise en page interne de [NavigationRail] : zone d'icône
  /// (`minWidth`, indicateur de 56px centré) + libellé + marge de fin égale
  /// à l'espace à gauche de l'indicateur (8px minimum, imposé par Flutter).
  double _extendedRailWidth(BuildContext context) {
    final theme = Theme.of(context);
    final railTheme = theme.navigationRailTheme;
    final fallbackStyle = theme.textTheme.labelMedium;
    final styles = [
      railTheme.selectedLabelTextStyle ?? fallbackStyle,
      railTheme.unselectedLabelTextStyle ?? fallbackStyle,
    ];
    final textScaler = MediaQuery.textScalerOf(context);

    var maxLabelWidth = 0.0;
    for (final d in widget.destinations) {
      for (final style in styles) {
        final painter = TextPainter(
          text: TextSpan(text: d.label, style: style),
          textDirection: Directionality.of(context),
          textScaler: textScaler,
          maxLines: 1,
        )..layout();
        if (painter.width > maxLabelWidth) maxLabelWidth = painter.width;
        painter.dispose();
      }
    }

    final minWidth = railTheme.minWidth ?? HoverNavigationRail._defaultMinWidth;
    final leadingGap = (minWidth - HoverNavigationRail._indicatorWidth) / 2;
    final labelEndPadding = leadingGap > HoverNavigationRail._minLabelEndPadding
        ? leadingGap
        : HoverNavigationRail._minLabelEndPadding;
    return minWidth + maxLabelWidth.ceilToDouble() + labelEndPadding;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          NavigationRail(
            selectedIndex: widget.selectedIndex,
            onDestinationSelected: widget.onDestinationSelected,
            extended: _hovered,
            minExtendedWidth: _extendedRailWidth(context),
            labelType: NavigationRailLabelType.none,
            destinations: [
              for (final d in widget.destinations)
                NavigationRailDestination(
                  icon: Icon(d.icon),
                  selectedIcon: Icon(d.selectedIcon),
                  label: Text(d.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
        ],
      ),
    );
  }
}
