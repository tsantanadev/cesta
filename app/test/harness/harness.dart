import 'package:cesta/src/app.dart';
import 'package:cesta/src/db/app_database.dart';
import 'package:cesta/src/ui/components.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'fake_api_client.dart';
import 'fake_auth_gateway.dart';

export 'package:cesta/src/ui/components.dart' show CesButton, CesMessage;

export 'fake_api_client.dart';
export 'fake_auth_gateway.dart';

const english = Locale('en');
const brazilianPortuguese = Locale('pt', 'BR');

/// A phone-sized screen in logical pixels (the design's frame), taller than
/// the test default.
const iPhone = Size(390, 844);

/// Seam 2 harness: the real app with an in-memory local database, a fake API
/// client and a fake identity provider. Each test gets its own [Harness]; [db]
/// and [auth] can be reused across [pumpApp] calls to simulate the app
/// restarting with the same storage and the same stored session.
class Harness {
  Harness(this.tester) : auth = FakeAuthGateway(), db = AppDatabase(NativeDatabase.memory()) {
    api = FakeApiClient(auth: auth);
    addTearDown(db.close);
  }

  final WidgetTester tester;
  final FakeAuthGateway auth;
  late final FakeApiClient api;
  final AppDatabase db;

  Future<void> pumpApp({
    Locale locale = english,
    ThemeMode themeMode = ThemeMode.light,
    double textScale = 1.0,
    String? initialLocation,
    Size? screen,
  }) async {
    // Unmount any previous instance so restarts start from a clean widget tree.
    await tester.pumpWidget(const SizedBox.shrink());
    if (screen != null) {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = screen;
      addTearDown(tester.view.reset);
    }
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      CestaApp(
        api: api,
        auth: auth,
        database: db,
        locale: locale,
        themeMode: themeMode,
        initialLocation: initialLocation,
      ),
    );
    await tester.pumpAndSettle();
  }

  /// A User who has used Cesta before, with a confirmed display name.
  /// [withGoogle] makes the Google picker return them; [signedIn] starts the
  /// app with their session stored.
  FakeIdentity existingUser({
    required String email,
    required String password,
    required String displayName,
    bool withGoogle = false,
    bool signedIn = false,
  }) {
    final identity = auth.addIdentity(email: email, password: password, name: displayName, signedIn: signedIn);
    api.addUser(identity, displayName: displayName);
    if (withGoogle) auth.googleAccount = FakeGoogleAccount(email: email, name: displayName);
    return identity;
  }

  /// Starts signed in as a User with a confirmed display name.
  FakeIdentity signedIn({String email = 'ana@example.com', String displayName = 'Ana Souza'}) =>
      existingUser(email: email, password: 'irrelevant', displayName: displayName, signedIn: true);

  /// Creates a List named [name] from the Lists screen.
  Future<void> createList(String name) async {
    await tester.tap(find.text('New list').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Name'), name);
    await tester.tap(find.widgetWithText(CesButton, 'Create list'));
    await tester.pumpAndSettle();
  }

  /// Opens the options of the List named [name] on the Lists screen.
  Future<void> openListOptions(String name) async {
    await tester.tap(find.byTooltip('Options for $name'));
    await tester.pumpAndSettle();
  }

  /// Renames the List named [from] to [to] from its options.
  Future<void> renameList(String from, String to) async {
    await openListOptions(from);
    await tester.tap(find.text('Rename'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Name'), to);
    await tester.tap(find.widgetWithText(CesButton, 'Save'));
    await tester.pumpAndSettle();
  }

  /// Starts the app and opens Recently deleted from the account menu.
  Future<void> openRecentlyDeleted({Locale locale = english}) async {
    await pumpApp(locale: locale);
    final inEnglish = locale == english;
    await tester.tap(find.byTooltip(inEnglish ? 'Account' : 'Conta'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(inEnglish ? 'Recently deleted' : 'Excluídas recentemente'));
    await tester.pumpAndSettle();
  }

  /// Deletes the List named [name] from its options.
  Future<void> deleteList(String name) async {
    await openListOptions(name);
    await tester.tap(find.text('Delete list'));
    await tester.pumpAndSettle();
  }

  /// Both the backend and the identity provider become unreachable.
  void goOffline() {
    api.goOffline();
    auth.offline = true;
  }

  Future<void> openEmailSignIn() async {
    await tester.tap(find.text('Already have an account? Sign in'));
    await tester.pumpAndSettle();
  }

  Future<void> signInWithEmail(String email, String password) async {
    await openEmailSignIn();
    await tester.enterText(find.widgetWithText(TextField, 'Email'), email);
    await tester.enterText(find.widgetWithText(TextField, 'Password'), password);
    await tester.tap(find.widgetWithText(CesButton, 'Sign in'));
    await tester.pumpAndSettle();
  }

  Future<void> signUpWithEmail(String email, String password) async {
    await tester.tap(find.text('Continue with email'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Email'), email);
    await tester.enterText(find.widgetWithText(TextField, 'Password'), password);
    await tester.tap(find.widgetWithText(CesButton, 'Create account'));
    await tester.pumpAndSettle();
  }

  Future<void> openAccountMenu() async {
    await tester.tap(find.byTooltip('Account'));
    await tester.pumpAndSettle();
  }

  /// The text in the field labelled [label].
  String textInField(String label) =>
      tester.widget<TextField>(find.widgetWithText(TextField, label)).controller?.text ?? '';
}
