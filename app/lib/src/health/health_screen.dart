import 'dart:async';

import 'package:dio/dio.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../api/generated/cesta_api.dart';
import '../db/app_database.dart';
import '../ui/components.dart';

/// Placeholder screen for the walking skeleton: calls the backend health
/// endpoint through the generated client, remembers the result locally and
/// shows the last known result when the backend can't be reached.
class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key, required this.api, required this.database});

  final ApiClient api;
  final AppDatabase database;

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

sealed class _HealthState {
  const _HealthState();
}

final class _Checking extends _HealthState {
  const _Checking();
}

final class _Reached extends _HealthState {
  const _Reached(this.serverUp, this.databaseUp);
  final bool serverUp;
  final bool databaseUp;
}

final class _Unreachable extends _HealthState {
  const _Unreachable(this.lastKnown);
  final KnownHealthData? lastKnown;
}

/// The check failed for a reason other than the network, e.g. a response the
/// client could not parse or a local database error.
final class _Failed extends _HealthState {
  const _Failed();
}

class _HealthScreenState extends State<HealthScreen> {
  _HealthState _state = const _Checking();

  @override
  void initState() {
    super.initState();
    unawaited(_check());
  }

  Future<void> _check() async {
    setState(() => _state = const _Checking());
    _HealthState next;
    try {
      next = await _fetch();
    } catch (_) {
      // Whatever goes wrong, never leave the screen stuck on "checking".
      next = const _Failed();
    }
    if (mounted) setState(() => _state = next);
  }

  Future<_HealthState> _fetch() async {
    try {
      final health = switch (await widget.api.getHealth()) {
        GetHealth200(:final value) => value,
        GetHealth503(:final value) => value,
      };
      final serverUp = health.status == HealthStatus.ok;
      final databaseUp = health.database == HealthDatabase.up;
      await widget.database.saveKnownHealth(serverUp: serverUp, databaseUp: databaseUp);
      return _Reached(serverUp, databaseUp);
    } on DioException {
      return _Unreachable(await widget.database.readKnownHealth());
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CesScaffold(
      title: l10n.healthTitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...switch (_state) {
            _Checking() => [CesProgress(label: l10n.healthChecking)],
            _Reached(:final serverUp, :final databaseUp) => [_healthCard(l10n, serverUp, databaseUp)],
            _Unreachable(:final lastKnown) => [
              CesStatusCard(
                tone: CesTone.neutral,
                title: l10n.healthOffline,
                lines: [if (lastKnown == null) l10n.healthOfflineNoData],
              ),
              if (lastKnown != null) ...[
                const CesGap.md(),
                _healthCard(l10n, lastKnown.serverUp, lastKnown.databaseUp, caption: l10n.healthLastKnown),
              ],
            ],
            _Failed() => [CesStatusCard(tone: CesTone.warning, title: l10n.healthCheckFailed)],
          },
          const CesGap.lg(),
          CesButton(label: l10n.healthRetry, onPressed: _state is _Checking ? null : _check),
        ],
      ),
    );
  }

  Widget _healthCard(AppLocalizations l10n, bool serverUp, bool databaseUp, {String? caption}) => CesStatusCard(
    tone: serverUp && databaseUp ? CesTone.positive : CesTone.warning,
    caption: caption,
    title: serverUp ? l10n.healthServerUp : l10n.healthServerDegraded,
    lines: [databaseUp ? l10n.healthDatabaseUp : l10n.healthDatabaseDown],
  );
}
