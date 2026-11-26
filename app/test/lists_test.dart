import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'harness/harness.dart';

void main() {
  testWidgets('creating a List shows it on the Lists screen', (tester) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    await h.pumpApp();

    await h.createList('Weekend feira');

    expect(find.text('Weekend feira'), findsOneWidget);
    expect(find.text('Only you'), findsOneWidget);
    expect(find.text('No Lists yet'), findsNothing);
    expect(h.api.listNamesOf(ana), ['Weekend feira']);
  });

  testWidgets('shows owned and shared Lists, with what is left to buy', (tester) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    h.api.addList(ana, name: 'Pharmacy', uncheckedItemCount: 2);
    h.api.addList(ana, name: 'Barbecue on Saturday', uncheckedItemCount: 14, otherMembers: 5);
    h.api.addListSharedWith(ana, name: 'Weekend feira', uncheckedItemCount: 9);
    h.api.addList(ana, name: 'Home basics');

    await h.pumpApp(screen: iPhone);

    expect(find.text('Only you'), findsNWidgets(2));
    expect(find.text('Shared with 5 people'), findsOneWidget);
    expect(find.text('Shared with you'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('14 to buy')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('9 to buy')), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('Nothing to buy')), findsOneWidget);
  });

  testWidgets('a List shared with the User has no rename or delete', (tester) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    h.api.addListSharedWith(ana, name: 'Weekend feira');

    await h.pumpApp();

    expect(find.text('Weekend feira'), findsOneWidget);
    expect(find.byTooltip('Options for Weekend feira'), findsNothing);
  });

  testWidgets('offline, the Lists seen last time are still shown', (tester) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    h.api.addList(ana, name: 'Pharmacy');
    await h.pumpApp();

    h.goOffline();
    await h.pumpApp();

    expect(find.text('Pharmacy'), findsOneWidget);
  });

  testWidgets('signing out forgets the Lists on the device', (tester) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    h.api.addList(ana, name: 'Pharmacy');
    await h.pumpApp();
    await h.openAccountMenu();
    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();

    h.goOffline();
    h.auth.offline = false;
    final bruno = h.existingUser(email: 'bruno@example.com', password: 'secret123', displayName: 'Bruno');
    await h.signInWithEmail(bruno.email, 'secret123');

    expect(find.text('Pharmacy'), findsNothing);
  });

  testWidgets('a List needs a name', (tester) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    await h.pumpApp();

    await h.createList('   ');

    expect(find.text('Enter a name.'), findsOneWidget);
    expect(h.api.listNamesOf(ana), isEmpty);
  });

  testWidgets('a List name can be at most 60 characters', (tester) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    await h.pumpApp();

    await h.createList('x' * 61);

    expect(find.text('Use 60 characters or fewer.'), findsOneWidget);
    expect(h.api.listNamesOf(ana), isEmpty);
  });

  testWidgets('the 101st List is refused with an explanation', (tester) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    for (var i = 0; i < 100; i++) {
      h.api.addList(ana, name: 'List $i');
    }
    await h.pumpApp();

    await h.createList('One too many');

    expect(find.text("You've reached the limit of 100 Lists. Delete one to create another."), findsOneWidget);
    expect(h.api.listNamesOf(ana), isNot(contains('One too many')));
  });

  testWidgets('creating a List offline says there is no connection', (tester) async {
    final h = Harness(tester);
    h.signedIn();
    await h.pumpApp();
    h.goOffline();

    await h.createList('Pharmacy');

    expect(find.text("You're offline. Connect to the internet and try again."), findsOneWidget);
  });

  testWidgets('the Lists screen is in Brazilian Portuguese on a Portuguese phone', (tester) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    h.api.addList(ana, name: 'Feira', uncheckedItemCount: 3, otherMembers: 1);

    await h.pumpApp(locale: brazilianPortuguese);

    expect(find.text('Suas listas'), findsOneWidget);
    expect(find.text('Compartilhada com 1 pessoa'), findsOneWidget);
    expect(find.text('a comprar'), findsOneWidget);
    expect(find.text('Nova lista'), findsOneWidget);
  });

  testWidgets('the Lists screen stays usable in dark mode at the largest text size', (tester) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    h.api.addList(ana, name: 'Barbecue on Saturday with the whole family', uncheckedItemCount: 120, otherMembers: 4);

    await h.pumpApp(themeMode: ThemeMode.dark, textScale: 2.0);
    await h.createList('Pharmacy');

    expect(tester.takeException(), isNull);
    expect(find.text('Pharmacy'), findsOneWidget);
  });

  group('rename', () {
    testWidgets('the Owner renames a List', (tester) async {
      final h = Harness(tester);
      final ana = h.signedIn();
      h.api.addList(ana, name: 'Feira');
      await h.pumpApp();

      await h.renameList('Feira', 'Weekend feira');

      expect(find.text('Weekend feira'), findsOneWidget);
      expect(find.text('Feira'), findsNothing);
      expect(h.api.listNamesOf(ana), ['Weekend feira']);
    });

    testWidgets('the sheet starts with the current name', (tester) async {
      final h = Harness(tester);
      final ana = h.signedIn();
      h.api.addList(ana, name: 'Feira');
      await h.pumpApp();

      await h.openListOptions('Feira');
      await tester.tap(find.text('Rename'));
      await tester.pumpAndSettle();

      expect(find.text('Rename list'), findsOneWidget);
      expect(h.textInField('Name'), 'Feira');
    });

    testWidgets('renaming a List deleted meanwhile says it is gone', (tester) async {
      final h = Harness(tester);
      final ana = h.signedIn();
      final id = h.api.addList(ana, name: 'Feira');
      await h.pumpApp();
      h.api.deleteListNow(id);

      await h.renameList('Feira', 'Weekend feira');

      expect(find.text('This List is no longer available.'), findsOneWidget);
    });
  });

  group('delete', () {
    testWidgets('the Owner deletes a List and it leaves the Lists screen', (tester) async {
      final h = Harness(tester);
      final ana = h.signedIn();
      h.api.addList(ana, name: 'Pharmacy');
      h.api.addList(ana, name: 'Feira');
      await h.pumpApp();

      await h.deleteList('Feira');

      expect(find.text('Feira'), findsNothing);
      expect(find.text('“Feira” deleted'), findsOneWidget);
      expect(h.api.listNamesOf(ana), ['Pharmacy']);
    });

    testWidgets('Undo brings the deleted List back', (tester) async {
      final h = Harness(tester);
      final ana = h.signedIn();
      h.api.addList(ana, name: 'Feira');
      await h.pumpApp();
      await h.deleteList('Feira');

      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(find.text('Feira'), findsOneWidget);
      expect(h.api.listNamesOf(ana), ['Feira']);
    });

    testWidgets('deleting offline says there is no connection and keeps the List', (tester) async {
      final h = Harness(tester);
      final ana = h.signedIn();
      h.api.addList(ana, name: 'Feira');
      await h.pumpApp();
      h.goOffline();

      await h.deleteList('Feira');

      expect(find.text("You're offline. Connect to the internet and try again."), findsOneWidget);
      expect(find.text('Feira'), findsOneWidget);
    });
  });

  group('recently deleted', () {
    testWidgets('shows the Lists the Owner deleted and how long they can be restored', (tester) async {
      final h = Harness(tester);
      final ana = h.signedIn();
      h.api.addList(ana, name: 'Feira', deletedAgo: const Duration(days: 3));
      h.api.addList(ana, name: 'Old party', deletedAgo: const Duration(days: 29, hours: 1));
      h.api.addList(ana, name: 'Long gone', deletedAgo: const Duration(days: 31));
      h.api.addList(ana, name: 'Pharmacy');

      await h.openRecentlyDeleted();

      expect(find.text('Feira'), findsOneWidget);
      expect(find.text('27 days left'), findsOneWidget);
      expect(find.text('Old party'), findsOneWidget);
      expect(find.text('1 day left'), findsOneWidget);
      expect(find.text('Long gone'), findsNothing);
      expect(find.text('Pharmacy'), findsNothing);
    });

    testWidgets('restoring a List puts it back on the Lists screen', (tester) async {
      final h = Harness(tester);
      final ana = h.signedIn();
      h.api.addList(ana, name: 'Feira', deletedAgo: const Duration(days: 3));
      await h.openRecentlyDeleted();

      await tester.tap(find.widgetWithText(CesButton, 'Restore'));
      await tester.pumpAndSettle();
      expect(find.text('Nothing deleted in the last 30 days.'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('Your Lists'), findsOneWidget);
      expect(find.text('Feira'), findsOneWidget);
      expect(h.api.listNamesOf(ana), ['Feira']);
    });

    testWidgets("doesn't show Lists other Users deleted", (tester) async {
      final h = Harness(tester);
      final ana = h.signedIn();
      final sharedId = h.api.addListSharedWith(ana, name: 'Their feira');
      h.api.deleteListNow(sharedId);

      await h.openRecentlyDeleted();

      expect(find.text('Their feira'), findsNothing);
      expect(find.text('Nothing deleted in the last 30 days.'), findsOneWidget);
    });

    testWidgets('restoring past the limit of 100 Lists says so', (tester) async {
      final h = Harness(tester);
      final ana = h.signedIn();
      h.api.addList(ana, name: 'Feira', deletedAgo: const Duration(days: 3));
      for (var i = 0; i < 100; i++) {
        h.api.addList(ana, name: 'List $i');
      }
      await h.openRecentlyDeleted();

      await tester.tap(find.widgetWithText(CesButton, 'Restore'));
      await tester.pumpAndSettle();

      expect(find.text("You've reached the limit of 100 Lists. Delete one to create another."), findsOneWidget);
      expect(find.text('Feira'), findsOneWidget);
    });

    testWidgets('offline, says there is no connection', (tester) async {
      final h = Harness(tester);
      h.signedIn();
      await h.pumpApp();
      h.goOffline();

      await h.openAccountMenu();
      await tester.tap(find.text('Recently deleted'));
      await tester.pumpAndSettle();

      expect(find.text("You're offline. Connect to the internet and try again."), findsOneWidget);
    });

    testWidgets('is in Brazilian Portuguese on a Portuguese phone', (tester) async {
      final h = Harness(tester);
      final ana = h.signedIn();
      h.api.addList(ana, name: 'Feira', deletedAgo: const Duration(days: 3));

      await h.openRecentlyDeleted(locale: brazilianPortuguese);

      expect(find.text('Excluídas recentemente'), findsOneWidget);
      expect(find.text('Faltam 27 dias'), findsOneWidget);
      expect(find.widgetWithText(CesButton, 'Restaurar'), findsOneWidget);
    });
  });
}
