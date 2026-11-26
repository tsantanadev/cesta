import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../api/generated/cesta_api.dart';
import '../ui/components.dart';
import 'lists_controller.dart';
import 'lists_screen.dart';

/// The Lists the User deleted in the last 30 days, which they can restore.
/// Only the Owner of a List can delete it, so only Owners see anything here.
class RecentlyDeletedScreen extends StatefulWidget {
  const RecentlyDeletedScreen({super.key, required this.lists});

  final ListsController lists;

  @override
  State<RecentlyDeletedScreen> createState() => _RecentlyDeletedScreenState();
}

class _RecentlyDeletedScreenState extends State<RecentlyDeletedScreen> {
  /// Null while loading or when loading failed ([_loadOutcome] says why).
  List<DeletedList>? _deleted;
  ListOutcome? _loadOutcome;

  /// Why the last restore failed, if it did.
  ListOutcome? _restoreOutcome;
  String? _restoring;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final (deleted, outcome) = await widget.lists.recentlyDeleted();
    if (!mounted) return;
    setState(() {
      _deleted = deleted;
      _loadOutcome = outcome;
    });
  }

  Future<void> _restore(DeletedList list) async {
    setState(() {
      _restoring = list.id;
      _restoreOutcome = null;
    });
    final outcome = await widget.lists.restore(list.id);
    if (!mounted) return;
    setState(() {
      _restoring = null;
      if (outcome == ListOutcome.done || outcome == ListOutcome.expired) {
        _deleted = _deleted?.where((l) => l.id != list.id).toList();
      }
      if (outcome != ListOutcome.done) _restoreOutcome = outcome;
    });
    if (outcome == ListOutcome.done) {
      showCesToast(context, message: AppLocalizations.of(context).listsRestored(list.name));
    }
  }

  static int _daysLeft(DeletedList list) {
    final left = list.purgeAt.difference(DateTime.now().toUtc());
    return left.isNegative ? 0 : (left.inMinutes / Duration.minutesPerDay).ceil();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final deleted = _deleted;
    return CesScaffold(
      title: l10n.listsRecentlyDeleted,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CesText(l10n.listsRecentlyDeletedExplanation),
          const CesGap.lg(),
          if (_restoreOutcome case final outcome?) ...[
            CesMessage(tone: CesMessageTone.error, text: listOutcomeMessage(l10n, outcome)),
            const CesGap.md(),
          ],
          if (deleted == null && _loadOutcome == null)
            CesProgress(label: l10n.loading)
          else if (deleted == null)
            CesMessage(tone: CesMessageTone.error, text: listOutcomeMessage(l10n, _loadOutcome!))
          else if (deleted.isEmpty)
            CesText(l10n.listsRecentlyDeletedEmpty)
          else
            for (final list in deleted) ...[
              CesListCard(
                key: ValueKey(list.id),
                name: list.name,
                subtitle: l10n.listsDaysLeft(_daysLeft(list)),
                trailing: [
                  CesButton.secondary(
                    label: l10n.listsRestore,
                    icon: CesIcons.restore,
                    busy: _restoring == list.id,
                    onPressed: _restoring == null ? () => unawaited(_restore(list)) : null,
                  ),
                ],
              ),
              const CesGap.sm(),
            ],
        ],
      ),
    );
  }
}
