import 'package:flutter_test/flutter_test.dart';

import 'harness/harness.dart';

void main() {
  testWidgets('inviting an email shows it as pending on the List', (tester) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    final listId = h.api.addList(ana, name: 'Weekend feira');
    await h.pumpApp();
    await h.openList('Weekend feira');

    await h.inviteByEmail('rui@example.com');

    expect(h.api.pendingInvitationEmails(listId), ['rui@example.com']);
    expect(find.text('Share list'), findsOneWidget);
    expect(find.text('Waiting to join'), findsOneWidget);
    expect(find.text('rui@example.com'), findsOneWidget);
  });

  testWidgets('the Owner cancels a pending Invitation', (tester) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    final listId = h.api.addList(ana, name: 'Weekend feira');
    h.api
      ..addInvitation(listId, email: 'rui@example.com')
      ..addInvitation(listId, email: 'bia@example.com');
    await h.pumpApp();
    await h.openList('Weekend feira');
    await h.openShareList();
    expect(find.text('rui@example.com'), findsOneWidget);

    await h.tap(find.byTooltip('Cancel invitation to rui@example.com'));

    expect(h.api.pendingInvitationEmails(listId), ['bia@example.com']);
    expect(find.text('Invitation to rui@example.com cancelled'), findsOneWidget);
    expect(find.text('rui@example.com'), findsNothing);
    expect(find.text('bia@example.com'), findsOneWidget);
  });

  testWidgets('the 21st Invitation of the day says the daily limit was reached', (tester) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    final listId = h.api.addList(ana, name: 'Weekend feira');
    h.api.sendInvitationsToday(ana, 20);
    await h.pumpApp();
    await h.openList('Weekend feira');

    await h.inviteByEmail('rui@example.com');

    expect(
      find.text("You've sent 20 invitations in the last 24 hours, the most allowed. Try again tomorrow."),
      findsOneWidget,
    );
    expect(h.api.pendingInvitationEmails(listId), isEmpty);
    expect(find.widgetWithText(CesButton, 'Send invitation'), findsOneWidget, reason: 'the sheet stays open');
  });
}
