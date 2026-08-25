import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meka_home/app.dart';

void main() {
  testWidgets('Affiche la navigation Accueil / Véhicules', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: MekaHomeApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Accueil'), findsWidgets);
    expect(find.text('Véhicules'), findsWidgets);
  });
}
