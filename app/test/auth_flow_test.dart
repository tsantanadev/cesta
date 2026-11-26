import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'harness/harness.dart';

const anaEmail = 'ana@example.com';
const password = 'correct horse battery';

void main() {
  group('signed out', () {
    testWidgets('opens on the welcome screen', (tester) async {
      final h = Harness(tester);

      await h.pumpApp();

      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Continue with email'), findsOneWidget);
      expect(find.text('Your Lists'), findsNothing);
    });

    testWidgets('the welcome screen is in Brazilian Portuguese on a Portuguese phone', (tester) async {
      final h = Harness(tester);

      await h.pumpApp(locale: brazilianPortuguese);

      expect(find.text('Continuar com Google'), findsOneWidget);
      expect(find.text('Continuar com e-mail'), findsOneWidget);
      expect(find.text('Já tem uma conta? Entrar'), findsOneWidget);
    });
  });

  group('sign in with email', () {
    testWidgets('leads to the home screen', (tester) async {
      final h = Harness(tester);
      h.existingUser(email: anaEmail, password: password, displayName: 'Ana Souza');
      await h.pumpApp();

      await h.signInWithEmail(anaEmail, password);

      expect(find.text('Your Lists'), findsOneWidget);
      expect(find.text('No Lists yet'), findsOneWidget);
    });

    testWidgets('a wrong password says so and stays on the sign-in screen', (tester) async {
      final h = Harness(tester);
      h.existingUser(email: anaEmail, password: password, displayName: 'Ana Souza');
      await h.pumpApp();

      await h.signInWithEmail(anaEmail, 'wrong password');

      expect(find.text('Wrong email or password.'), findsOneWidget);
      expect(find.text('Your Lists'), findsNothing);
    });

    testWidgets('offline, says there is no connection', (tester) async {
      final h = Harness(tester);
      h.existingUser(email: anaEmail, password: password, displayName: 'Ana Souza');
      await h.pumpApp();
      h.goOffline();

      await h.signInWithEmail(anaEmail, password);

      expect(find.text("You're offline. Connect to the internet and try again."), findsOneWidget);
    });

    testWidgets('asks for an email and password before trying', (tester) async {
      final h = Harness(tester);
      await h.pumpApp();
      await h.openEmailSignIn();

      await tester.tap(find.widgetWithText(CesButton, 'Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('Enter your email address.'), findsOneWidget);
      expect(find.text('Enter your password.'), findsOneWidget);
      expect(h.auth.signInAttempts, 0);
    });
  });

  group('sign up with email', () {
    testWidgets('asks the new User to confirm a display name, then goes home', (tester) async {
      final h = Harness(tester);
      await h.pumpApp();

      await h.signUpWithEmail('bruno.lima@example.com', password);

      expect(find.text('What should we call you?'), findsOneWidget);
      expect(h.textInField('Display name'), 'bruno.lima');

      await tester.enterText(find.widgetWithText(TextField, 'Display name'), 'Bruno');
      await tester.tap(find.widgetWithText(CesButton, 'Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Your Lists'), findsOneWidget);
      expect(h.api.userFor('bruno.lima@example.com')?.displayName, 'Bruno');
    });

    testWidgets('an email that already has an account says so', (tester) async {
      final h = Harness(tester);
      h.existingUser(email: anaEmail, password: password, displayName: 'Ana Souza');
      await h.pumpApp();

      await h.signUpWithEmail(anaEmail, 'another password');

      expect(find.text('An account with this email already exists. Sign in instead.'), findsOneWidget);
    });

    testWidgets('rejects an invalid email and a short password before trying', (tester) async {
      final h = Harness(tester);
      await h.pumpApp();

      await h.signUpWithEmail('not-an-email', '123');

      expect(find.text('Enter a valid email address.'), findsOneWidget);
      expect(find.text('Use at least 8 characters.'), findsOneWidget);
      expect(h.auth.signUpAttempts, 0);
    });
  });

  group('sign in with Google', () {
    testWidgets('a first-time Google User confirms the name from Google, then goes home', (tester) async {
      final h = Harness(tester);
      h.auth.googleAccount = const FakeGoogleAccount(email: anaEmail, name: 'Ana Souza');
      await h.pumpApp();

      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      expect(find.text('What should we call you?'), findsOneWidget);
      expect(h.textInField('Display name'), 'Ana Souza');

      await tester.tap(find.widgetWithText(CesButton, 'Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Your Lists'), findsOneWidget);
      expect(h.api.userFor(anaEmail)?.displayNameConfirmed, isTrue);
    });

    testWidgets('a returning User goes straight home', (tester) async {
      final h = Harness(tester);
      h.existingUser(email: anaEmail, password: password, displayName: 'Ana Souza', withGoogle: true);
      await h.pumpApp();

      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      expect(find.text('Your Lists'), findsOneWidget);
    });

    testWidgets('closing the Google account picker stays on the welcome screen without an error', (tester) async {
      final h = Harness(tester);
      h.auth.googleAccount = null; // the User backs out of the picker
      await h.pumpApp();

      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.byType(CesMessage), findsNothing);
    });
  });

  group('display name', () {
    testWidgets('must not be blank or longer than 50 characters', (tester) async {
      final h = Harness(tester);
      h.auth.googleAccount = const FakeGoogleAccount(email: anaEmail, name: 'Ana Souza');
      await h.pumpApp();
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();
      final field = find.widgetWithText(TextField, 'Display name');

      await tester.enterText(field, '   ');
      await tester.tap(find.widgetWithText(CesButton, 'Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a name.'), findsOneWidget);

      await tester.enterText(field, 'a' * 51);
      await tester.tap(find.widgetWithText(CesButton, 'Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Use 50 characters or fewer.'), findsOneWidget);
      expect(h.api.userFor(anaEmail)?.displayNameConfirmed, isFalse);
    });

    testWidgets('a name the server rejects says it cannot be used', (tester) async {
      final h = Harness(tester);
      h.auth.googleAccount = const FakeGoogleAccount(email: anaEmail, name: 'Ana Souza');
      await h.pumpApp();
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();
      h.api.rejectDisplayNames = true;

      await tester.tap(find.widgetWithText(CesButton, 'Continue'));
      await tester.pumpAndSettle();

      expect(find.text("That name can't be used. Try another."), findsOneWidget);
    });

    testWidgets('a name with control characters is rejected before saving', (tester) async {
      final h = Harness(tester);
      h.auth.googleAccount = const FakeGoogleAccount(email: anaEmail, name: 'Ana Souza');
      await h.pumpApp();
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();

      await tester.enterText(find.widgetWithText(TextField, 'Display name'), 'Ana\u0007');
      await tester.tap(find.widgetWithText(CesButton, 'Continue'));
      await tester.pumpAndSettle();

      expect(find.text("That name can't be used. Try another."), findsOneWidget);
      expect(h.api.userFor(anaEmail)?.displayNameConfirmed, isFalse);
    });

    testWidgets('when the server is rate limiting, says to wait', (tester) async {
      final h = Harness(tester);
      h.auth.googleAccount = const FakeGoogleAccount(email: anaEmail, name: 'Ana Souza');
      await h.pumpApp();
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();
      h.api.rateLimited = true;

      await tester.tap(find.widgetWithText(CesButton, 'Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Too many attempts. Wait a moment and try again.'), findsOneWidget);
    });

    testWidgets('a new User can sign out from the name screen instead of confirming', (tester) async {
      final h = Harness(tester);
      h.auth.googleAccount = const FakeGoogleAccount(email: anaEmail, name: 'Ana Souza');
      await h.pumpApp();
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();
      h.goOffline(); // can't save the name, so signing out is the only way on

      await tester.tap(find.widgetWithText(CesButton, 'Continue'));
      await tester.pumpAndSettle();
      expect(find.text("You're offline. Connect to the internet and try again."), findsOneWidget);
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();

      expect(find.text('Continue with Google'), findsOneWidget);
    });

    testWidgets('can be changed later from the account menu', (tester) async {
      final h = Harness(tester);
      h.existingUser(email: anaEmail, password: password, displayName: 'Ana Souza', signedIn: true);
      await h.pumpApp();

      await h.openAccountMenu();
      expect(find.text('Ana Souza'), findsOneWidget);
      await tester.tap(find.text('Change display name'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Display name'), 'Aninha');
      await tester.tap(find.widgetWithText(CesButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('Your Lists'), findsOneWidget);
      expect(h.api.userFor(anaEmail)?.displayName, 'Aninha');
      await h.openAccountMenu();
      expect(find.text('Aninha'), findsOneWidget);
    });
  });

  group('staying signed in', () {
    testWidgets('a signed-in User reopens the app straight to home', (tester) async {
      final h = Harness(tester);
      h.existingUser(email: anaEmail, password: password, displayName: 'Ana Souza');
      await h.pumpApp();
      await h.signInWithEmail(anaEmail, password);

      await h.pumpApp(); // app restarts

      expect(find.text('Your Lists'), findsOneWidget);
    });

    testWidgets('reopening offline still goes home and remembers the display name', (tester) async {
      final h = Harness(tester);
      h.existingUser(email: anaEmail, password: password, displayName: 'Ana Souza', signedIn: true);
      await h.pumpApp();
      h.goOffline();

      await h.pumpApp();

      expect(find.text('Your Lists'), findsOneWidget);
      await h.openAccountMenu();
      expect(find.text('Ana Souza'), findsOneWidget);
    });
  });

  group('sign out', () {
    testWidgets('returns to the welcome screen and stays signed out after a restart', (tester) async {
      final h = Harness(tester);
      h.existingUser(email: anaEmail, password: password, displayName: 'Ana Souza', signedIn: true);
      await h.pumpApp();

      await h.openAccountMenu();
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();

      expect(find.text('Continue with Google'), findsOneWidget);
      await h.pumpApp();
      expect(find.text('Continue with Google'), findsOneWidget);
    });

    testWidgets('forgets the display name on this device', (tester) async {
      final h = Harness(tester);
      h.existingUser(email: anaEmail, password: password, displayName: 'Ana Souza', signedIn: true);
      h.existingUser(email: 'bruno.lima@example.com', password: password, displayName: 'Bruno');
      await h.pumpApp();
      await h.openAccountMenu();
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();

      await h.signInWithEmail('bruno.lima@example.com', password);
      h.goOffline();
      await h.pumpApp();
      await h.openAccountMenu();

      expect(find.text('Bruno'), findsOneWidget);
      expect(find.text('Ana Souza'), findsNothing);
    });
  });

  group('forgotten password', () {
    testWidgets('sends a reset email and says so', (tester) async {
      final h = Harness(tester);
      h.existingUser(email: anaEmail, password: password, displayName: 'Ana Souza');
      await h.pumpApp();
      await h.openEmailSignIn();

      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Email'), anaEmail);
      await tester.tap(find.widgetWithText(CesButton, 'Send reset link'));
      await tester.pumpAndSettle();

      expect(find.text('If an account exists for $anaEmail, we sent it a link to reset the password.'), findsOneWidget);
      expect(h.auth.passwordResetsSentTo, [anaEmail]);
    });

    testWidgets('keeps the email typed on the sign-in screen', (tester) async {
      final h = Harness(tester);
      await h.pumpApp();
      await h.openEmailSignIn();
      await tester.enterText(find.widgetWithText(TextField, 'Email'), anaEmail);

      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();

      expect(h.textInField('Email'), anaEmail);
    });
  });

  testWidgets('the sign-in screens stay usable in dark mode at the largest text size', (tester) async {
    final h = Harness(tester);
    tester.view.physicalSize = const Size(360, 640) * tester.view.devicePixelRatio;
    addTearDown(tester.view.reset);

    await h.pumpApp(themeMode: ThemeMode.dark, textScale: 3.0, locale: brazilianPortuguese);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Continuar com e-mail'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar com e-mail'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Criar conta'), findsWidgets);
  });
}
