import 'package:cesta/src/api/generated/cesta_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'harness/harness.dart';

void main() {
  testWidgets('shows the server is up, in English', (tester) async {
    final h = Harness(tester);

    await h.pumpApp();

    expect(find.text('Server is up'), findsOneWidget);
    expect(find.text('Database: connected'), findsOneWidget);
  });

  testWidgets('shows the server is up, in Brazilian Portuguese', (tester) async {
    final h = Harness(tester);

    await h.pumpApp(locale: brazilianPortuguese);

    expect(find.text('Status do servidor'), findsOneWidget);
    expect(find.text('Servidor no ar'), findsOneWidget);
    expect(find.text('Banco de dados: conectado'), findsOneWidget);
    expect(find.text('Verificar novamente'), findsOneWidget);
  });

  testWidgets('shows a degraded server when the backend reports its database down', (tester) async {
    final h = Harness(tester);
    h.api.health = const Health(status: HealthStatus.degraded, database: HealthDatabase.down);

    await h.pumpApp();

    expect(find.text('Server is degraded'), findsOneWidget);
    expect(find.text('Database: unreachable'), findsOneWidget);
  });

  testWidgets('offline with nothing stored, says the server could not be reached', (tester) async {
    final h = Harness(tester);
    h.api.goOffline();

    await h.pumpApp();

    expect(find.text("You're offline"), findsOneWidget);
    expect(find.text("Couldn't reach the server."), findsOneWidget);
    expect(find.text('Server is up'), findsNothing);
  });

  testWidgets('offline after a restart, shows the last known status from the device', (tester) async {
    final h = Harness(tester);
    await h.pumpApp();
    h.api.goOffline();

    await h.pumpApp(); // app restarts with the same local database

    expect(find.text("You're offline"), findsOneWidget);
    expect(find.text('Last known status'), findsOneWidget);
    expect(find.text('Server is up'), findsOneWidget);
  });

  testWidgets('checking again after reconnecting shows the live status', (tester) async {
    final h = Harness(tester);
    h.api.goOffline();
    await h.pumpApp();
    h.api.goOnline();

    await tester.tap(find.text('Check again'));
    await tester.pumpAndSettle();

    expect(find.text("You're offline"), findsNothing);
    expect(find.text('Server is up'), findsOneWidget);
  }, variant: TargetPlatformVariant.mobile());

  testWidgets('an unexpected failure says the check failed and lets the user check again', (tester) async {
    final h = Harness(tester);
    h.api.failure = const FormatException('malformed health response');

    await h.pumpApp();

    expect(find.text("Couldn't check the server status."), findsOneWidget);
    expect(find.text('Checking the server…'), findsNothing);

    h.api.failure = null;
    await tester.tap(find.text('Check again'));
    await tester.pumpAndSettle();

    expect(find.text('Server is up'), findsOneWidget);
  });

  testWidgets('stays readable in dark mode at the largest text size', (tester) async {
    final h = Harness(tester);
    tester.view.physicalSize = const Size(360, 640) * tester.view.devicePixelRatio;
    addTearDown(tester.view.reset);

    await h.pumpApp(themeMode: ThemeMode.dark, textScale: 3.0, locale: brazilianPortuguese);

    expect(tester.takeException(), isNull);
    expect(find.text('Servidor no ar'), findsOneWidget);
    expect(find.text('Verificar novamente'), findsOneWidget);
  });
}
