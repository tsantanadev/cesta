import 'dart:async';

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../session/session_controller.dart';
import '../ui/components.dart';

/// Home: the User's Lists (none yet; Lists arrive in a later slice) and the
/// User menu.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.session});

  final SessionController session;

  void _openUserMenu(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = session.user;
    unawaited(
      showCesSheet(
        context,
        children: [
          if (user != null) CesSheetHeader(title: user.displayName, subtitle: user.email),
          CesSheetItem(
            icon: CesIcons.edit,
            label: l10n.userMenuChangeDisplayName,
            onTap: () => unawaited(context.push('/me/name')),
          ),
          CesSheetItem(
            icon: CesIcons.server,
            label: l10n.userMenuServerStatus,
            onTap: () => unawaited(context.push('/server-status')),
          ),
          CesSheetItem(icon: CesIcons.signOut, label: l10n.userMenuSignOut, onTap: () => unawaited(session.signOut())),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CesScaffold(
      title: l10n.homeTitle,
      actions: [CesIconButton(icon: CesIcons.user, tooltip: l10n.userMenu, onPressed: () => _openUserMenu(context))],
      body: CesEmptyState(icon: CesIcons.basket, title: l10n.homeEmptyTitle, body: l10n.homeEmptyBody),
    );
  }
}
