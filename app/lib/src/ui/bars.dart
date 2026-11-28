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
