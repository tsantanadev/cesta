import 'package:drift_flutter/drift_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:material_ui/material_ui.dart';

import 'src/api/api_transport.dart';
import 'src/api/generated/cesta_api.dart';
import 'src/app.dart';
import 'src/auth/firebase_auth_gateway.dart';
import 'src/db/app_database.dart';
import 'src/sync/network_status.dart';

/// Backend base URL. Override with `--dart-define=API_BASE_URL=...`
/// (the Android emulator reaches the host as http://10.0.2.2:8080).
const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8080');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Reads google-services.json / GoogleService-Info.plist (infra/auth-setup.sh).
  await Firebase.initializeApp();
  final auth = FirebaseAuthGateway();
  final api = CestaApi(createApiTransport(baseUrl: apiBaseUrl, idToken: auth.idToken)).api;
  final database = AppDatabase(driftDatabase(name: 'cesta'));
  runApp(CestaApp(api: api, auth: auth, database: database, network: DeviceNetworkStatus()));
}
