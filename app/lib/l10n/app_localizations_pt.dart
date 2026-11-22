// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class AppLocalizationsPt extends AppLocalizations {
  AppLocalizationsPt([String locale = 'pt']) : super(locale);

  @override
  String get appTitle => 'Cesta';

  @override
  String get healthTitle => 'Status do servidor';

  @override
  String get healthChecking => 'Verificando o servidor…';

  @override
  String get healthServerUp => 'Servidor no ar';

  @override
  String get healthServerDegraded => 'Servidor instável';

  @override
  String get healthDatabaseUp => 'Banco de dados: conectado';

  @override
  String get healthDatabaseDown => 'Banco de dados: inacessível';

  @override
  String get healthOffline => 'Você está offline';

  @override
  String get healthOfflineNoData => 'Não foi possível acessar o servidor.';

  @override
  String get healthLastKnown => 'Último status conhecido';

  @override
  String get healthRetry => 'Verificar novamente';
}
