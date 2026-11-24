import 'package:material_ui/material_ui.dart';

import '../l10n/app_localizations.dart';
import 'api/generated/cesta_api.dart';
import 'db/app_database.dart';
import 'health/health_screen.dart';
import 'ui/theme.dart';

/// The Cesta app. Its dependencies are passed in so tests can supply an
/// in-memory database and a fake API client.
class CestaApp extends StatelessWidget {
  const CestaApp({
    super.key,
    required this.api,
    required this.database,
    this.locale,
    this.themeMode = ThemeMode.system,
  });

  final ApiClient api;
  final AppDatabase database;

  /// Forces a locale; null follows the device.
  final Locale? locale;
  final ThemeMode themeMode;

  @override
  Widget build(BuildContext context) => MaterialApp(
    onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
    theme: CestaTheme.light(),
    darkTheme: CestaTheme.dark(),
    themeMode: themeMode,
    locale: locale,
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [AppLocalizations.delegate, ...GlobalMaterialLocalizations.delegates],
    home: HealthScreen(api: api, database: database),
  );
}
