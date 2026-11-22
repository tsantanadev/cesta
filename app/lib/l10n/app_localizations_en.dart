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
  String get healthRetry => 'Check again';
}
