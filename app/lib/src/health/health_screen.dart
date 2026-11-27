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
  const _Reached(this.health);
  final Health health;
}

final class _Unreachable extends _HealthState {
  const _Unreachable(this.lastKnown);
  final Health? lastKnown;
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
        GetHealth429() => throw StateError('rate limited'),
      };
      await widget.database.saveKnownHealth(health);
      return _Reached(health);
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
            _Reached(:final health) => [_healthCard(l10n, health)],
            _Unreachable(:final lastKnown) => [
              CesStatusCard(
                tone: CesTone.neutral,
                title: l10n.healthOffline,
                lines: [if (lastKnown == null) l10n.healthOfflineNoData],
              ),
              if (lastKnown != null) ...[
                const CesGap.md(),
                _healthCard(l10n, lastKnown, caption: l10n.healthLastKnown),
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

  Widget _healthCard(AppLocalizations l10n, Health health, {String? caption}) => CesStatusCard(
    tone: health.status == HealthStatus.ok && health.database == HealthDatabase.up ? CesTone.positive : CesTone.warning,
    caption: caption,
    title: switch (health.status) {
      HealthStatus.ok => l10n.healthServerUp,
      HealthStatus.degraded => l10n.healthServerDegraded,
    },
    lines: [
      switch (health.database) {
        HealthDatabase.up => l10n.healthDatabaseUp,
        HealthDatabase.down => l10n.healthDatabaseDown,
      },
    ],
  );
}
