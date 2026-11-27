import 'dart:async';

import 'package:cesta/src/api/generated/cesta_api.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'harness/harness.dart';

void main() {
  testWidgets('opening a List shows its Items to buy and those in the basket, with who checked them', (tester) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    final rui = h.existingUser(email: 'rui@example.com', password: 'x', displayName: 'Rui');
    final list = h.api.addList(ana, name: 'Weekend feira', sharedWith: [rui]);
    h.api.addItem(list, name: 'Tomatoes', addedBy: ana, quantity: '1', unit: ItemUnit.kg);
    h.api.addItem(list, name: 'Bread rolls', addedBy: rui, quantity: '10', unit: ItemUnit.un);
    h.api.addItem(list, name: 'Coffee', addedBy: ana);
    h.api.addItem(list, name: 'Bananas', addedBy: ana, checkedBy: rui);
    h.api.addItem(list, name: 'Cookies', addedBy: ana, checkedBy: ana);

    await h.pumpApp();
    await h.openList('Weekend feira');

    expect(find.text('Weekend feira'), findsOneWidget);
    expect(find.text('3 to buy, 2 in the basket'), findsOneWidget);
    expect(h.tags(), ['1 kg Tomatoes', '10 Bread rolls', 'Coffee']);
    expect(h.basketRows(), [('Bananas', 'Rui'), ('Cookies', 'You')]);
  });

  testWidgets('tapping a tag checks the Item into the basket, and tapping it there unchecks it', (tester) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    final list = h.api.addList(ana, name: 'Weekend feira');
    h.api.addItem(list, name: 'Tomatoes', addedBy: ana);
    h.api.addItem(list, name: 'Coffee', addedBy: ana);
    await h.pumpApp();
    await h.openList('Weekend feira');

    await h.tapTag('Tomatoes');

    expect(h.tags(), ['Coffee']);
    expect(h.basketRows(), [('Tomatoes', 'You')]);
    expect(find.text('1 to buy, 1 in the basket'), findsOneWidget);
    expect(h.api.itemsInBasket(list), ['Tomatoes']);

    await h.tapBasketRow('Tomatoes');

    expect(h.tags(), ['Tomatoes', 'Coffee']);
    expect(h.basketRows(), isEmpty);
    expect(h.api.itemsInBasket(list), isEmpty);
  });

  testWidgets('offline, added and checked Items show at once, and sync after reconnecting', (tester) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    final list = h.api.addList(ana, name: 'Weekend feira');
    h.api.addItem(list, name: 'Coffee', addedBy: ana);
    await h.pumpApp();
    await h.openList('Weekend feira');
    h.goOffline();

    await h.addNewItem('Tomatoes', listName: 'Weekend feira', steps: 2, unit: 'kg');
    await h.tap(find.text('Done'));
    await h.tapTag('Coffee');

    expect(h.tags(), ['2 kg Tomatoes']);
    expect(h.basketRows(), [('Coffee', 'You')]);
    expect(find.text('Offline · 2 changes waiting to sync'), findsOneWidget);
    expect(h.api.itemsToBuy(list), ['Coffee']);

    await h.goOnline();

    expect(find.byType(CesStatusPill), findsNothing);
    expect(h.api.itemsToBuy(list), ['Tomatoes']);
    expect(h.api.itemsInBasket(list), ['Coffee']);
    expect(h.api.serverItem('Tomatoes').quantity?.value, '2');
    expect(h.api.serverItem('Tomatoes').unit?.value, ItemUnit.kg);
    expect(h.tags(), ['2 kg Tomatoes']);
    expect(h.basketRows(), [('Coffee', 'You')]);
  });

  testWidgets('Undo on the "added" Toast removes the Item just added', (tester) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    final list = h.api.addList(ana, name: 'Weekend feira');
    await h.pumpApp();
    await h.openList('Weekend feira');

    await h.addNewItem('Tomatoes', listName: 'Weekend feira');
    expect(find.text('Tomatoes added to Weekend feira'), findsOneWidget);
    await h.tap(find.text('Undo'));
    await h.tap(find.text('Done'));

    expect(h.tags(), isEmpty);
    expect(h.api.itemsToBuy(list), isEmpty);
  });

  testWidgets('offline, Undo of an add leaves nothing waiting to sync', (tester) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    final list = h.api.addList(ana, name: 'Weekend feira');
    h.api.addItem(list, name: 'Coffee', addedBy: ana);
    await h.pumpApp();
    await h.openList('Weekend feira');
    h.goOffline();

    await h.addNewItem('Tomatoes', listName: 'Weekend feira');
    await h.addNewItem('Bread', listName: 'Weekend feira');
    await h.tap(find.text('Undo'));
    await h.tap(find.text('Done'));

    expect(h.tags(), ['Coffee', 'Tomatoes']);
    expect(find.text('Offline · 1 change waiting to sync'), findsOneWidget);
    await h.goOnline();
    expect(h.api.itemsToBuy(list), ['Coffee', 'Tomatoes']);
  });

  for (final (locale, typed, less, stepped) in [
    (english, '2.3', 'Less', '1.3'),
    (brazilianPortuguese, '2,3', 'Menos', '1,3'),
  ]) {
    testWidgets('stepping a typed decimal keeps it exact ($locale)', (tester) async {
      final h = Harness(tester);
      final ana = h.signedIn();
      h.api.addList(ana, name: 'Feira');
      await h.pumpApp(locale: locale);
      await h.openList('Feira');
      await h.tap(find.byType(CesAddBar));
      await h.search('Cheese');
      await h.tap(find.byType(CesAddAsNew));
      final quantity = find.descendant(of: find.byType(CesStepper), matching: find.byType(EditableText));

      await tester.enterText(quantity, typed);
      await h.tap(find.bySemanticsLabel(less));

      expect(tester.widget<EditableText>(quantity).controller.text, stepped);
    });
  }

  testWidgets('a change the server rejects is rolled back with a message', (tester) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    final list = h.api.addList(ana, name: 'Weekend feira');
    h.api.addItem(list, name: 'Coffee', addedBy: ana);
    await h.pumpApp();
    await h.openList('Weekend feira');
    h.api.rejectMutations = ApiErrorCode.listNotFound;

    await h.tapTag('Coffee');

    expect(h.tags(), ['Coffee']);
    expect(h.basketRows(), isEmpty);
    expect(find.text('Couldn’t save “Coffee”. The list is no longer available.'), findsOneWidget);
    expect(find.byType(CesStatusPill), findsNothing);
  });

  testWidgets('pulling down shows changes made on another phone', (tester) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    final rui = h.existingUser(email: 'rui@example.com', password: 'x', displayName: 'Rui');
    final list = h.api.addList(ana, name: 'Weekend feira', sharedWith: [rui]);
    h.api.addItem(list, name: 'Coffee', addedBy: ana);
    await h.pumpApp();
    await h.openList('Weekend feira');

    h.api.checkItemNow('Coffee', by: rui);
    await tester.fling(find.text('Weekend feira'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(h.basketRows(), [('Coffee', 'Rui')]);
  });

  testWidgets('long-pressing a tag opens the Item; Save sends the edits and clears emptied fields', (tester) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    final list = h.api.addList(ana, name: 'Weekend feira');
    h.api.addItem(list, name: 'Tomatoes', addedBy: ana, quantity: '1', unit: ItemUnit.kg, note: 'Ripe ones');
    await h.pumpApp();
    await h.openList('Weekend feira');

    await h.openItem('Tomatoes');

    expect(find.text('Edit item'), findsOneWidget);
    expect(h.textInField('Name'), 'Tomatoes');
    expect(h.quantityText, '1');
    expect(h.selectedUnit, 'kg');
    expect(h.noteText, 'Ripe ones');
    expect(find.text('Added by you'), findsOneWidget);
    expect(find.textContaining('Checked by'), findsNothing);

    await tester.enterText(field('Name'), 'Cherry tomatoes');
    await h.tap(find.bySemanticsLabel('Less')); // 1 → no quantity
    await h.tap(find.widgetWithText(CesChoiceChip, 'kg')); // unselect
    await tester.enterText(h.noteField, '');
    await h.tap(find.widgetWithText(CesButton, 'Save'));

    expect(find.text('Edit item'), findsNothing);
    expect(h.tags(), ['Cherry tomatoes']);
    final saved = h.api.serverItem('Cherry tomatoes');
    expect(saved.quantity?.value, isNull);
    expect(saved.unit?.value, isNull);
    expect(saved.note?.value, isNull);
  });

  testWidgets('long-pressing a basket row opens the Item, saying who added and who checked it', (tester) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    final rui = h.existingUser(email: 'rui@example.com', password: 'x', displayName: 'Rui');
    final list = h.api.addList(ana, name: 'Weekend feira', sharedWith: [rui]);
    h.api.addItem(list, name: 'Milk', addedBy: rui, checkedBy: rui);
    await h.pumpApp();
    await h.openList('Weekend feira');

    await tester.longPress(find.widgetWithText(CesCheckedItem, 'Milk'));
    await tester.pumpAndSettle();

    expect(find.text('Edit item'), findsOneWidget);
    expect(find.text('Added by Rui'), findsOneWidget);
    expect(find.text('Checked by Rui'), findsOneWidget);

    await h.tap(find.widgetWithText(CesButton, 'Save')); // nothing changed: nothing to send
    expect(h.api.itemsInBasket(list), ['Milk']);
  });

  testWidgets('Remove item takes it off the List, and Undo brings it back with no remove synced', (tester) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    final list = h.api.addList(ana, name: 'Weekend feira');
    final tomatoes = h.api.addItem(list, name: 'Tomatoes', addedBy: ana, quantity: '1', unit: ItemUnit.kg);
    h.api.addItem(list, name: 'Coffee', addedBy: ana);
    await h.pumpApp();
    await h.openList('Weekend feira');

    await h.openItem('Tomatoes');
    await h.tap(find.text('Remove item'));

    expect(h.tags(), ['Coffee']);
    expect(find.text('Tomatoes removed'), findsOneWidget);
    expect(h.api.itemsToBuy(list), ['Tomatoes', 'Coffee']); // held while Undo is offered

    await h.tap(find.text('Undo'));
    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();

    expect(h.tags(), ['1 kg Tomatoes', 'Coffee']);
    expect(h.api.itemsToBuy(list), ['Tomatoes', 'Coffee']);
    expect(h.api.serverItem('Tomatoes').id, tomatoes); // the same Item, never removed
  });

  testWidgets('a removal not undone is synced once the Undo Toast closes', (tester) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    final list = h.api.addList(ana, name: 'Weekend feira');
    h.api.addItem(list, name: 'Tomatoes', addedBy: ana);
    h.api.addItem(list, name: 'Coffee', addedBy: ana);
    await h.pumpApp();
    await h.openList('Weekend feira');

    await h.openItem('Tomatoes');
    await h.tap(find.text('Remove item'));
    await h.tapTag('Coffee'); // a later change syncs while the removal waits

    expect(h.api.itemsToBuy(list), ['Tomatoes']);
    expect(h.api.itemsInBasket(list), ['Coffee']);

    await tester.pump(const Duration(seconds: 10));
    await tester.pumpAndSettle();

    expect(find.text('Tomatoes removed'), findsNothing);
    expect(h.tags(), isEmpty);
    expect(h.api.itemsToBuy(list), isEmpty);
    expect(h.api.itemsInBasket(list), ['Coffee']);
  });

  testWidgets('signing out while Undo is offered takes the Undo away with the session', (tester) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    final list = h.api.addList(ana, name: 'Weekend feira');
    h.api.addItem(list, name: 'Tomatoes', addedBy: ana);
    await h.pumpApp();
    await h.openList('Weekend feira');

    await h.openItem('Tomatoes');
    await h.tap(find.text('Remove item'));
    await h.tap(find.byTooltip('Back'));
    await h.signOut();

    expect(find.text('Undo'), findsNothing);
  });

  testWidgets('online, an Item removed just before signing out stays removed', (tester) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    final list = h.api.addList(ana, name: 'Weekend feira');
    h.api.addItem(list, name: 'Tomatoes', addedBy: ana);
    h.api.addItem(list, name: 'Coffee', addedBy: ana);
    await h.pumpApp();
    await h.openList('Weekend feira');

    await h.openItem('Tomatoes');
    await h.tap(find.text('Remove item'));
    await h.tap(find.byTooltip('Back'));
    await h.signOut(); // while Undo is still offered

    expect(h.api.itemsToBuy(list), ['Coffee']);
  });

  testWidgets('offline, Undo of a removal just drops the waiting change', (tester) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    final list = h.api.addList(ana, name: 'Weekend feira');
    h.api.addItem(list, name: 'Tomatoes', addedBy: ana);
    h.api.addItem(list, name: 'Coffee', addedBy: ana);
    await h.pumpApp();
    await h.openList('Weekend feira');
    h.goOffline();

    await h.openItem('Tomatoes');
    await h.tap(find.text('Remove item'));
    expect(find.text('Offline · 1 change waiting to sync'), findsOneWidget);
    await h.tap(find.text('Undo'));

    expect(h.tags(), ['Tomatoes', 'Coffee']);
    expect(find.text('Offline'), findsOneWidget);
    await h.goOnline();
    expect(h.api.itemsToBuy(list), ['Tomatoes', 'Coffee']);
  });

  testWidgets('an edit to an Item someone else removed is not saved, and says so', (tester) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    final list = h.api.addList(ana, name: 'Weekend feira');
    h.api.addItem(list, name: 'Milk', addedBy: ana);
    h.api.addItem(list, name: 'Coffee', addedBy: ana);
    await h.pumpApp();
    await h.openList('Weekend feira');
    h.api.removeItemNow('Milk'); // on another phone; this one hasn't pulled yet

    await h.tapTag('Milk');

    expect(find.text('Couldn’t save “Milk”. It was removed.'), findsOneWidget);
    expect(h.tags(), ['Coffee']);
    expect(h.basketRows(), isEmpty);
  });

  testWidgets('a full List says so instead of opening Add items', (tester) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    final list = h.api.addList(ana, name: 'Weekend feira');
    for (var i = 0; i < 500; i++) {
      h.api.addItem(list, name: 'Item $i', addedBy: ana);
    }
    await h.pumpApp();
    await h.openList('Weekend feira');

    await h.tap(find.text('Add an item'));

    expect(find.text('This list is full'), findsOneWidget);
    expect(find.text('A list can hold up to 500 items. Remove ones you no longer need to make room.'), findsOneWidget);
    expect(find.widgetWithText(CesButton, 'Clear checked'), findsNothing); // nothing is checked
    expect(find.byType(CesSearchField), findsNothing);

    await h.tap(find.byTooltip('Close'));
    expect(find.text('This list is full'), findsNothing);
  });

  testWidgets('an Item the server refuses because the List is full shows the limit sheet', (tester) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    final list = h.api.addList(ana, name: 'Weekend feira');
    h.api.addItem(list, name: 'Coffee', addedBy: ana);
    h.api.itemLimit = 1; // filled up from another phone meanwhile
    await h.pumpApp();
    await h.openList('Weekend feira');

    await h.addNewItem('Tomatoes', listName: 'Weekend feira');

    expect(find.text('This list is full'), findsOneWidget);
    expect(find.text('A list can hold up to 1 items. Remove ones you no longer need to make room.'), findsOneWidget);
    expect(h.api.itemsToBuy(list), ['Coffee']);

    // The limit the server reported is the one the app now checks.
    await h.tap(find.byTooltip('Close'));
    await h.tap(find.text('Done'));
    await h.tap(find.text('Add an item'));
    expect(find.text('This list is full'), findsOneWidget);
  });

  testWidgets('an empty List invites adding the first Item', (tester) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    h.api.addList(ana, name: 'Weekend feira');
    await h.pumpApp();
    await h.openList('Weekend feira');

    expect(find.text('Nothing to buy yet'), findsOneWidget);
    expect(find.text('Start your list'), findsOneWidget);
    expect(find.text('Add what you need. Everyone on this list sees it right away.'), findsOneWidget);
    expect(h.tags(), isEmpty);

    await h.addNewItem('Tomatoes', listName: 'Weekend feira');
    await h.tap(find.text('Done'));

    expect(find.text('Start your list'), findsNothing);
    expect(find.text('1 to buy, 0 in the basket'), findsOneWidget);
  });

  testWidgets('the Opened item, offline pill and empty List read in Portuguese', (tester) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    final rui = h.existingUser(email: 'rui@example.com', password: 'x', displayName: 'Rui');
    final list = h.api.addList(ana, name: 'Feira', sharedWith: [rui]);
    h.api.addItem(list, name: 'Arroz', addedBy: rui, quantity: '1.5', unit: ItemUnit.kg, checkedBy: ana);
    h.api.addList(ana, name: 'Vazia');
    await h.pumpApp(locale: brazilianPortuguese);
    await h.openList('Feira');

    await tester.longPress(find.widgetWithText(CesCheckedItem, 'Arroz'));
    await tester.pumpAndSettle();
    expect(find.text('Editar item'), findsOneWidget);
    expect(h.quantityText, '1,5');
    expect(find.text('Adicionado por Rui'), findsOneWidget);
    expect(find.text('Marcado por você'), findsOneWidget);
    expect(find.text('Salvar'), findsOneWidget);
    await h.tap(find.text('Remover item'));
    expect(find.text('Arroz removido'), findsOneWidget);

    h.goOffline();
    await h.tap(find.text('Desfazer'));
    expect(find.text('Sem conexão'), findsOneWidget); // Undo just dropped the removal
    await h.tapBasketRow('Arroz');
    await h.tapTag('Arroz');
    expect(find.text('Sem conexão · 2 alterações aguardando sincronização'), findsOneWidget);

    await h.tap(find.byTooltip('Voltar'));
    await h.openList('Vazia');
    expect(find.text('Nada para comprar ainda'), findsOneWidget);
    expect(find.text('Comece sua lista'), findsOneWidget);
  });

  testWidgets('the List, Add items and New item read in Portuguese', (tester) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    final list = h.api.addList(ana, name: 'Feira');
    h.api.addItem(list, name: 'Arroz', addedBy: ana, quantity: '1.5', unit: ItemUnit.kg);
    h.api.addItem(list, name: 'Café', addedBy: ana, checkedBy: ana);
    await h.pumpApp(locale: brazilianPortuguese);
    await h.openList('Feira');

    expect(find.text('1 a comprar, 1 na cesta'), findsOneWidget);
    expect(find.text('1,5 kg'), findsOneWidget);
    expect(find.text('Na cesta'), findsOneWidget);
    expect(h.basketRows(), [('Café', 'Você')]);

    await h.tap(find.text('Adicionar um item'));
    await h.search('Leite');
    await h.tap(find.text('Adicionar “Leite” como novo item'));

    expect(find.text('Novo item'), findsOneWidget);
    expect(find.text('Quantidade'), findsOneWidget);
    expect(find.text('Adicionar a Feira'), findsOneWidget);
    expect(find.widgetWithText(CesChoiceChip, 'un'), findsOneWidget);
  });

  testWidgets('a sync still in flight when a User signs out leaves nothing behind for the next User', (tester) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    final bruno = h.existingUser(email: 'bruno@example.com', password: 'secret123', displayName: 'Bruno');
    final brunos = h.api.addList(bruno, name: 'Bruno’s groceries');
    h.api.addItem(brunos, name: 'Milk', addedBy: bruno);
    final anas = h.api.addList(ana, name: 'Weekend feira');
    h.api.addItem(anas, name: 'Coffee', addedBy: ana);
    h.api.slowSync = Completer();
    await h.pumpApp();

    await h.signOut();
    h.api.slowSync!.complete(); // Ana's pull arrives after she signed out
    h.api.slowSync = null;
    await tester.pumpAndSettle();
    await h.signInWithEmail('bruno@example.com', 'secret123');
    await h.openList('Bruno’s groceries');

    expect(h.tags(), ['Milk']);
  });

  testWidgets('a refused new Item is reported once, not again for each later change to it', (tester) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    final list = h.api.addList(ana, name: 'Weekend feira');
    h.api.addItem(list, name: 'Coffee', addedBy: ana);
    await h.pumpApp();
    await h.openList('Weekend feira');
    h.goOffline();
    await h.addNewItem('Tomatoes', listName: 'Weekend feira');
    await h.tap(find.text('Done'));
    await h.tapTag('Tomatoes');
    await h.tapBasketRow('Tomatoes');
    h.api.itemLimit = 1; // filled up from another phone meanwhile

    await h.goOnline();

    expect(find.text('This list is full'), findsOneWidget);
    expect(find.textContaining('Couldn’t save'), findsNothing);
    await h.tap(find.byTooltip('Close'));
    expect(h.tags(), ['Coffee']);
    expect(h.basketRows(), isEmpty);
  });

  testWidgets('the offline pill counts only the changes waiting on the List shown', (tester) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    final feira = h.api.addList(ana, name: 'Weekend feira');
    h.api.addItem(feira, name: 'Coffee', addedBy: ana);
    h.api.addList(ana, name: 'Pharmacy');
    await h.pumpApp();
    await h.openList('Weekend feira');
    h.goOffline();
    await h.tapTag('Coffee');
    expect(find.text('Offline · 1 change waiting to sync'), findsOneWidget);

    await h.tap(find.byTooltip('Back'));
    await h.openList('Pharmacy');

    expect(find.text('Offline'), findsOneWidget);
  });

  testWidgets('opening a List shows the changes other Members made since', (tester) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    final rui = h.existingUser(email: 'rui@example.com', password: 'x', displayName: 'Rui');
    final list = h.api.addList(ana, name: 'Weekend feira', sharedWith: [rui]);
    h.api.addItem(list, name: 'Coffee', addedBy: ana);
    await h.pumpApp();

    h.api.checkItemNow('Coffee', by: rui);
    await h.openList('Weekend feira');

    expect(h.basketRows(), [('Coffee', 'Rui')]);
  });

  for (final status in [400, 403]) {
    testWidgets('a push the server refuses outright ($status) is rolled back with a message, and later changes sync', (
      tester,
    ) async {
      final h = Harness(tester);
      final ana = h.signedIn();
      final list = h.api.addList(ana, name: 'Weekend feira');
      h.api.addItem(list, name: 'Coffee', addedBy: ana);
      h.api.addItem(list, name: 'Milk', addedBy: ana);
      await h.pumpApp();
      await h.openList('Weekend feira');
      h.api.refusePushes = status;

      await h.tapTag('Coffee');

      expect(find.text('Couldn’t save “Coffee”.'), findsOneWidget);
      expect(h.tags(), ['Coffee', 'Milk']);

      h.api.refusePushes = null;
      await h.tapTag('Milk');

      expect(h.api.itemsInBasket(list), ['Milk']);
    });
  }

  testWidgets('a push the server can’t take right now (503) waits and syncs once it can', (tester) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    final list = h.api.addList(ana, name: 'Weekend feira');
    h.api.addItem(list, name: 'Coffee', addedBy: ana);
    await h.pumpApp();
    await h.openList('Weekend feira');
    h.api.refusePushes = 503;

    await h.tapTag('Coffee');

    expect(find.textContaining('Couldn’t save'), findsNothing);
    expect(h.basketRows(), [('Coffee', 'You')]);

    h.api.refusePushes = null;
    await tester.pump(const Duration(seconds: 2)); // the next retry
    await tester.pumpAndSettle();

    expect(h.api.itemsInBasket(list), ['Coffee']);
  });
  testWidgets('typing in Add items highlights the List’s Item under Matches; tapping it opens that Item', (
    tester,
  ) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    final list = h.api.addList(ana, name: 'Weekend feira');
    h.api.addItem(list, name: 'leite', addedBy: ana, quantity: '2', unit: ItemUnit.l);
    h.api.addItem(list, name: 'Coffee', addedBy: ana);
    await h.pumpApp();
    await h.openList('Weekend feira');
    await h.tap(find.text('Add an item'));

    await h.search('Leite');

    expect(find.text('Matches'), findsOneWidget);
    expect(h.matches(), ['2 L leite']);

    await h.tap(find.widgetWithText(CesItemTile, 'leite'));

    expect(find.text('Edit item'), findsOneWidget);
    expect(h.textInField('Name'), 'leite');
    expect(find.text('Added by you'), findsOneWidget);
    expect(h.api.itemsToBuy(list), ['leite', 'Coffee']);
  });

  testWidgets('"Add “…” as a new item" still adds a second Item when one matches', (tester) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    final list = h.api.addList(ana, name: 'Weekend feira');
    h.api.addItem(list, name: 'leite', addedBy: ana);
    await h.pumpApp();
    await h.openList('Weekend feira');

    await h.addNewItem('Leite', listName: 'Weekend feira');
    await h.tap(find.text('Done'));

    expect(h.tags(), ['leite', 'Leite']);
    expect(h.api.itemsToBuy(list), ['leite', 'Leite']);
  });

  testWidgets('Matches ignore case and accents, and leave out what is In the basket', (tester) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    final list = h.api.addList(ana, name: 'Feira');
    h.api.addItem(list, name: 'Pão de forma', addedBy: ana);
    h.api.addItem(list, name: 'Pãozinho', addedBy: ana, checkedBy: ana);
    h.api.addItem(list, name: 'Arroz', addedBy: ana);
    await h.pumpApp(locale: brazilianPortuguese);
    await h.openList('Feira');
    await h.tap(find.text('Adicionar um item'));

    await h.search('PAO');

    expect(find.text('Resultados'), findsOneWidget);
    expect(h.matches(), ['Pão de forma']);

    await h.search('feijão');

    expect(find.text('Resultados'), findsNothing);
    expect(h.matches(), isEmpty);
  });
}
