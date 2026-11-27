import 'dart:ui' show Tristate;

import 'package:cesta/src/app.dart';
import 'package:cesta/src/db/app_database.dart';
import 'package:cesta/src/ui/components.dart';
import 'package:drift/drift.dart' show DatabaseConnection;
import 'package:drift/native.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'fake_api_client.dart';
import 'fake_auth_gateway.dart';
import 'fields.dart';

export 'package:cesta/src/ui/components.dart'
    show
        CesAddAsNew,
        CesAddBar,
        CesButton,
        CesCheckedItem,
        CesChoiceChip,
        CesItemTile,
        CesMessage,
        CesSearchField,
        CesSoftField,
        CesStatusPill,
        CesStepper;

export 'fake_api_client.dart';
export 'fake_auth_gateway.dart';
export 'fields.dart';

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
  Harness(this.tester)
    : auth = FakeAuthGateway(),
      db = AppDatabase(
        // Close stream queries at once when their listener goes, rather than on a
        // later timer that a widget test's fake clock would never run.
        DatabaseConnection(NativeDatabase.memory(), closeStreamsSynchronously: true),
      ) {
    api = FakeApiClient(auth: auth);
    addTearDown(api.close);
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
    Size screen = iPhone,
  }) async {
    // Unmount any previous instance so restarts start from a clean widget tree.
    await tester.pumpWidget(const SizedBox.shrink());
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = screen;
    addTearDown(tester.view.reset);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpWidget(
      CestaApp(
        api: api,
        auth: auth,
        database: db,
        network: api.network,
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
    await tester.enterText(field('Name'), name);
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
    await tester.enterText(field('Name'), to);
    await tester.tap(find.widgetWithText(CesButton, 'Save'));
    await tester.pumpAndSettle();
  }

  /// Starts the app and opens Recently deleted from the User menu.
  Future<void> openRecentlyDeleted({Locale locale = english}) async {
    await pumpApp(locale: locale);
    final inEnglish = locale == english;
    await tester.tap(find.byTooltip(inEnglish ? 'User menu' : 'Menu do usuário'));
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

  /// The network and both servers become reachable again; waits for the app
  /// to notice and sync.
  Future<void> goOnline() async {
    api.goOnline();
    auth.offline = false;
    await tester.pumpAndSettle();
  }

  /// Scrolls [target] into view, taps it and waits for the app to settle.
  Future<void> tap(Finder target) async {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  /// From the welcome screen: email, then over from sign-up to sign-in.
  Future<void> openEmailSignIn() async {
    await tap(find.text('Continue with email'));
    await tester.tap(find.text('Already have an account? Sign in'));
    await tester.pumpAndSettle();
  }

  Future<void> signInWithEmail(String email, String password) async {
    await openEmailSignIn();
    await tester.enterText(field('Email'), email);
    await tester.enterText(field('Password'), password);
    await tester.tap(find.widgetWithText(CesButton, 'Sign in'));
    await tester.pumpAndSettle();
  }

  Future<void> signUpWithEmail(String email, String password) async {
    await tap(find.text('Continue with email'));
    await tester.enterText(field('Email'), email);
    await tester.enterText(field('Password'), password);
    await tester.tap(find.widgetWithText(CesButton, 'Create account'));
    await tester.pumpAndSettle();
  }

  /// A first-time User signs in with Google as [email] and lands on the
  /// display name screen, which suggests [name].
  Future<void> signInWithGoogleForTheFirstTime({String email = 'ana@example.com', String name = 'Ana Souza'}) async {
    auth.googleAccount = FakeGoogleAccount(email: email, name: name);
    await pumpApp();
    await tap(find.text('Continue with Google'));
  }

  Future<void> openUserMenu() async {
    await tester.tap(find.byTooltip('User menu'));
    await tester.pumpAndSettle();
  }

  /// Signs out from the User menu.
  Future<void> signOut() async {
    await openUserMenu();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
  }

  /// Opens the List named [name] from the Lists screen.
  Future<void> openList(String name) => tap(find.text(name));

  /// The Item tags to buy, in order, as they read on screen: the quantity,
  /// if any, then the name (e.g. "1 kg Tomatoes").
  List<String> tags() => [for (final n in find.semantics.byHint(_check).evaluate()) n.label];

  /// The rows In the basket, in order: each Checked Item's name and who
  /// checked it, as they read on screen.
  List<(String, String)> basketRows() => [
    for (final n in find.semantics.byHint(_uncheck).evaluate())
      switch (n.label.split('\n')) {
        [final name, final checkedBy] => (name, checkedBy),
        final other => throw StateError('Unexpected basket row: $other'),
      },
  ];

  /// The tags under Matches on Add items, in order, each as its label reads
  /// ("2 L leite").
  List<String> matches() => [for (final n in find.semantics.byHint(_open).evaluate()) n.label];

  /// What tapping a tag or a basket row does, as screen readers say it.
  static final _check = RegExp(r'^(Check|Marcar como comprado)$');
  static final _open = RegExp(r'^(Open|Abrir)$');
  static final _uncheck = RegExp(r'^(Uncheck|Desmarcar)$');

  /// From a List's screen, adds a new Item named [name] through Add items and
  /// the New item sheet, pressing + [steps] times and picking [unit] (as its
  /// chip reads); stays on Add items.
  Future<void> addNewItem(String name, {required String listName, int steps = 0, String? unit}) async {
    if (find.byType(CesSearchField).evaluate().isEmpty) await tap(find.text('Add an item'));
    await search(name);
    await tap(find.text('Add “$name” as a new item'));
    for (var i = 0; i < steps; i++) {
      await tap(find.bySemanticsLabel('More'));
    }
    if (unit != null) await tap(find.widgetWithText(CesChoiceChip, unit));
    await tap(find.widgetWithText(CesButton, 'Add to $listName'));
  }

  /// Types [text] in Add items' search field.
  Future<void> search(String text) async {
    await tester.enterText(find.descendant(of: find.byType(CesSearchField), matching: find.byType(EditableText)), text);
    await tester.pumpAndSettle();
  }

  /// Taps the tag of the Item named [name] (checks it).
  Future<void> tapTag(String name) => tap(find.widgetWithText(CesItemTile, name));

  /// Long-presses the tag of the Item named [name] (opens it).
  Future<void> openItem(String name) async {
    await tester.longPress(find.widgetWithText(CesItemTile, name));
    await tester.pumpAndSettle();
  }

  /// The quantity typed in the open Item sheet's stepper.
  String get quantityText => tester
      .widget<EditableText>(find.descendant(of: find.byType(CesStepper), matching: find.byType(EditableText)))
      .controller
      .text;

  /// The label of the selected unit chip, or null.
  String? get selectedUnit =>
      find.semantics.byPredicate((n) => n.flagsCollection.isSelected == Tristate.isTrue).evaluate().firstOrNull?.label;

  /// The note field of the open Item sheet.
  Finder get noteField => find.descendant(of: find.byType(CesSoftField), matching: find.byType(EditableText));

  String get noteText => tester.widget<EditableText>(noteField).controller.text;

  /// Taps the In the basket row of the Item named [name] (unchecks it).
  Future<void> tapBasketRow(String name) => tap(find.widgetWithText(CesCheckedItem, name));

  /// The text in the field labelled [label].
  String textInField(String label) => fieldController(tester, label).text;
}
