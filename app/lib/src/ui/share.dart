import 'package:material_ui/material_ui.dart';

import 'tokens.dart';

/// The white card of Share list (Figma "Share card" 4:373): a centred
/// [title] in Bricolage, a muted [body] under it, then [actions], 16 dp apart.
class CesShareCard extends StatelessWidget {
  const CesShareCard({super.key, required this.title, required this.body, required this.actions});

  final String title;
  final String body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(color: scheme.surfaceContainerLowest, borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: CestaDisplayType.listName.copyWith(color: scheme.onSurface),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: CestaFonts.family,
                fontSize: 15,
                height: 1.5,
                color: scheme.onSurfaceVariant,
              ),
            ),
            for (final action in actions) ...[const SizedBox(height: 16), action],
          ],
        ),
      ),
    );
  }
}

/// A row under Share list's card (Figma "Member" 4:553): a 36 dp round
/// badge, the [label] with an optional muted [detail] under it, then a
/// [trailing] widget.
class CesPersonRow extends StatelessWidget {
  const CesPersonRow({super.key, required this.icon, required this.label, this.detail, this.trailing});

  final IconData icon;
  final String label;
  final String? detail;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 10, 4, 10),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: scheme.surfaceContainerLowest, shape: BoxShape.circle),
            child: Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: CestaFonts.family,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: scheme.onSurface,
                  ),
                ),
                if (detail case final detail?)
                  Text(
                    detail,
                    style: TextStyle(fontFamily: CestaFonts.family, fontSize: 13, color: scheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

/// An Invitation addressed to the User, on the Lists screen (provisional
/// until its frame is designed, #44): a card like a List's, outlined in
/// Banana, with the List's [name], who invited them ([subtitle]) and the
/// [actions] to join or decline, side by side.
class CesInvitationCard extends StatelessWidget {
  const CesInvitationCard({super.key, required this.name, required this.subtitle, required this.actions});

  final String name;
  final String subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(CestaRadii.listCard),
        border: Border.all(color: context.palette.toBuy, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 18, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(name, style: CestaDisplayType.listName.copyWith(color: scheme.onSurface)),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500, color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                for (final (i, action) in actions.indexed) ...[
                  if (i > 0) const SizedBox(width: 8),
                  Expanded(child: action),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
