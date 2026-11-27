import 'package:material_ui/material_ui.dart';

import 'icons.dart';
import 'tokens.dart';

/// Shared Cesta bottom-sheet chrome (Figma 32:1492, 32:1390, 32:1138):
/// 40×4 Checked grabber, title header with round Alface close button, and
/// keyboard-safe bottom padding.
class _CesSheet extends StatelessWidget {
  const _CesSheet({required this.sectionGap, required this.child, this.title, this.subtitle, this.closeTooltip});

  final double sectionGap;
  final String? title;
  final String? subtitle;
  final String? closeTooltip;
  final Widget child;

  static const _horizontalPadding = 20.0;
  static const _topPadding = 10.0;
  static const _bottomPadding = 34.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tooltip = closeTooltip ?? MaterialLocalizations.of(context).closeButtonTooltip;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.only(bottom: _bottomPadding),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(_horizontalPadding, _topPadding, _horizontalPadding, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: scheme.outlineVariant, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              SizedBox(height: sectionGap),
              if (title != null || subtitle != null) ...[
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (title case final title?)
                            Text(
                              title,
                              style: TextStyle(
                                fontFamily: CestaFonts.family,
                                fontWeight: FontWeight.w700,
                                fontSize: 17,
                                color: scheme.onSurface,
                              ),
                            ),
                          if (subtitle case final subtitle?)
                            Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: scheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    SizedBox(width: context.spacing.sm),
                    _SheetCloseButton(tooltip: tooltip),
                  ],
                ),
                SizedBox(height: sectionGap),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows a menu of [items] about [title] (Figma "10 List options" 32:1492):
/// a bottom sheet with grabber, header + close button, and Alface action rows.
Future<void> showCesSheet(
  BuildContext context, {
  String? title,
  String? subtitle,
  String? closeTooltip,
  required List<CesSheetItem> items,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (context) => _CesSheet(
    title: title,
    subtitle: subtitle,
    closeTooltip: closeTooltip,
    sectionGap: 20,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, item) in items.indexed) ...[if (i > 0) SizedBox(height: context.spacing.sm), item],
      ],
    ),
  ),
);

/// One action row in a [showCesSheet] menu (Figma 32:1530 / 32:1534): 56 dp
/// tall, 16 dp radius, Alface fill, 24 dp icon and 16 dp SemiBold label.
/// Tapping it closes the menu, then runs [onTap].
class CesSheetItem extends StatelessWidget {
  const CesSheetItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// Shown in the destructive colour (Beterraba), e.g. "Delete list".
  final bool destructive;

  void _tap(BuildContext context) {
    Navigator.of(context).pop();
    onTap();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final foreground = destructive ? scheme.error : scheme.onSurface;
    return Material(
      color: scheme.surface,
      borderRadius: BorderRadius.circular(CestaRadii.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _tap(context),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                Icon(icon, size: 24, color: foreground),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: CestaFonts.family,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: foreground,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows a short message at the bottom of the screen (the design's Toast),
/// with an optional action such as "Undo".
void showCesToast(BuildContext context, {required String message, String? actionLabel, VoidCallback? onAction}) =>
    showCesToastOn(ScaffoldMessenger.of(context), message: message, actionLabel: actionLabel, onAction: onAction);

/// [showCesToast] through a given [messenger], e.g. the app's, for messages
/// that don't belong to one screen.
void showCesToastOn(
  ScaffoldMessengerState messenger, {
  required String message,
  String? actionLabel,
  VoidCallback? onAction,
}) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        persist: false,
        duration: const Duration(seconds: 6),
        action: actionLabel == null ? null : SnackBarAction(label: actionLabel, onPressed: onAction ?? () {}),
      ),
    );
}

/// Shows a sheet with a [title], a close button and [child] (usually a
/// form), kept above the keyboard (Figma "11 Rename list" 32:1390 & "New list"
/// 32:1138).
Future<void> showCesFormSheet(
  BuildContext context, {
  required String title,
  required String closeTooltip,
  required Widget child,
  double? sectionGap,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (context) =>
      _CesSheet(title: title, closeTooltip: closeTooltip, sectionGap: sectionGap ?? context.spacing.lg, child: child),
);

/// The round close button of a sheet (Figma 9:440, 32:1496, 32:1394): 36 dp,
/// Alface ground.
class _SheetCloseButton extends StatelessWidget {
  const _SheetCloseButton({required this.tooltip});

  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      tooltip: tooltip,
      onPressed: () => Navigator.of(context).pop(),
      icon: const Icon(CesIcons.close, size: 16),
      style: IconButton.styleFrom(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        fixedSize: const Size(36, 36),
        minimumSize: const Size(36, 36),
      ),
    );
  }
}
