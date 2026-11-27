import 'dart:async';

import 'package:cesta/src/api/generated/cesta_api.dart';
import 'package:flutter_test/flutter_test.dart';

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

  testWidgets('Remove item takes it off the List, and Undo brings it back', (tester) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    final list = h.api.addList(ana, name: 'Weekend feira');
    h.api.addItem(list, name: 'Tomatoes', addedBy: ana, quantity: '1', unit: ItemUnit.kg);
    h.api.addItem(list, name: 'Coffee', addedBy: ana);
    await h.pumpApp();
    await h.openList('Weekend feira');

    await h.openItem('Tomatoes');
    await h.tap(find.text('Remove item'));

    expect(h.tags(), ['Coffee']);
    expect(find.text('Tomatoes removed'), findsOneWidget);
    expect(h.api.itemsToBuy(list), ['Coffee']);

    await h.tap(find.text('Undo'));

    expect(h.tags(), containsAll(['1 kg Tomatoes', 'Coffee']));
    expect(h.api.itemsToBuy(list), containsAll(['Tomatoes', 'Coffee']));
    expect(h.api.serverItem('Tomatoes').quantity?.value, '1');
    expect(h.api.serverItem('Tomatoes').unit?.value, ItemUnit.kg);
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
    expect(
      find.text(
        'A list can hold up to 500 items. Clear checked items, or remove ones you no longer need, to make room.',
      ),
      findsOneWidget,
    );
    expect(find.widgetWithText(CesButton, 'Clear checked'), findsNothing); // Clear checked isn't in the app yet
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
    expect(h.api.itemsToBuy(list), ['Coffee']);
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
}
