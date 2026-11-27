// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Cesta';

  @override
  String get healthTitle => 'Server status';

  @override
  String get healthChecking => 'Checking the server…';

  @override
  String get healthServerUp => 'Server is up';

  @override
  String get healthServerDegraded => 'Server is degraded';

  @override
  String get healthDatabaseUp => 'Database: connected';

  @override
  String get healthDatabaseDown => 'Database: unreachable';

  @override
  String get healthOffline => 'You\'re offline';

  @override
  String get healthOfflineNoData => 'Couldn\'t reach the server.';

  @override
  String get healthLastKnown => 'Last known status';

  @override
  String get healthCheckFailed => 'Couldn\'t check the server status.';

  @override
  String get healthRetry => 'Check again';

  @override
  String get welcomeHeadline => 'One shopping list for the whole house.';

  @override
  String get welcomeSubtitle => 'Add what\'s missing, see what others added, and check things off at the market.';

  @override
  String get welcomeSampleOranges => 'Oranges';

  @override
  String get welcomeSampleBread => 'Bread';

  @override
  String get welcomeSampleCoffee => 'Coffee';

  @override
  String get welcomeSampleEggs => 'Eggs';

  @override
  String get welcomeSampleCheese => 'Cheese';

  @override
  String get welcomeContinueWithGoogle => 'Continue with Google';

  @override
  String get welcomeContinueWithEmail => 'Continue with email';

  @override
  String get signInTitle => 'Sign in';

  @override
  String get signInButton => 'Sign in';

  @override
  String get signInForgotPassword => 'Forgot password?';

  @override
  String get signInNoAccount => 'New here? Create an account';

  @override
  String get signUpTitle => 'Create account';

  @override
  String get signUpButton => 'Create account';

  @override
  String get signUpHaveAccount => 'Already have an account? Sign in';

  @override
  String get fieldEmail => 'Email';

  @override
  String get fieldPassword => 'Password';

  @override
  String get fieldPasswordShow => 'Show password';

  @override
  String get fieldPasswordHide => 'Hide password';

  @override
  String get fieldPasswordHint => 'At least 8 characters';

  @override
  String get errorEmailRequired => 'Enter your email address.';

  @override
  String get errorEmailInvalid => 'Enter a valid email address.';

  @override
  String get errorPasswordRequired => 'Enter your password.';

  @override
  String get errorPasswordTooShort => 'Use at least 8 characters.';

  @override
  String get errorWrongCredentials => 'Wrong email or password.';

  @override
  String get errorEmailInUse => 'An account with this email already exists. Sign in instead.';

  @override
  String get errorWeakPassword => 'Choose a stronger password.';

  @override
  String get errorOffline => 'You\'re offline. Connect to the internet and try again.';

  @override
  String get errorTooManyAttempts => 'Too many attempts. Wait a moment and try again.';

  @override
  String get errorAccountDisabled => 'This account has been disabled.';

  @override
  String get errorOtherSignInMethod =>
      'This email is already used with another sign-in method. Sign in that way instead.';

  @override
  String get errorUnknown => 'Something went wrong. Try again.';

  @override
  String get resetTitle => 'Reset password';

  @override
  String get resetExplanation =>
      'Enter the email you signed up with and we\'ll send you a link to choose a new password.';

  @override
  String get resetButton => 'Send reset link';

  @override
  String resetSent(String email) {
    return 'If an account exists for $email, we sent it a link to reset the password.';
  }

  @override
  String get resetBackToSignIn => 'Back to sign in';

  @override
  String get displayNameOnboardingTitle => 'What should we call you?';

  @override
  String get displayNameExplanation => 'Other Members of your Lists see this name.';

  @override
  String get displayNameEditTitle => 'Display name';

  @override
  String get fieldDisplayName => 'Display name';

  @override
  String get displayNameContinue => 'Continue';

  @override
  String get displayNameSave => 'Save';

  @override
  String get errorDisplayNameRequired => 'Enter a name.';

  @override
  String get errorDisplayNameTooLong => 'Use 50 characters or fewer.';

  @override
  String get errorDisplayNameInvalid => 'That name can\'t be used. Try another.';

  @override
  String get listsTitle => 'Your Lists';

  @override
  String get listsEmptyTitle => 'No Lists yet';

  @override
  String get listsEmptyBody => 'Lists you create or are invited to will show up here.';

  @override
  String get userMenu => 'User menu';

  @override
  String get userMenuChangeDisplayName => 'Change display name';

  @override
  String get userMenuServerStatus => 'Server status';

  @override
  String get userMenuSignOut => 'Sign out';

  @override
  String get loading => 'Loading…';

  @override
  String get userLoadFailed => 'We couldn\'t load your details.';

  @override
  String get userLoadRetry => 'Try again';

  @override
  String get sheetClose => 'Close';

  @override
  String get listsNew => 'New list';

  @override
  String get listsToBuy => 'to buy';

  @override
  String get listsNothingToBuy => 'Nothing to buy';

  @override
  String get listsOnlyYou => 'Only you';

  @override
  String listsSharedWithPeople(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count people', one: '1 person');
    return 'Shared with $_temp0';
  }

  @override
  String get listsSharedWithYou => 'Shared with you';

  @override
  String get listsNewSheetTitle => 'New list';

  @override
  String get fieldListName => 'Name';

  @override
  String get listsCreate => 'Create list';

  @override
  String listsOptions(String name) {
    return 'Options for $name';
  }

  @override
  String get listsRename => 'Rename';

  @override
  String get listsRenameSheetTitle => 'Rename list';

  @override
  String get listsSave => 'Save';

  @override
  String get listsDelete => 'Delete list';

  @override
  String listsDeleted(String name) {
    return '“$name” deleted';
  }

  @override
  String get listsUndo => 'Undo';

  @override
  String get listsRestore => 'Restore';

  @override
  String listsRestored(String name) {
    return '“$name” restored';
  }

  @override
  String get listsRecentlyDeleted => 'Recently deleted';

  @override
  String listsRecentlyDeletedExplanation(int days) {
    return 'Deleted Lists can be restored for $days days. After that they\'re gone for good.';
  }

  @override
  String listsRecentlyDeletedEmpty(int days) {
    return 'Nothing deleted in the last $days days.';
  }

  @override
  String listsDaysLeft(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days left',
      one: '1 day left',
      zero: 'Gone today',
    );
    return '$_temp0';
  }

  @override
  String get errorListNameRequired => 'Enter a name.';

  @override
  String errorListNameTooLong(int max) {
    return 'Use $max characters or fewer.';
  }

  @override
  String get errorListNameInvalid => 'That name can\'t be used. Try another.';

  @override
  String errorListLimit(int limit) {
    return 'You\'ve reached the limit of $limit Lists. Delete one to create another.';
  }

  @override
  String get errorListLimitGeneric => 'You\'ve reached the limit of Lists. Delete one to create another.';

  @override
  String get errorListNotFound => 'This List is no longer available.';

  @override
  String get errorListDeleted => 'This List was deleted. You can restore it from Recently deleted.';

  @override
  String get errorListNotRestorable => 'This List is no longer available and can\'t be restored.';

  @override
  String listToBuyInBasket(int toBuy, int inBasket) {
    return '$toBuy to buy, $inBasket in the basket';
  }

  @override
  String get listInTheBasket => 'In the basket';

  @override
  String get listAddAnItem => 'Add an item';

  @override
  String get listCheckedByYou => 'You';

  @override
  String get itemCheck => 'Check';

  @override
  String get itemUncheck => 'Uncheck';

  @override
  String get itemOpen => 'Open';

  @override
  String get addItemsMatches => 'Matches';

  @override
  String get addItemsSearch => 'Search items';

  @override
  String get addItemsDone => 'Done';

  @override
  String addItemsAddAsNew(String name) {
    return 'Add “$name” as a new item';
  }

  @override
  String get newItemTitle => 'New item';

  @override
  String get newItemName => 'Name';

  @override
  String get newItemHowMuch => 'How much';

  @override
  String get newItemQuantity => 'Quantity';

  @override
  String get newItemLess => 'Less';

  @override
  String get newItemMore => 'More';

  @override
  String get newItemNoteHint => 'Add a note, like “ripe ones”';

  @override
  String newItemAddTo(String list) {
    return 'Add to $list';
  }

  @override
  String get unitUn => 'units';

  @override
  String get unitKg => 'kg';

  @override
  String get unitG => 'g';

  @override
  String get unitL => 'L';

  @override
  String get unitMl => 'ml';

  @override
  String get unitPack => 'pack';

  @override
  String itemAdded(String item, String list) {
    return '$item added to $list';
  }

  @override
  String get itemUndo => 'Undo';

  @override
  String get errorItemNameRequired => 'Enter a name.';

  @override
  String errorItemNameTooLong(int max) {
    return 'Use $max characters or fewer.';
  }

  @override
  String get errorItemQuantityInvalid => 'Use a number above zero, like 2 or 1.5.';

  @override
  String listOffline(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Offline · $count changes waiting to sync',
      one: 'Offline · 1 change waiting to sync',
      zero: 'Offline',
    );
    return '$_temp0';
  }

  @override
  String get listNothingToBuyYet => 'Nothing to buy yet';

  @override
  String get listEmptyTitle => 'Start your list';

  @override
  String get listEmptyBody => 'Add what you need. Everyone on this list sees it right away.';

  @override
  String get itemEditTitle => 'Edit item';

  @override
  String get itemSave => 'Save';

  @override
  String itemAddedBy(String name) {
    return 'Added by $name';
  }

  @override
  String get itemAddedByYou => 'Added by you';

  @override
  String itemCheckedBy(String name) {
    return 'Checked by $name';
  }

  @override
  String get itemCheckedByYou => 'Checked by you';

  @override
  String get itemRemove => 'Remove item';

  @override
  String itemRemoved(String item) {
    return '$item removed';
  }

  @override
  String itemRejectedRemoved(String name) {
    return 'Couldn’t save “$name”. It was removed.';
  }

  @override
  String itemRejectedListGone(String name) {
    return 'Couldn’t save “$name”. The list is no longer available.';
  }

  @override
  String itemRejected(String name) {
    return 'Couldn’t save “$name”.';
  }

  @override
  String get itemLimitTitle => 'This list is full';

  @override
  String itemLimitBody(int max) {
    return 'A list can hold up to $max items. Remove ones you no longer need to make room.';
  }
}
