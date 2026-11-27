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
    expect(h.tagNames(), ['Tomatoes', 'Bread rolls', 'Coffee']);
    expect(find.text('1 kg'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
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

    expect(h.tagNames(), ['Coffee']);
    expect(h.basketRows(), [('Tomatoes', 'You')]);
    expect(find.text('1 to buy, 1 in the basket'), findsOneWidget);
    expect(h.api.itemsInBasket(list), ['Tomatoes']);

    await h.tapBasketRow('Tomatoes');

    expect(h.tagNames(), ['Tomatoes', 'Coffee']);
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

    expect(h.tagNames(), ['Tomatoes']);
    expect(find.text('2 kg'), findsOneWidget);
    expect(h.basketRows(), [('Coffee', 'You')]);
    expect(h.showsPending, isTrue);
    expect(h.api.itemsToBuy(list), ['Coffee']);

    h.api.goOnline();
    h.auth.offline = false;
    await tester.pump(const Duration(minutes: 1)); // the next retry
    await tester.pumpAndSettle();

    expect(h.showsPending, isFalse);
    expect(h.api.itemsToBuy(list), ['Tomatoes']);
    expect(h.api.itemsInBasket(list), ['Coffee']);
    expect(h.api.serverItem('Tomatoes').quantity, '2');
    expect(h.api.serverItem('Tomatoes').unit, ItemUnit.kg);
    expect(h.tagNames(), ['Tomatoes']);
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

    expect(h.tagNames(), isEmpty);
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

    expect(h.tagNames(), ['Coffee']);
    expect(h.basketRows(), isEmpty);
    expect(find.text('Your change to “Coffee” couldn\'t be saved, so it was undone.'), findsOneWidget);
    expect(h.showsPending, isFalse);
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
}
