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

      expect(find.text('One shopping list for the whole house.'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Continue with email'), findsOneWidget);
      expect(find.text('Your Lists'), findsNothing);
    });

    testWidgets('the welcome screen is in Brazilian Portuguese on a Portuguese phone', (tester) async {
      final h = Harness(tester);

      await h.pumpApp(locale: brazilianPortuguese);

      expect(find.text('Uma lista de compras para a casa toda.'), findsOneWidget);
      expect(find.text('Continuar com Google'), findsOneWidget);
      expect(find.text('Continuar com e-mail'), findsOneWidget);
    });
  });

  group('sign in with email', () {
    testWidgets('leads to the home screen, and signing out returns to the welcome screen', (tester) async {
      final h = Harness(tester);
      h.existingUser(email: anaEmail, password: password, displayName: 'Ana Souza');
      await h.pumpApp();

      await h.signInWithEmail(anaEmail, password);

      expect(find.text('Your Lists'), findsOneWidget);
      expect(find.text('No Lists yet'), findsOneWidget);

      await h.signOut();

      expect(find.text('Continue with Google'), findsOneWidget);
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
      expect(find.byType(CesMessage), findsNothing); // only the form says what is missing, no sign-in error
    });
  });

  group('sign up with email', () {
    testWidgets('asks the new User to confirm a display name, then goes home', (tester) async {
      final h = Harness(tester);
      await h.pumpApp();

      await h.signUpWithEmail('bruno.lima@example.com', password);

      expect(find.text('What should we call you?'), findsOneWidget);
      expect(h.textInField('Display name'), 'bruno.lima');

      await tester.enterText(field('Display name'), 'Bruno');
      await tester.tap(find.widgetWithText(CesButton, 'Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Your Lists'), findsOneWidget);
      await h.openUserMenu();
      expect(find.text('Bruno'), findsOneWidget);
    });

    testWidgets('signing out after sign-up returns to the welcome screen', (tester) async {
      final h = Harness(tester);
      await h.pumpApp();
      await h.signUpWithEmail('bruno.lima@example.com', password);
      await tester.tap(find.widgetWithText(CesButton, 'Continue'));
      await tester.pumpAndSettle();

      await h.signOut();

      expect(find.text('Continue with Google'), findsOneWidget);
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
      expect(find.byType(CesMessage), findsNothing); // only the form says what is wrong, no sign-up error
    });
  });

  group('sign in with Google', () {
    testWidgets('a first-time Google User confirms the name from Google, then goes home', (tester) async {
      final h = Harness(tester);
      await h.signInWithGoogleForTheFirstTime();

      expect(find.text('What should we call you?'), findsOneWidget);
      expect(h.textInField('Display name'), 'Ana Souza');

      await tester.tap(find.widgetWithText(CesButton, 'Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Your Lists'), findsOneWidget);

      await h.pumpApp(); // the confirmed name sticks: no second time on the name screen
      expect(find.text('Your Lists'), findsOneWidget);
    });

    testWidgets('a returning User goes straight home, and signing out returns to the welcome screen', (tester) async {
      final h = Harness(tester);
      h.existingUser(email: anaEmail, password: password, displayName: 'Ana Souza', withGoogle: true);
      await h.pumpApp();

      await h.tap(find.text('Continue with Google'));
      expect(find.text('Your Lists'), findsOneWidget);

      await h.signOut();

      expect(find.text('Continue with Google'), findsOneWidget);
    });

    testWidgets('closing the Google account picker stays on the welcome screen without an error', (tester) async {
      final h = Harness(tester);
      h.auth.googleAccount = null; // the User backs out of the picker
      await h.pumpApp();

      await h.tap(find.text('Continue with Google'));

      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.byType(CesMessage), findsNothing);
    });
  });

  group('loading a new User', () {
    testWidgets('offline, says so and offers to try again', (tester) async {
      final h = Harness(tester);
      h.api.goOffline(); // signed in at the provider, but the backend can't be reached
      await h.signInWithGoogleForTheFirstTime();

      expect(find.text("You're offline. Connect to the internet and try again."), findsOneWidget);
      expect(find.text('Your Lists'), findsNothing);

      h.api.goOnline();
      await tester.tap(find.widgetWithText(CesButton, 'Try again'));
      await tester.pumpAndSettle();

      expect(find.text('What should we call you?'), findsOneWidget);
    });

    testWidgets('when it keeps failing, the User can sign out', (tester) async {
      final h = Harness(tester);
      h.api.rateLimited = true;
      await h.signInWithGoogleForTheFirstTime();
      expect(find.text('Too many attempts. Wait a moment and try again.'), findsOneWidget);

      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();

      expect(find.text('Continue with Google'), findsOneWidget);
    });
  });

  group('display name', () {
    testWidgets('must not be blank or longer than 50 characters', (tester) async {
      final h = Harness(tester);
      await h.signInWithGoogleForTheFirstTime();

      await tester.enterText(field('Display name'), '   ');
      await tester.tap(find.widgetWithText(CesButton, 'Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Enter a name.'), findsOneWidget);

      await tester.enterText(field('Display name'), 'a' * 51);
      await tester.tap(find.widgetWithText(CesButton, 'Continue'));
      await tester.pumpAndSettle();
      expect(find.text('Use 50 characters or fewer.'), findsOneWidget);

      await h.pumpApp(); // nothing was saved: still asked for a name
      expect(find.text('What should we call you?'), findsOneWidget);
    });

    testWidgets('a name the server rejects says it cannot be used', (tester) async {
      final h = Harness(tester);
      await h.signInWithGoogleForTheFirstTime();
      h.api.rejectDisplayNames = true;

      await tester.tap(find.widgetWithText(CesButton, 'Continue'));
      await tester.pumpAndSettle();

      expect(find.text("That name can't be used. Try another."), findsOneWidget);
    });

    testWidgets('a name with control characters is rejected before saving', (tester) async {
      final h = Harness(tester);
      await h.signInWithGoogleForTheFirstTime();

      await tester.enterText(field('Display name'), 'Ana\u0007');
      await tester.tap(find.widgetWithText(CesButton, 'Continue'));
      await tester.pumpAndSettle();

      expect(find.text("That name can't be used. Try another."), findsOneWidget);
      await h.pumpApp(); // nothing was saved: still asked for a name
      expect(find.text('What should we call you?'), findsOneWidget);
    });

    testWidgets('when the server is rate limiting, says to wait', (tester) async {
      final h = Harness(tester);
      await h.signInWithGoogleForTheFirstTime();
      h.api.rateLimited = true;

      await tester.tap(find.widgetWithText(CesButton, 'Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Too many attempts. Wait a moment and try again.'), findsOneWidget);
    });

    testWidgets('an Item tile previews the name as it is typed', (tester) async {
      final h = Harness(tester);
      await h.signInWithGoogleForTheFirstTime();

      await tester.enterText(field('Display name'), 'Marina');
      await tester.pump();

      expect(find.descendant(of: find.byType(CesItemTile), matching: find.text('Marina')), findsOneWidget);
    });

    testWidgets('a new User can sign out from the name screen instead of confirming', (tester) async {
      final h = Harness(tester);
      await h.signInWithGoogleForTheFirstTime();
      h.goOffline(); // can't save the name, so signing out is the only way on

      await tester.tap(find.widgetWithText(CesButton, 'Continue'));
      await tester.pumpAndSettle();
      expect(find.text("You're offline. Connect to the internet and try again."), findsOneWidget);
      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();

      expect(find.text('Continue with Google'), findsOneWidget);
    });

    testWidgets('can be changed later from the User menu', (tester) async {
      final h = Harness(tester);
      h.existingUser(email: anaEmail, password: password, displayName: 'Ana Souza', signedIn: true);
      await h.pumpApp();

      await h.openUserMenu();
      expect(find.text('Ana Souza'), findsOneWidget);
      await tester.tap(find.text('Change display name'));
      await tester.pumpAndSettle();
      await tester.enterText(field('Display name'), 'Aninha');
      await tester.tap(find.widgetWithText(CesButton, 'Save'));
      await tester.pumpAndSettle();

      expect(find.text('Your Lists'), findsOneWidget);
      await h.openUserMenu();
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
      await h.openUserMenu();
      expect(find.text('Ana Souza'), findsOneWidget);
    });
  });

  group('sign out', () {
    testWidgets('returns to the welcome screen and stays signed out after a restart', (tester) async {
      final h = Harness(tester);
      h.existingUser(email: anaEmail, password: password, displayName: 'Ana Souza', signedIn: true);
      await h.pumpApp();

      await h.signOut();

      expect(find.text('Continue with Google'), findsOneWidget);
      await h.pumpApp();
      expect(find.text('Continue with Google'), findsOneWidget);
    });

    testWidgets('forgets the display name on this device', (tester) async {
      final h = Harness(tester);
      h.existingUser(email: anaEmail, password: password, displayName: 'Ana Souza', signedIn: true);
      h.existingUser(email: 'bruno.lima@example.com', password: password, displayName: 'Bruno');
      await h.pumpApp();
      await h.signOut();

      await h.signInWithEmail('bruno.lima@example.com', password);
      h.goOffline();
      await h.pumpApp();
      await h.openUserMenu();

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
      await tester.enterText(field('Email'), anaEmail);
      await tester.tap(find.widgetWithText(CesButton, 'Send reset link'));
      await tester.pumpAndSettle();

      expect(find.text('If an account exists for $anaEmail, we sent it a link to reset the password.'), findsOneWidget);
      expect(h.auth.passwordResetsSentTo, [anaEmail]); // the email the User would receive
    });

    testWidgets('keeps the email typed on the sign-in screen', (tester) async {
      final h = Harness(tester);
      await h.pumpApp();
      await h.openEmailSignIn();
      await tester.enterText(field('Email'), anaEmail);

      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();

      expect(h.textInField('Email'), anaEmail);
    });
  });

  testWidgets('the sign-in screens stay usable in dark mode at the largest text size', (tester) async {
    final h = Harness(tester);

    await h.pumpApp(
      themeMode: ThemeMode.dark,
      textScale: 3.0,
      screen: const Size(360, 640),
      locale: brazilianPortuguese,
    );
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Continuar com e-mail'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continuar com e-mail'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Criar conta'), findsWidgets);
  });

  testWidgets(
    'on iOS, signing in and out works with the Cupertino controls',
    variant: TargetPlatformVariant.only(TargetPlatform.iOS),
    (tester) async {
      final h = Harness(tester);
      h.existingUser(email: anaEmail, password: password, displayName: 'Ana Souza');
      await h.pumpApp();

      await h.openEmailSignIn();
      await tester.tap(find.widgetWithText(CesButton, 'Sign in'));
      await tester.pumpAndSettle();
      expect(find.text('Enter your email address.'), findsOneWidget);

      await tester.enterText(field('Email'), anaEmail);
      await tester.enterText(field('Password'), password);
      await tester.tap(find.widgetWithText(CesButton, 'Sign in'));
      await tester.pumpAndSettle();
      expect(find.text('Your Lists'), findsOneWidget);

      await h.signOut(); // from an action sheet
      expect(find.text('Continue with Google'), findsOneWidget);
    },
  );
}
