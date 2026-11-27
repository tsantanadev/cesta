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
}
