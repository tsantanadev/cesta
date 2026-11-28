import 'package:cesta/src/api/generated/cesta_api.dart' show InvitationCreateLanguage, InvitationStatus;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show ThemeMode;

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

  testWidgets('inviting someone already on the List says so', (tester) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    final bia = h.existingUser(email: 'bia@example.com', password: 'irrelevant', displayName: 'Bia Lima');
    final listId = h.api.addList(ana, name: 'Weekend feira', sharedWith: [bia]);
    await h.pumpApp();
    await h.openList('Weekend feira');

    await h.inviteByEmail('Bia@example.com');

    expect(find.text('That person is already on this list.'), findsOneWidget);
    expect(h.api.pendingInvitationEmails(listId), isEmpty);
  });

  testWidgets("an Invitation whose email couldn't be sent says so, and can be sent again", (tester) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    final listId = h.api.addList(ana, name: 'Weekend feira');
    h.api.invitationEmailsFail = true;
    await h.pumpApp();
    await h.openList('Weekend feira');

    await h.inviteByEmail('rui@example.com');

    expect(find.text("We couldn't send the invitation email. Try again in a moment."), findsOneWidget);
    expect(h.api.pendingInvitationEmails(listId), isEmpty);
    h.api.invitationEmailsFail = false;
    await h.tap(find.widgetWithText(CesButton, 'Send invitation'));
    expect(h.api.pendingInvitationEmails(listId), ['rui@example.com']);
  });

  testWidgets('the Owner still sees an Invitation that expired, marked expired', (tester) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    final listId = h.api.addList(ana, name: 'Weekend feira');
    h.api.setInvitationStatus(h.api.addInvitation(listId, email: 'rui@example.com'), InvitationStatus.expired);
    await h.pumpApp();
    await h.openList('Weekend feira');

    await h.openShareList();

    expect(find.text('rui@example.com'), findsOneWidget);
    expect(find.text('Expired, never joined'), findsOneWidget);
  });

  group("the User's pending Invitations", () {
    testWidgets('show on the Lists screen, and joining adds the List', (tester) async {
      final h = Harness(tester);
      final bia = h.existingUser(email: 'bia@example.com', password: 'irrelevant', displayName: 'Bia Lima');
      final ana = h.signedIn();
      final listId = h.api.addList(bia, name: 'Barbecue');
      h.api.addInvitation(listId, email: 'ana@example.com');
      await h.pumpApp();

      expect(find.text('Barbecue'), findsOneWidget);
      expect(find.text('Bia Lima invited you'), findsOneWidget);

      await h.tap(find.widgetWithText(CesButton, 'Join'));

      expect(h.api.listNamesOf(ana), ['Barbecue']);
      expect(find.text('You joined Barbecue'), findsOneWidget);
      expect(find.text('Bia Lima invited you'), findsNothing);
      expect(find.text('Shared with you'), findsOneWidget);
    });

    testWidgets('declining one takes it away without joining', (tester) async {
      final h = Harness(tester);
      final bia = h.existingUser(email: 'bia@example.com', password: 'irrelevant', displayName: 'Bia Lima');
      final ana = h.signedIn();
      h.api.addInvitation(h.api.addList(bia, name: 'Barbecue'), email: 'ana@example.com');
      await h.pumpApp();

      await h.tap(find.widgetWithText(CesButton, 'Decline'));

      expect(h.api.listNamesOf(ana), isEmpty);
      expect(find.text('Invitation to Barbecue declined'), findsOneWidget);
      expect(find.text('Bia Lima invited you'), findsNothing);
    });

    testWidgets('joining one the Owner cancelled meanwhile says so', (tester) async {
      final h = Harness(tester);
      final bia = h.existingUser(email: 'bia@example.com', password: 'irrelevant', displayName: 'Bia Lima');
      final ana = h.signedIn();
      h.api.addInvitation(h.api.addList(bia, name: 'Barbecue'), email: 'ana@example.com');
      await h.pumpApp();
      h.api.cancelInvitationNow('ana@example.com');

      await h.tap(find.widgetWithText(CesButton, 'Join'));

      expect(h.api.listNamesOf(ana), isEmpty);
      expect(find.text('This invitation was cancelled. Ask for a new one.'), findsOneWidget);
      expect(find.text('Bia Lima invited you'), findsNothing);
    });
  });

  testWidgets('an Editor has no Share list', (tester) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    h.api.addListSharedWith(ana, name: 'Weekend feira');
    await h.pumpApp();
    await h.openList('Weekend feira');

    expect(find.byTooltip('Share list'), findsNothing);
  });

  testWidgets('Share list and the invite sheet are in Brazilian Portuguese, and so is the email', (tester) async {
    final h = Harness(tester);
    final ana = h.signedIn();
    h.api.addList(ana, name: 'Feira de sábado');
    await h.pumpApp(locale: brazilianPortuguese);
    await h.openList('Feira de sábado');

    await h.tap(find.byTooltip('Compartilhar lista'));
    await h.tap(find.widgetWithText(CesButton, 'Convidar por e-mail'));
    expect(find.textContaining('O link vale por 14 dias.'), findsOneWidget);
    await tester.enterText(field('E-mail'), 'rui@example.com');
    await h.tap(find.widgetWithText(CesButton, 'Enviar convite'));

    expect(find.text('Aguardando resposta'), findsOneWidget);
    expect(find.text('rui@example.com'), findsOneWidget);
    expect(h.api.sentInvitationEmails.single.language, InvitationCreateLanguage.ptBr);
  });

  testWidgets('Invitations stay usable in dark mode at the largest text size', (tester) async {
    final h = Harness(tester);
    final bia = h.existingUser(email: 'bia@example.com', password: 'irrelevant', displayName: 'Bia Lima');
    final ana = h.signedIn();
    h.api.addInvitation(h.api.addList(bia, name: 'Barbecue on Saturday'), email: 'ana@example.com');
    final listId = h.api.addList(ana, name: 'Weekend feira');
    h.api.addInvitation(listId, email: 'a.very.long.address.for.someone@example.com');
    await h.pumpApp(themeMode: ThemeMode.dark, textScale: 2);
    expect(find.text('Bia Lima invited you'), findsOneWidget);
    await h.openList('Weekend feira');

    await h.inviteByEmail('rui@example.com');

    expect(tester.takeException(), isNull);
    expect(h.api.pendingInvitationEmails(listId), ['rui@example.com', 'a.very.long.address.for.someone@example.com']);
  });
}
