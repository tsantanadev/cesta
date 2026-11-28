import 'package:material_ui/material_ui.dart';

import 'icons.dart';
import 'tokens.dart';

/// A round 44 dp Branco button with a 20 dp icon in a screen's top bar, e.g.
/// Share on a List (Figma "Share" 4:163). [tooltip] is also its accessible label.
class CesTopBarButton extends StatelessWidget {
  const CesTopBarButton({super.key, required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 20, color: scheme.onSurface),
      style: IconButton.styleFrom(
        backgroundColor: scheme.surfaceContainerLowest,
        fixedSize: const Size(44, 44),
        minimumSize: const Size(44, 44),
      ),
    );
  }
}

/// The top bar of a screen opened over another (Figma "06 Share list" 4:368):
/// a 44 dp close button with a 22 dp cross, then the [title].
class CesCloseBar extends StatelessWidget {
  const CesCloseBar({super.key, required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: onClose,
            icon: Icon(CesIcons.close, size: 22, color: scheme.onSurface),
            style: IconButton.styleFrom(fixedSize: const Size(44, 44), minimumSize: const Size(44, 44)),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: CestaFonts.family,
                  fontWeight: FontWeight.w700,
                  fontSize: 17,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
/// badge, the [label], then a [trailing] widget.
class CesPersonRow extends StatelessWidget {
  const CesPersonRow({super.key, required this.icon, required this.label, this.trailing});

  final IconData icon;
  final String label;
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
            child: Text(
              label,
              style: TextStyle(
                fontFamily: CestaFonts.family,
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: scheme.onSurface,
              ),
            ),
          ),
          ?trailing,
        ],
      ),
    );
  }
}
