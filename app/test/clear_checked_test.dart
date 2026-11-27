import 'package:cesta/src/api/generated/cesta_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'harness/harness.dart';

void main() {
  testWidgets('offline, Clear checked takes the Checked Items off the List at once, and syncs on reconnect', (
    tester,
  ) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    final rui = h.existingUser(email: 'rui@example.com', password: 'x', displayName: 'Rui');
    final list = h.api.addList(ana, name: 'Weekend feira', sharedWith: [rui]);
    h.api.addItem(list, name: 'Tomatoes', addedBy: ana);
    h.api.addItem(list, name: 'Bananas', addedBy: ana, checkedBy: rui);
    h.api.addItem(list, name: 'Cookies', addedBy: ana, checkedBy: ana);
    await h.pumpApp();
    await h.openList('Weekend feira');
    h.goOffline();

    await h.tap(find.text('Clear checked'));

    expect(h.basketRows(), isEmpty);
    expect(find.text('In the basket'), findsNothing);
    expect(find.text('Clear checked'), findsNothing);
    expect(h.tags(), ['Tomatoes']);
    expect(find.text('1 to buy, 0 in the basket'), findsOneWidget);
    expect(find.text('Offline · 2 changes waiting to sync'), findsOneWidget);
    expect(h.api.itemsInBasket(list), ['Bananas', 'Cookies']);

    await h.goOnline();

    expect(find.byType(CesStatusPill), findsNothing);
    expect(h.api.itemsInBasket(list), isEmpty);
    expect(h.api.itemsToBuy(list), ['Tomatoes']);
    expect(h.basketRows(), isEmpty);
    expect(h.tags(), ['Tomatoes']);
  });

  testWidgets('cleared Items are in the List’s Item history after sync, most recent first, with what was bought', (
    tester,
  ) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    final rui = h.existingUser(email: 'rui@example.com', password: 'x', displayName: 'Rui');
    final list = h.api.addList(ana, name: 'Weekend feira', sharedWith: [rui]);
    final other = h.api.addList(ana, name: 'Pharmacy');
    h.api.addItem(list, name: 'Rice', addedBy: rui, quantity: '1.5', unit: ItemUnit.kg, note: 'brown', checkedBy: rui);
    h.api.addItem(list, name: 'Tomatoes', addedBy: ana);
    h.api.addItem(list, name: 'Bananas', addedBy: ana, checkedBy: ana);
    h.api.addItem(other, name: 'Plasters', addedBy: ana, checkedBy: ana);
    h.api.clearCheckedNow(list, by: rui); // on Rui's phone, before Ana opens the app
    h.api.checkItemNow('Tomatoes', by: ana);
    h.api.clearCheckedNow(other, by: ana);
    await h.pumpApp();
    await h.openList('Weekend feira');

    await h.tap(find.text('Clear checked'));

    final history = await h.itemHistory(list);
    expect(
      [for (final e in history) (e.name, e.quantity, e.unit, e.note, e.clearedBy.displayName)],
      [
        ('Tomatoes', null, null, null, 'Ana Souza'),
        ('Bananas', null, null, null, 'Rui'),
        ('Rice', '1.5', ItemUnit.kg, 'brown', 'Rui'),
      ],
    );
    expect([for (final e in await h.itemHistory(other)) e.name], ['Plasters']);
  });

  testWidgets('an Item put back to buy on another phone before Clear checked synced stays on the List, and says so', (
    tester,
  ) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    final rui = h.existingUser(email: 'rui@example.com', password: 'x', displayName: 'Rui');
    final list = h.api.addList(ana, name: 'Weekend feira', sharedWith: [rui]);
    h.api.addItem(list, name: 'Bananas', addedBy: ana, checkedBy: ana);
    h.api.addItem(list, name: 'Cookies', addedBy: ana, checkedBy: ana);
    await h.pumpApp();
    await h.openList('Weekend feira');
    h.goOffline();

    await h.tap(find.text('Clear checked'));
    h.api.uncheckItemNow('Bananas', by: rui);
    await h.goOnline();

    expect(find.text('Couldn’t clear “Bananas”. It’s no longer checked.'), findsOneWidget);
    expect(h.tags(), ['Bananas']);
    expect(h.basketRows(), isEmpty);
    expect(h.api.itemsToBuy(list), ['Bananas']);
    expect([for (final e in await h.itemHistory(list)) e.name], ['Cookies']);
  });

  testWidgets('a refused check is reported once, not again for the Clear checked that followed it', (tester) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    final list = h.api.addList(ana, name: 'Weekend feira');
    h.api.addItem(list, name: 'Coffee', addedBy: ana);
    h.api.addItem(list, name: 'Rice', addedBy: ana);
    await h.pumpApp();
    await h.openList('Weekend feira');
    h.goOffline();

    await h.tapTag('Coffee');
    await h.tap(find.text('Clear checked'));
    h.api
      ..rejectMutations = ApiErrorCode.invalidItem
      ..rejectOnly = {MutationType.itemUpdate}; // the check, not the clear
    await h.goOnline();

    expect(find.text('Couldn’t save “Coffee”.'), findsOneWidget);
    expect(find.text('Couldn’t clear “Coffee”. It’s no longer checked.'), findsNothing);
    expect(h.tags(), ['Coffee', 'Rice']);
    expect(h.api.itemsToBuy(list), ['Coffee', 'Rice']);
  });

  testWidgets('a full List with Checked Items offers Clear checked, which makes room', (tester) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    final list = h.api.addList(ana, name: 'Weekend feira');
    h.api.addItem(list, name: 'Bananas', addedBy: ana, checkedBy: ana);
    for (var i = 0; i < 499; i++) {
      h.api.addItem(list, name: 'Item $i', addedBy: ana);
    }
    await h.pumpApp();
    await h.openList('Weekend feira');

    await h.tap(find.text('Add an item'));

    expect(find.text('This list is full'), findsOneWidget);
    expect(
      find.text(
        'A list can hold up to 500 items. Clear checked items, or remove ones you no longer need, to make room.',
      ),
      findsOneWidget,
    );

    await h.tap(find.widgetWithText(CesButton, 'Clear checked'));

    expect(find.text('This list is full'), findsNothing);
    expect(h.basketRows(), isEmpty);
    expect(h.api.itemsInBasket(list), isEmpty);
    await h.tap(find.text('Add an item'));
    expect(find.byType(CesSearchField), findsOneWidget);
  });

  testWidgets('the Item limit sheet the server’s refusal opens offers Clear checked too, in Portuguese', (
    tester,
  ) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    final list = h.api.addList(ana, name: 'Feira');
    h.api.addItem(list, name: 'Café', addedBy: ana, checkedBy: ana);
    h.api.itemLimit = 1; // filled up from another phone meanwhile
    await h.pumpApp(locale: brazilianPortuguese);
    await h.openList('Feira');
    expect(find.text('Limpar marcados'), findsOneWidget);

    await h.tap(find.text('Adicionar um item'));
    await h.search('Arroz');
    await h.tap(find.text('Adicionar “Arroz” como novo item'));
    await h.tap(find.widgetWithText(CesButton, 'Adicionar a Feira'));

    expect(find.text('Esta lista está cheia'), findsOneWidget);
    expect(
      find.text(
        'Uma lista pode ter até 1 itens. Limpe os itens marcados ou remova os que você não precisa mais para abrir espaço.',
      ),
      findsOneWidget,
    );
    await h.tap(find.widgetWithText(CesButton, 'Limpar marcados'));

    expect(find.text('Esta lista está cheia'), findsNothing);
    expect(h.api.itemsInBasket(list), isEmpty);
  });

  testWidgets('a deleted List’s Item history goes with it, and signing out leaves none behind', (tester) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    final feira = h.api.addList(ana, name: 'Weekend feira');
    final pharmacy = h.api.addList(ana, name: 'Pharmacy');
    h.api.addItem(feira, name: 'Bananas', addedBy: ana, checkedBy: ana);
    h.api.addItem(pharmacy, name: 'Plasters', addedBy: ana, checkedBy: ana);
    h.api.clearCheckedNow(feira, by: ana);
    h.api.clearCheckedNow(pharmacy, by: ana);
    await h.pumpApp();
    await h.openList('Weekend feira');
    expect([for (final e in await h.itemHistory(feira)) e.name], ['Bananas']);

    h.api.deleteListNow(feira); // on another phone
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 300)); // pull to refresh
    await tester.pumpAndSettle();

    expect(await h.itemHistory(feira), isEmpty);
    expect([for (final e in await h.itemHistory(pharmacy)) e.name], ['Plasters']);

    await h.tap(find.byTooltip('Back'));
    await h.signOut();

    expect(await h.itemHistory(pharmacy), isEmpty);
  });
}
