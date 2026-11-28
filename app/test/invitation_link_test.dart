import 'package:cesta/src/api/generated/cesta_api.dart' show InvitationStatus;
import 'package:flutter_test/flutter_test.dart';

import 'harness/harness.dart';

const password = 'correct horse battery';
const brunoEmail = 'bruno@example.com';

/// The Invitation deep link for [token], as the email carries it.
String invitationLink(String token) => 'https://cesta.tsantana.dev/invite/$token';

/// Ana owns a List named Casa and invited [email] to it; returns the token
/// in the Invitation's deep link.
String anaInvites(Harness h, {String email = brunoEmail, InvitationStatus status = InvitationStatus.pending}) {
  final ana = h.existingUser(email: 'ana@example.com', password: password, displayName: 'Ana Souza');
  final invitation = h.api.addInvitation(h.api.addList(ana, name: 'Casa'), email: email);
  h.api.setInvitationStatus(invitation, status);
  return h.api.invitationToken(invitation);
}

/// The Invitation whose deep link carries [token].
String invitationOf(String token) => token.substring('token-'.length);

final accept = find.widgetWithText(CesButton, 'Join');
final decline = find.widgetWithText(CesButton, 'Decline');

void main() {
  group('an Invitation link opened while signed out', () {
    testWidgets('goes through sign-in and lands on the accept screen', (tester) async {
      final h = Harness(tester);
      final token = anaInvites(h);
      h.existingUser(email: brunoEmail, password: password, displayName: 'Bruno');
      await h.pumpApp();

      await h.openLink(invitationLink(token));
      expect(find.text('Continue with email'), findsOneWidget);
      await h.signInWithEmail(brunoEmail, password);

      expect(find.text('Ana Souza invited you to join Casa'), findsOneWidget);
      expect(accept, findsOneWidget);
      expect(decline, findsOneWidget);
    });

    testWidgets('that started the app goes through sign-up and the display name to the accept screen', (tester) async {
      final h = Harness(tester);
      final token = anaInvites(h);

      await h.pumpApp(initialLocation: Uri.parse(invitationLink(token)).path);
      await h.signUpWithEmail(brunoEmail, password);
      expect(find.text('What should we call you?'), findsOneWidget);
      await tester.tap(find.widgetWithText(CesButton, 'Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Ana Souza invited you to join Casa'), findsOneWidget);
    });

    testWidgets('is kept when the app restarts before the User signs in', (tester) async {
      final h = Harness(tester);
      final token = anaInvites(h);
      h.existingUser(email: brunoEmail, password: password, displayName: 'Bruno');
      await h.pumpApp();
      await h.openLink(invitationLink(token));

      await h.pumpApp();
      await h.signInWithEmail(brunoEmail, password);

      expect(find.text('Ana Souza invited you to join Casa'), findsOneWidget);
    });

    testWidgets('is opened only once: signing out and in again goes to the Lists', (tester) async {
      final h = Harness(tester);
      final token = anaInvites(h);
      h.existingUser(email: brunoEmail, password: password, displayName: 'Bruno');
      await h.pumpApp();
      await h.openLink(invitationLink(token));
      await h.signInWithEmail(brunoEmail, password);
      await h.tap(decline);

      await h.signOut();
      await h.signInWithEmail(brunoEmail, password);

      expect(find.text('Your Lists'), findsOneWidget);
    });
  });

  group('the accept screen', () {
    testWidgets('accepting makes the User an Editor and opens the List, which is then with their Lists', (
      tester,
    ) async {
      final h = Harness(tester);
      final token = anaInvites(h);
      final bruno = h.signedIn(email: brunoEmail, displayName: 'Bruno');
      await h.pumpApp();
      await h.openLink(invitationLink(token));

      await h.tap(accept);

      expect(h.api.listNamesOf(bruno), ['Casa']);
      expect(find.text('Casa'), findsOneWidget);
      expect(find.text('Add an item'), findsOneWidget);

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();

      expect(find.text('Your Lists'), findsOneWidget);
      expect(find.text('Casa'), findsOneWidget);
      expect(find.text('Shared with you'), findsOneWidget);
    });

    testWidgets('declining goes to the Lists and the link stops working', (tester) async {
      final h = Harness(tester);
      final token = anaInvites(h);
      final bruno = h.signedIn(email: brunoEmail, displayName: 'Bruno');
      await h.pumpApp();
      await h.openLink(invitationLink(token));

      await h.tap(decline);

      expect(find.text('Invitation to Casa declined'), findsOneWidget);
      expect(find.text('Your Lists'), findsOneWidget);
      expect(h.api.listNamesOf(bruno), isEmpty);
      expect(h.api.invitationStatus(invitationOf(token)), InvitationStatus.declined);
    });

    testWidgets('says when it was sent to another email, and still lets the User accept', (tester) async {
      final h = Harness(tester);
      final token = anaInvites(h, email: 'bruno.lima@work.example.com');
      final bruno = h.signedIn(email: brunoEmail, displayName: 'Bruno');
      await h.pumpApp();
      await h.openLink(invitationLink(token));

      expect(
        find.text("This invitation was sent to bruno.lima@work.example.com. You'll join as bruno@example.com."),
        findsOneWidget,
      );
      await h.tap(accept);

      expect(h.api.listNamesOf(bruno), ['Casa']);
    });

    for (final (status, message) in [
      (InvitationStatus.expired, 'This invitation expired. Ask for a new one.'),
      (InvitationStatus.cancelled, 'This invitation was cancelled. Ask for a new one.'),
      (InvitationStatus.declined, 'This invitation was declined.'),
    ]) {
      testWidgets('a ${status.value} Invitation says so and offers only the way to the Lists', (tester) async {
        final h = Harness(tester);
        final token = anaInvites(h, status: status);
        h.signedIn(email: brunoEmail, displayName: 'Bruno');
        await h.pumpApp();

        await h.openLink(invitationLink(token));

        expect(find.text(message), findsOneWidget);
        expect(accept, findsNothing);
        await h.tap(find.widgetWithText(CesButton, 'Go to your lists'));
        expect(find.text('Your Lists'), findsOneWidget);
      });
    }

    testWidgets('a link whose token matches no Invitation says it does not work', (tester) async {
      final h = Harness(tester);
      h.signedIn(email: brunoEmail, displayName: 'Bruno');
      await h.pumpApp();

      await h.openLink(invitationLink('not-a-token'));

      expect(find.text('This invitation is no longer available.'), findsOneWidget);
      expect(accept, findsNothing);
    });

    testWidgets('an Invitation cancelled after the screen opened says so on accept', (tester) async {
      final h = Harness(tester);
      final token = anaInvites(h);
      h.signedIn(email: brunoEmail, displayName: 'Bruno');
      await h.pumpApp();
      await h.openLink(invitationLink(token));
      h.api.setInvitationStatus(invitationOf(token), InvitationStatus.cancelled);

      await h.tap(accept);

      expect(find.text('This invitation was cancelled. Ask for a new one.'), findsOneWidget);
      expect(accept, findsNothing);
    });

    testWidgets('offline, says so and offers to try again', (tester) async {
      final h = Harness(tester);
      final token = anaInvites(h);
      h.signedIn(email: brunoEmail, displayName: 'Bruno');
      await h.pumpApp();
      h.goOffline();

      await h.openLink(invitationLink(token));
      expect(find.text("You're offline. Connect to the internet and try again."), findsOneWidget);
      await h.goOnline();
      await h.tap(find.widgetWithText(CesButton, 'Try again'));

      expect(find.text('Ana Souza invited you to join Casa'), findsOneWidget);
      expect(accept, findsOneWidget);
    });

    testWidgets('is in Brazilian Portuguese on a Portuguese phone', (tester) async {
      final h = Harness(tester);
      final token = anaInvites(h);
      h.signedIn(email: brunoEmail, displayName: 'Bruno');
      await h.pumpApp(locale: brazilianPortuguese);

      await h.openLink(invitationLink(token));

      expect(find.text('Ana Souza convidou você para a lista Casa'), findsOneWidget);
      expect(find.widgetWithText(CesButton, 'Entrar'), findsOneWidget);
      expect(find.widgetWithText(CesButton, 'Recusar'), findsOneWidget);
    });
  });

  testWidgets('a Share link (/join/, not built yet: #10) opens the Lists instead of an error', (tester) async {
    final h = Harness(tester);
    h.signedIn();
    await h.pumpApp();

    await h.openLink('https://cesta.tsantana.dev/join/some-code');

    expect(find.text('Your Lists'), findsOneWidget);
  });
}
