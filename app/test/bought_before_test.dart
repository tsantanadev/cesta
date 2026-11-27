import 'package:cesta/src/api/generated/cesta_api.dart';
import 'package:flutter_test/flutter_test.dart';

import 'harness/harness.dart';

void main() {
  testWidgets('offline, after Clear checked the cleared Items show under Bought before; tapping one adds it back', (
    tester,
  ) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    final list = h.api.addList(ana, name: 'Weekend feira');
    h.api.addItem(list, name: 'Rice', addedBy: ana, quantity: '1.5', unit: ItemUnit.kg, note: 'brown', checkedBy: ana);
    h.api.addItem(list, name: 'Bananas', addedBy: ana, checkedBy: ana);
    h.api.addItem(list, name: 'Coffee', addedBy: ana);
    await h.pumpApp();
    await h.openList('Weekend feira');
    h.goOffline();
    await h.tap(find.text('Clear checked'));
    await h.tap(find.text('Add an item'));

    expect(find.text('Bought before'), findsOneWidget);
    expect(h.pastItems(), ['Bananas', '1.5 kg Rice']);

    await h.tap(find.widgetWithText(CesItemTile, 'Rice'));

    expect(find.text('Rice added to Weekend feira'), findsOneWidget);
    expect(h.pastItems(), ['Bananas']); // Rice is to buy again
    await h.tap(find.text('Done'));
    expect(h.tags(), ['Coffee', '1.5 kg Rice']);
    expect(find.text('Offline · 3 changes waiting to sync'), findsOneWidget);

    await h.goOnline();

    expect(h.api.itemsToBuy(list), ['Coffee', 'Rice']);
    expect(h.api.serverItem('Rice').quantity?.value, '1.5');
    expect(h.api.serverItem('Rice').unit?.value, ItemUnit.kg);
    expect(h.api.serverItem('Rice').note?.value, 'brown');
  });

  testWidgets('Undo on the Toast of a past Item removes the Item just added', (tester) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    final list = h.api.addList(ana, name: 'Weekend feira');
    h.api.addItem(list, name: 'Bananas', addedBy: ana, checkedBy: ana);
    h.api.clearCheckedNow(list, by: ana);
    await h.pumpApp();
    await h.openList('Weekend feira');
    await h.tap(find.text('Add an item'));

    await h.tap(find.widgetWithText(CesItemTile, 'Bananas'));
    await h.tap(find.text('Undo'));

    expect(h.pastItems(), ['Bananas']);
    await h.tap(find.text('Done'));
    expect(h.tags(), isEmpty);
    expect(h.api.itemsToBuy(list), isEmpty);
  });

  testWidgets('Bought before shows each name once, most recent first, ignoring case and accents', (tester) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    final list = h.api.addList(ana, name: 'Feira');
    h.api.addItem(list, name: 'Pão', addedBy: ana, quantity: '6', checkedBy: ana);
    h.api.addItem(list, name: 'Leite', addedBy: ana, checkedBy: ana);
    h.api.clearCheckedNow(list, by: ana);
    h.api.addItem(list, name: 'pao', addedBy: ana, quantity: '4', checkedBy: ana);
    h.api.clearCheckedNow(list, by: ana);
    await h.pumpApp(locale: brazilianPortuguese);
    await h.openList('Feira');

    await h.tap(find.text('Adicionar um item'));

    expect(find.text('Comprados antes'), findsOneWidget);
    expect(h.pastItems(), ['4 pao', 'Leite']);
  });

  testWidgets('Matches show past Items after the List’s Items to buy, and a name on the List only once', (
    tester,
  ) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    final list = h.api.addList(ana, name: 'Weekend feira');
    h.api.addItem(list, name: 'Leite', addedBy: ana, checkedBy: ana);
    h.api.addItem(list, name: 'Leite condensado', addedBy: ana, checkedBy: ana);
    h.api.addItem(list, name: 'Coffee', addedBy: ana, checkedBy: ana);
    h.api.clearCheckedNow(list, by: ana);
    h.api.addItem(list, name: 'leite', addedBy: ana, quantity: '2', unit: ItemUnit.l);
    await h.pumpApp();
    await h.openList('Weekend feira');
    await h.tap(find.text('Add an item'));
    expect(h.pastItems(), ['Coffee', 'Leite condensado']); // leite is already to buy

    await h.search('LEITE');

    expect(find.text('Bought before'), findsNothing);
    expect(find.text('Matches'), findsOneWidget);
    expect(h.matches(), ['2 L leite']);
    expect(h.pastItems(), ['Leite condensado']);

    await h.tap(find.widgetWithText(CesItemTile, 'Leite condensado'));

    expect(find.text('Leite condensado added to Weekend feira'), findsOneWidget);
    expect(find.text('LEITE'), findsNothing); // the search is cleared for the next one
    expect(h.pastItems(), ['Coffee']);
    expect(h.api.itemsToBuy(list), ['leite', 'Leite condensado']);
  });
}
