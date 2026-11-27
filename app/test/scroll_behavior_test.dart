import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'harness/harness.dart';

/// Simulates an iPhone with status bar + home indicator insets (iPhone 15/16).
const _iPhonePadding = FakeViewPadding(top: 59, bottom: 34);

void main() {
  Future<void> expectNoSwipeDownMovement(WidgetTester tester, Finder anchor) async {
    final before = tester.getTopLeft(anchor);
    final gesture = await tester.startGesture(const Offset(195, 400));
    await gesture.moveBy(const Offset(0, 200));
    await tester.pump();
    final during = tester.getTopLeft(anchor);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(during.dy, before.dy);
  }

  testWidgets(
    'on iOS, swiping down does not drag screens whose content fits the viewport',
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    (tester) async {
      final h = Harness(tester);
      Future<void> pumpWithInsets() async {
        await h.pumpApp();
        tester.view.padding = _iPhonePadding;
        tester.view.viewPadding = _iPhonePadding;
        await tester.pumpAndSettle();
      }

      // Welcome screen
      await pumpWithInsets();
      await expectNoSwipeDownMovement(tester, find.text('One shopping list for the whole house.'));

      // Sign-up screen
      await h.tap(find.text('Continue with email'));
      await expectNoSwipeDownMovement(tester, find.text('Create account').last);

      // Lists screen (empty)
      h.signedIn();
      await pumpWithInsets();
      await expectNoSwipeDownMovement(tester, find.text('Your Lists'));

      // Display name screen (CesFormScaffold)
      await h.openUserMenu();
      await tester.tap(find.text('Change display name'));
      await tester.pumpAndSettle();
      await expectNoSwipeDownMovement(tester, find.text('Save'));

      // Lists screen (a few Lists that fit on screen)
      final ana = h.signedIn();
      h.api.addList(ana, name: 'Groceries');
      h.api.addList(ana, name: 'Pharmacy');
      await pumpWithInsets();
      await expectNoSwipeDownMovement(tester, find.text('Your Lists'));

      // Recently deleted screen
      await h.openUserMenu();
      await tester.tap(find.text('Recently deleted'));
      await tester.pumpAndSettle();
      await expectNoSwipeDownMovement(tester, find.textContaining('30 days').first);
    },
  );

  testWidgets(
    'on iOS, a long Lists screen still scrolls while keeping the wordmark anchored',
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    (tester) async {
      final h = Harness(tester);
      final ana = h.signedIn();
      for (var i = 0; i < 15; i++) {
        h.api.addList(ana, name: 'List $i');
      }
      await h.pumpApp();
      tester.view.padding = _iPhonePadding;
      tester.view.viewPadding = _iPhonePadding;
      await tester.pumpAndSettle();

      final wordmarkBefore = tester.getTopLeft(find.text('cesta'));
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(tester.getTopLeft(find.text('cesta')), wordmarkBefore);
    },
  );
}
