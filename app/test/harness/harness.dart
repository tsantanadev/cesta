import 'package:cesta/src/app.dart';
import 'package:cesta/src/db/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'fake_api_client.dart';

export 'fake_api_client.dart';

const english = Locale('en');
const brazilianPortuguese = Locale('pt', 'BR');

/// Seam 2 harness: the real app with an in-memory local database and a fake
/// API client. Each test gets its own [Harness]; [db] can be reused across
/// [pumpApp] calls to simulate the app restarting with the same storage.
class Harness {
  Harness(this.tester) : api = FakeApiClient(), db = AppDatabase(NativeDatabase.memory()) {
    addTearDown(db.close);
  }

  final WidgetTester tester;
  final FakeApiClient api;
  final AppDatabase db;

  Future<void> pumpApp({Locale locale = english, ThemeMode themeMode = ThemeMode.light, double textScale = 1.0}) async {
    // Unmount any previous instance so restarts start from a clean widget tree.
    await tester.pumpWidget(const SizedBox.shrink());
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(CestaApp(api: api, database: db, locale: locale, themeMode: themeMode));
    await tester.pumpAndSettle();
  }
}
