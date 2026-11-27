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

  /// Big headline on the welcome screen.
  ///
  /// In en, this message translates to:
  /// **'One shopping list for the whole house.'**
  String get welcomeHeadline;

  /// Line under the welcome headline.
  ///
  /// In en, this message translates to:
  /// **'Add what\'s missing, see what others added, and check things off at the market.'**
  String get welcomeSubtitle;

  /// Example Item on a decorative tag on the welcome screen.
  ///
  /// In en, this message translates to:
  /// **'Oranges'**
  String get welcomeSampleOranges;

  /// Example Item on a decorative tag on the welcome screen.
  ///
  /// In en, this message translates to:
  /// **'Bread'**
  String get welcomeSampleBread;

  /// Example Item on a decorative tag on the welcome screen.
  ///
  /// In en, this message translates to:
  /// **'Coffee'**
  String get welcomeSampleCoffee;

  /// Example Item on a decorative tag on the welcome screen.
  ///
  /// In en, this message translates to:
  /// **'Eggs'**
  String get welcomeSampleEggs;

  /// Example Item on a decorative tag on the welcome screen.
  ///
  /// In en, this message translates to:
  /// **'Cheese'**
  String get welcomeSampleCheese;

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

  /// Title of the Lists screen (the home screen), which lists the User's Lists.
  ///
  /// In en, this message translates to:
  /// **'Your Lists'**
  String get listsTitle;

  /// Lists screen when the User has no Lists.
  ///
  /// In en, this message translates to:
  /// **'No Lists yet'**
  String get listsEmptyTitle;

  /// Lists screen empty state explanation.
  ///
  /// In en, this message translates to:
  /// **'Lists you create or are invited to will show up here.'**
  String get listsEmptyBody;

  /// Tooltip of the button that opens the User menu (display name, sign out).
  ///
  /// In en, this message translates to:
  /// **'User menu'**
  String get userMenu;

  /// User menu item.
  ///
  /// In en, this message translates to:
  /// **'Change display name'**
  String get userMenuChangeDisplayName;

  /// User menu item that opens the server status screen.
  ///
  /// In en, this message translates to:
  /// **'Server status'**
  String get userMenuServerStatus;

  /// User menu item that signs out.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get userMenuSignOut;

  /// Shown while the app is starting or loading the signed-in User.
  ///
  /// In en, this message translates to:
  /// **'Loading…'**
  String get loading;

  /// Shown after sign-in when the signed-in User could not be loaded from the server and nothing is stored on the device.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your details.'**
  String get userLoadFailed;

  /// Retries loading the signed-in User.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get userLoadRetry;

  /// Tooltip of the button that closes a bottom sheet.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get sheetClose;

  /// Button on the Lists screen that starts creating a List.
  ///
  /// In en, this message translates to:
  /// **'New list'**
  String get listsNew;

  /// Caption under the number of unchecked Items on a List's card, e.g. '9 to buy'.
  ///
  /// In en, this message translates to:
  /// **'to buy'**
  String get listsToBuy;

  /// Accessible label of the sign on a List's card when it has no unchecked Items.
  ///
  /// In en, this message translates to:
  /// **'Nothing to buy'**
  String get listsNothingToBuy;

  /// Subtitle of a List the User owns and hasn't shared.
  ///
  /// In en, this message translates to:
  /// **'Only you'**
  String get listsOnlyYou;

  /// Subtitle of a List the User owns and shared; count is the other Members.
  ///
  /// In en, this message translates to:
  /// **'Shared with {count, plural, =1{1 person} other{{count} people}}'**
  String listsSharedWithPeople(int count);

  /// Subtitle of a List another User owns and shared with the User (the User is an Editor).
  ///
  /// In en, this message translates to:
  /// **'Shared with you'**
  String get listsSharedWithYou;

  /// Title of the sheet that creates a List.
  ///
  /// In en, this message translates to:
  /// **'New list'**
  String get listsNewSheetTitle;

  /// Label of the List name field.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get fieldListName;

  /// Button that creates the List.
  ///
  /// In en, this message translates to:
  /// **'Create list'**
  String get listsCreate;

  /// Tooltip of the button on a List's card that opens its options (rename, delete).
  ///
  /// In en, this message translates to:
  /// **'Options for {name}'**
  String listsOptions(String name);

  /// List option that renames the List.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get listsRename;

  /// Title of the sheet that renames a List.
  ///
  /// In en, this message translates to:
  /// **'Rename list'**
  String get listsRenameSheetTitle;

  /// Button that saves a List's new name.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get listsSave;

  /// List option that deletes the List (the Owner can restore it for 30 days).
  ///
  /// In en, this message translates to:
  /// **'Delete list'**
  String get listsDelete;

  /// Toast after deleting a List; it has an Undo action.
  ///
  /// In en, this message translates to:
  /// **'“{name}” deleted'**
  String listsDeleted(String name);

  /// Toast action that restores the List just deleted.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get listsUndo;

  /// Button that restores a deleted List.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get listsRestore;

  /// Toast after restoring a deleted List.
  ///
  /// In en, this message translates to:
  /// **'“{name}” restored'**
  String listsRestored(String name);

  /// Title of the screen of Lists the User deleted and can still restore, and the menu item that opens it.
  ///
  /// In en, this message translates to:
  /// **'Recently deleted'**
  String get listsRecentlyDeleted;

  /// Explanation at the top of the Recently deleted screen; days is the restore window.
  ///
  /// In en, this message translates to:
  /// **'Deleted Lists can be restored for {days} days. After that they\'re gone for good.'**
  String listsRecentlyDeletedExplanation(int days);

  /// Recently deleted screen when there is nothing to restore; days is the restore window.
  ///
  /// In en, this message translates to:
  /// **'Nothing deleted in the last {days} days.'**
  String listsRecentlyDeletedEmpty(int days);

  /// How long a deleted List can still be restored.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{Gone today} =1{1 day left} other{{days} days left}}'**
  String listsDaysLeft(int days);

  /// Validation: List name blank.
  ///
  /// In en, this message translates to:
  /// **'Enter a name.'**
  String get errorListNameRequired;

  /// Validation: List name too long; max is the longest allowed.
  ///
  /// In en, this message translates to:
  /// **'Use {max} characters or fewer.'**
  String errorListNameTooLong(int max);

  /// List name has characters that can't be used (e.g. control characters), or the server rejected it.
  ///
  /// In en, this message translates to:
  /// **'That name can\'t be used. Try another.'**
  String get errorListNameInvalid;

  /// Creating or restoring a List failed because the User already owns the most Lists allowed (limit).
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached the limit of {limit} Lists. Delete one to create another.'**
  String errorListLimit(int limit);

  /// Creating or restoring a List failed because the User reached the List limit, when the server did not report the number.
  ///
  /// In en, this message translates to:
  /// **'You\'ve reached the limit of Lists. Delete one to create another.'**
  String get errorListLimitGeneric;

  /// The List is gone for good, or the User is no longer a Member.
  ///
  /// In en, this message translates to:
  /// **'This List is no longer available.'**
  String get errorListNotFound;

  /// Renaming failed because the List was deleted meanwhile (e.g. on another device); its Owner can still restore it.
  ///
  /// In en, this message translates to:
  /// **'This List was deleted. You can restore it from Recently deleted.'**
  String get errorListDeleted;

  /// Restoring failed because the List is gone: its restore window passed, it was purged, or the User lost access. The app can't tell which.
  ///
  /// In en, this message translates to:
  /// **'This List is no longer available and can\'t be restored.'**
  String get errorListNotRestorable;

  /// Under a List's name on its screen: how many Items are still to buy and how many are checked.
  ///
  /// In en, this message translates to:
  /// **'{toBuy} to buy, {inBasket} in the basket'**
  String listToBuyInBasket(int toBuy, int inBasket);

  /// Heading of the Checked Items on a List's screen.
  ///
  /// In en, this message translates to:
  /// **'In the basket'**
  String get listInTheBasket;

  /// The bar at the bottom of a List's screen that opens Add items.
  ///
  /// In en, this message translates to:
  /// **'Add an item'**
  String get listAddAnItem;

  /// Who checked an Item In the basket, when it was the signed-in User.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get listCheckedByYou;

  /// Screen reader hint on an Item tag: tapping it marks the Item as bought.
  ///
  /// In en, this message translates to:
  /// **'Check'**
  String get itemCheck;

  /// Screen reader hint on a Checked Item: tapping it puts the Item back to buy.
  ///
  /// In en, this message translates to:
  /// **'Uncheck'**
  String get itemUncheck;

  /// Screen reader hint on an Item tag under Matches: tapping it opens that Item instead of adding another.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get itemOpen;

  /// Heading on Add items over the Items whose names match what was typed.
  ///
  /// In en, this message translates to:
  /// **'Matches'**
  String get addItemsMatches;

  /// Label of the search field on Add items.
  ///
  /// In en, this message translates to:
  /// **'Search items'**
  String get addItemsSearch;

  /// Closes Add items and returns to the List.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get addItemsDone;

  /// Action on Add items that opens the New item sheet with the search text as its name.
  ///
  /// In en, this message translates to:
  /// **'Add “{name}” as a new item'**
  String addItemsAddAsNew(String name);

  /// Title of the sheet that adds a new Item.
  ///
  /// In en, this message translates to:
  /// **'New item'**
  String get newItemTitle;

  /// Label of the new Item's name field.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get newItemName;

  /// Label of the new Item's quantity and unit.
  ///
  /// In en, this message translates to:
  /// **'How much'**
  String get newItemHowMuch;

  /// Screen reader label of the quantity value in the stepper.
  ///
  /// In en, this message translates to:
  /// **'Quantity'**
  String get newItemQuantity;

  /// Stepper button that lowers the quantity.
  ///
  /// In en, this message translates to:
  /// **'Less'**
  String get newItemLess;

  /// Stepper button that raises the quantity.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get newItemMore;

  /// Placeholder of the new Item's note field.
  ///
  /// In en, this message translates to:
  /// **'Add a note, like “ripe ones”'**
  String get newItemNoteHint;

  /// Button that adds the new Item to the List.
  ///
  /// In en, this message translates to:
  /// **'Add to {list}'**
  String newItemAddTo(String list);

  /// The unit 'un' (counted pieces) on its chip.
  ///
  /// In en, this message translates to:
  /// **'units'**
  String get unitUn;

  /// Kilograms.
  ///
  /// In en, this message translates to:
  /// **'kg'**
  String get unitKg;

  /// Grams.
  ///
  /// In en, this message translates to:
  /// **'g'**
  String get unitG;

  /// Litres.
  ///
  /// In en, this message translates to:
  /// **'L'**
  String get unitL;

  /// Millilitres.
  ///
  /// In en, this message translates to:
  /// **'ml'**
  String get unitMl;

  /// Packs.
  ///
  /// In en, this message translates to:
  /// **'pack'**
  String get unitPack;

  /// Toast after adding an Item; it has an Undo action.
  ///
  /// In en, this message translates to:
  /// **'{item} added to {list}'**
  String itemAdded(String item, String list);

  /// Toast action that removes the Item just added.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get itemUndo;

  /// Validation: Item name blank.
  ///
  /// In en, this message translates to:
  /// **'Enter a name.'**
  String get errorItemNameRequired;

  /// Validation: Item name too long.
  ///
  /// In en, this message translates to:
  /// **'Use {max} characters or fewer.'**
  String errorItemNameTooLong(int max);

  /// Validation: the typed quantity isn't a positive number the app accepts.
  ///
  /// In en, this message translates to:
  /// **'Use a number above zero, like 2 or 1.5.'**
  String get errorItemQuantityInvalid;

  /// Pill on a List while the phone is offline (Figma 13 List offline), with how many changes wait to reach the server.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Offline} =1{Offline · 1 change waiting to sync} other{Offline · {count} changes waiting to sync}}'**
  String listOffline(int count);

  /// Subtitle of a List with no Items (Figma 15 Empty list).
  ///
  /// In en, this message translates to:
  /// **'Nothing to buy yet'**
  String get listNothingToBuyYet;

  /// Heading of a List with no Items.
  ///
  /// In en, this message translates to:
  /// **'Start your list'**
  String get listEmptyTitle;

  /// Body of a List with no Items.
  ///
  /// In en, this message translates to:
  /// **'Add what you need. Everyone on this list sees it right away.'**
  String get listEmptyBody;

  /// Title of the Opened item sheet.
  ///
  /// In en, this message translates to:
  /// **'Edit item'**
  String get itemEditTitle;

  /// Saves the edits to an Item.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get itemSave;

  /// Who added the Item, on the Opened item sheet.
  ///
  /// In en, this message translates to:
  /// **'Added by {name}'**
  String itemAddedBy(String name);

  /// The signed-in User added the Item.
  ///
  /// In en, this message translates to:
  /// **'Added by you'**
  String get itemAddedByYou;

  /// Who checked the Item, on the Opened item sheet.
  ///
  /// In en, this message translates to:
  /// **'Checked by {name}'**
  String itemCheckedBy(String name);

  /// The signed-in User checked the Item.
  ///
  /// In en, this message translates to:
  /// **'Checked by you'**
  String get itemCheckedByYou;

  /// Removes the Item from the List.
  ///
  /// In en, this message translates to:
  /// **'Remove item'**
  String get itemRemove;

  /// Toast after removing an Item; it has an Undo action.
  ///
  /// In en, this message translates to:
  /// **'{item} removed'**
  String itemRemoved(String item);

  /// Toast (Figma 13b): a change to an Item that someone else removed was not saved.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t save “{name}”. It was removed.'**
  String itemRejectedRemoved(String name);

  /// Toast: a change was not saved because its List was deleted or the User left it.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t save “{name}”. The list is no longer available.'**
  String itemRejectedListGone(String name);

  /// Toast: the server refused a change made on this device, which was undone.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t save “{name}”.'**
  String itemRejected(String name);

  /// Title of the Item limit sheet (Figma 14).
  ///
  /// In en, this message translates to:
  /// **'This list is full'**
  String get itemLimitTitle;

  /// Body of the Item limit sheet.
  ///
  /// In en, this message translates to:
  /// **'A list can hold up to {max} items. Remove ones you no longer need to make room.'**
  String itemLimitBody(int max);
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
