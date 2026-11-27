import 'dart:async';

import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../api/generated/cesta_api.dart';
import '../ui/components.dart';
import 'list_messages.dart';
import 'lists_controller.dart';

/// The Lists the User deleted within the Restore window, which they can restore.
/// Only the Owner of a List can delete it, so only Owners see anything here.
class RecentlyDeletedScreen extends StatefulWidget {
  const RecentlyDeletedScreen({super.key, required this.lists});

  final ListsController lists;

  @override
  State<RecentlyDeletedScreen> createState() => _RecentlyDeletedScreenState();
}

class _RecentlyDeletedScreenState extends State<RecentlyDeletedScreen> {
  /// Null while loading or when loading failed ([_loadFailure] says why).
  List<DeletedList>? _deleted;
  ListFailure? _loadFailure;

  /// Why the last restore failed, if it did.
  ListFailure? _restoreFailure;
  String? _restoring;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    final (deleted, failure) = await widget.lists.recentlyDeleted();
    if (!mounted) return;
    setState(() {
      _deleted = deleted;
      _loadFailure = failure;
    });
  }

  Future<void> _restore(DeletedList list) async {
    setState(() {
      _restoring = list.id;
      _restoreFailure = null;
    });
    final failure = await widget.lists.restore(list.id);
    if (!mounted) return;
    setState(() {
      _restoring = null;
      if (failure == null || failure == ListFailure.notRestorable) {
        _deleted = _deleted?.where((l) => l.id != list.id).toList();
      }
      _restoreFailure = failure;
    });
    if (failure == null) {
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
          CesText(l10n.listsRecentlyDeletedExplanation(restoreWindow.inDays)),
          const CesGap.lg(),
          if (_restoreFailure case final failure?) ...[
            CesMessage(tone: CesMessageTone.error, text: listFailureMessage(l10n, failure)),
            const CesGap.md(),
          ],
          if (deleted == null && _loadFailure == null)
            CesProgress(label: l10n.loading)
          else if (deleted == null)
            CesMessage(tone: CesMessageTone.error, text: listFailureMessage(l10n, _loadFailure!))
          else if (deleted.isEmpty)
            CesText(l10n.listsRecentlyDeletedEmpty(restoreWindow.inDays))
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
