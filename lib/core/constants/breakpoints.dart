/// Points de rupture responsive centralisés, alignés sur les tailles de
/// classe de fenêtre Material 3 (compact / medium / expanded).
enum AppWindowClass { compact, medium, expanded }

class AppBreakpoints {
  const AppBreakpoints._();

  static const double medium = 600;
  static const double expanded = 840;

  static AppWindowClass classify(double width) {
    if (width >= expanded) return AppWindowClass.expanded;
    if (width >= medium) return AppWindowClass.medium;
    return AppWindowClass.compact;
  }

  /// Navigation latérale (rail) à partir de `medium`, barre basse en dessous.
  static bool usesSideNavigation(double width) =>
      classify(width) != AppWindowClass.compact;
}
