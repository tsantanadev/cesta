import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en'), Locale('pt')];

  /// App name shown in the task switcher.
  ///
  /// In en, this message translates to:
  /// **'Cesta'**
  String get appTitle;

  /// Title of the placeholder screen that shows backend health.
  ///
  /// In en, this message translates to:
  /// **'Server status'**
  String get healthTitle;

  /// Shown while the health check is in flight.
  ///
  /// In en, this message translates to:
  /// **'Checking the server…'**
  String get healthChecking;

  /// The backend answered and is healthy.
  ///
  /// In en, this message translates to:
  /// **'Server is up'**
  String get healthServerUp;

  /// The backend answered but reports a problem.
  ///
  /// In en, this message translates to:
  /// **'Server is degraded'**
  String get healthServerDegraded;

  /// The backend can reach its database.
  ///
  /// In en, this message translates to:
  /// **'Database: connected'**
  String get healthDatabaseUp;

  /// The backend cannot reach its database.
  ///
  /// In en, this message translates to:
  /// **'Database: unreachable'**
  String get healthDatabaseDown;

  /// The app could not reach the backend.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline'**
  String get healthOffline;

  /// Offline and no earlier result is stored on the device.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach the server.'**
  String get healthOfflineNoData;

  /// Heading above the last health result stored on the device, shown when offline.
  ///
  /// In en, this message translates to:
  /// **'Last known status'**
  String get healthLastKnown;

  /// The health check failed for a reason other than being offline, e.g. an unreadable response or a local storage error.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t check the server status.'**
  String get healthCheckFailed;

  /// Button that repeats the health check.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get healthRetry;

  /// Welcome screen line under the app name.
  ///
  /// In en, this message translates to:
  /// **'Shared shopping lists that work in the store, with or without signal.'**
  String get welcomeTagline;

  /// Button that signs in or signs up with a Google account.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get welcomeContinueWithGoogle;

  /// Button that opens the email sign-up form.
  ///
  /// In en, this message translates to:
  /// **'Continue with email'**
  String get welcomeContinueWithEmail;

  /// Link from the welcome screen to the email sign-in form.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get welcomeHaveAccount;

  /// Title of the email sign-in screen.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInTitle;

  /// Button that signs in with email and password.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signInButton;

  /// Link to the password reset screen.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get signInForgotPassword;

  /// Link from sign-in to sign-up.
  ///
  /// In en, this message translates to:
  /// **'New here? Create an account'**
  String get signInNoAccount;

  /// Title of the email sign-up screen.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signUpTitle;

  /// Button that creates an account with email and password.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get signUpButton;

  /// Link from sign-up to sign-in.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get signUpHaveAccount;

  /// Label of the email address field.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get fieldEmail;

  /// Label of the password field.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get fieldPassword;

  /// Tooltip of the button that reveals the password.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get fieldPasswordShow;

  /// Tooltip of the button that hides the password.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get fieldPasswordHide;

  /// Helper text under the new password field on sign-up.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get fieldPasswordHint;

  /// Validation: email left empty.
  ///
  /// In en, this message translates to:
  /// **'Enter your email address.'**
  String get errorEmailRequired;

  /// Validation or server: the email address is malformed.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get errorEmailInvalid;

  /// Validation: password left empty on sign-in.
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get errorPasswordRequired;

  /// Validation: new password too short.
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters.'**
  String get errorPasswordTooShort;

  /// Sign-in failed because the email or password is wrong.
  ///
  /// In en, this message translates to:
  /// **'Wrong email or password.'**
  String get errorWrongCredentials;

  /// Sign-up failed because the email already has an account.
  ///
  /// In en, this message translates to:
  /// **'An account with this email already exists. Sign in instead.'**
  String get errorEmailInUse;

  /// The identity provider rejected the password as too weak.
  ///
  /// In en, this message translates to:
  /// **'Choose a stronger password.'**
  String get errorWeakPassword;

  /// An action that needs the network failed because the device is offline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. Connect to the internet and try again.'**
  String get errorOffline;

  /// The identity provider or the server is rate limiting this device.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait a moment and try again.'**
  String get errorTooManyAttempts;

  /// Sign-in failed because the account is disabled.
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled.'**
  String get errorAccountDisabled;

  /// The email already has an account that signs in another way.
  ///
  /// In en, this message translates to:
  /// **'This email is already used with another sign-in method. Sign in that way instead.'**
  String get errorOtherSignInMethod;

  /// Fallback error for unexpected failures.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get errorUnknown;

  /// Title of the password reset screen.
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get resetTitle;

  /// Explanation on the password reset screen.
  ///
  /// In en, this message translates to:
  /// **'Enter the email you signed up with and we\'ll send you a link to choose a new password.'**
  String get resetExplanation;

  /// Button that sends the password reset email.
  ///
  /// In en, this message translates to:
  /// **'Send reset link'**
  String get resetButton;

  /// Confirmation after requesting a password reset. Deliberately does not reveal whether the account exists.
  ///
  /// In en, this message translates to:
  /// **'If an account exists for {email}, we sent it a link to reset the password.'**
  String resetSent(String email);

  /// Button that returns to sign-in after sending a reset link.
  ///
  /// In en, this message translates to:
  /// **'Back to sign in'**
  String get resetBackToSignIn;

  /// Title of the display name screen shown once after sign-up.
  ///
  /// In en, this message translates to:
  /// **'What should we call you?'**
  String get displayNameOnboardingTitle;

  /// Explains what the display name is for.
  ///
  /// In en, this message translates to:
  /// **'Other Members of your Lists see this name.'**
  String get displayNameExplanation;

  /// Title of the screen that changes the display name.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayNameEditTitle;

  /// Label of the display name field.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get fieldDisplayName;

  /// Confirms the display name during onboarding.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get displayNameContinue;

  /// Saves a changed display name.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get displayNameSave;

  /// Validation: display name blank.
  ///
  /// In en, this message translates to:
  /// **'Enter a name.'**
  String get errorDisplayNameRequired;

  /// Validation: display name over 50 characters.
  ///
  /// In en, this message translates to:
  /// **'Use 50 characters or fewer.'**
  String get errorDisplayNameTooLong;

  /// Display name has characters that can't be used (e.g. control characters), or the server rejected it.
  ///
  /// In en, this message translates to:
  /// **'That name can\'t be used. Try another.'**
  String get errorDisplayNameInvalid;

  /// Title of the home screen, which lists the User's Lists.
  ///
  /// In en, this message translates to:
  /// **'Your Lists'**
  String get homeTitle;

  /// Home screen when the User has no Lists.
  ///
  /// In en, this message translates to:
  /// **'No Lists yet'**
  String get homeEmptyTitle;

  /// Home screen empty state explanation.
  ///
  /// In en, this message translates to:
  /// **'Lists you create or are invited to will show up here.'**
  String get homeEmptyBody;

  /// Tooltip of the button that opens the User menu (display name, sign out).
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get userMenu;

  /// Account menu item.
  ///
  /// In en, this message translates to:
  /// **'Change display name'**
  String get userMenuChangeDisplayName;

  /// Account menu item that opens the server status screen.
  ///
  /// In en, this message translates to:
  /// **'Server status'**
  String get userMenuServerStatus;

  /// Account menu item that signs out.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get userMenuSignOut;

  /// Shown while the app is starting or loading the account.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'pt':
      return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
