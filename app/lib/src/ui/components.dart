/// In-house UI components. Feature screens build with these instead of
/// styling raw Material or Cupertino widgets, so the Cesta look (and the
/// iOS-adaptive behaviour) lives in one place.
library;

import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoButton;
import 'package:material_ui/material_ui.dart';

import 'icons.dart';
import 'tokens.dart';

export 'icons.dart';

bool _isCupertino(BuildContext context) => switch (Theme.of(context).platform) {
  TargetPlatform.iOS || TargetPlatform.macOS => true,
  _ => false,
};

/// Page scaffold with an adaptive app bar (centred title on iOS). The body
/// scrolls, so it stays usable at large text sizes.
class CesScaffold extends StatelessWidget {
  const CesScaffold({super.key, required this.title, required this.body, this.actions = const []}) : _appBar = true;

  /// A page without an app bar, e.g. the welcome screen.
  const CesScaffold.bare({super.key, required this.body}) : title = '', actions = const [], _appBar = false;

  final String title;
  final Widget body;
  final List<Widget> actions;
  final bool _appBar;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: _appBar ? AppBar(title: Text(title), centerTitle: _isCupertino(context), actions: actions) : null,
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: EdgeInsets.all(context.spacing.lg),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight - 2 * context.spacing.lg),
            child: Center(
              child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: body),
            ),
          ),
        ),
      ),
    ),
  );
}

enum _ButtonKind { primary, secondary }

/// An action button. The primary kind is a filled Material button, or a
/// filled Cupertino button on iOS; the secondary kind is outlined. While
/// [busy] it shows a spinner and ignores taps.
class CesButton extends StatelessWidget {
  const CesButton({super.key, required this.label, required this.onPressed, this.icon, this.busy = false})
    : _kind = _ButtonKind.primary;

  const CesButton.secondary({super.key, required this.label, required this.onPressed, this.icon, this.busy = false})
    : _kind = _ButtonKind.secondary;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;
  final _ButtonKind _kind;

  @override
  Widget build(BuildContext context) {
    final onPressed = busy ? null : this.onPressed;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (busy)
          const SizedBox.square(dimension: 20, child: CircularProgressIndicator.adaptive(strokeWidth: 2))
        else if (icon case final icon?)
          Icon(icon, size: 20),
        if (busy || icon != null) SizedBox(width: context.spacing.sm),
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ],
    );
    return switch (_kind) {
      _ButtonKind.primary when _isCupertino(context) => CupertinoButton.filled(
        onPressed: onPressed,
        borderRadius: BorderRadius.circular(CestaRadii.button),
        child: content,
      ),
      _ButtonKind.primary => FilledButton(onPressed: onPressed, child: content),
      _ButtonKind.secondary => OutlinedButton(onPressed: onPressed, child: content),
    };
  }
}

/// A low-emphasis, link-like action.
class CesLink extends StatelessWidget {
  const CesLink({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => TextButton(
    onPressed: onPressed,
    child: Text(label, textAlign: TextAlign.center),
  );
}

/// An icon-only action with a tooltip (which is also its accessible label).
class CesIconButton extends StatelessWidget {
  const CesIconButton({super.key, required this.icon, required this.tooltip, required this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => IconButton(icon: Icon(icon), tooltip: tooltip, onPressed: onPressed);
}

/// A labelled text field for use inside a [Form].
class CesTextField extends StatelessWidget {
  const CesTextField({
    super.key,
    required this.label,
    required this.controller,
    this.validator,
    this.keyboardType,
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
    this.helper,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final String? helper;
  final bool autofocus;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    validator: validator,
    keyboardType: keyboardType,
    autofillHints: autofillHints,
    textInputAction: textInputAction,
    onFieldSubmitted: onSubmitted,
    autofocus: autofocus,
    textCapitalization: textCapitalization,
    autocorrect: false,
    decoration: InputDecoration(labelText: label, helperText: helper),
  );
}

/// A password field with a show/hide toggle.
class CesPasswordField extends StatefulWidget {
  const CesPasswordField({
    super.key,
    required this.label,
    required this.showLabel,
    required this.hideLabel,
    required this.controller,
    this.validator,
    this.newPassword = false,
    this.helper,
    this.onSubmitted,
  });

  final String label;
  final String showLabel;
  final String hideLabel;
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;

  /// True on sign-up, so password managers offer to generate one.
  final bool newPassword;
  final String? helper;
  final ValueChanged<String>? onSubmitted;

  @override
  State<CesPasswordField> createState() => _CesPasswordFieldState();
}

class _CesPasswordFieldState extends State<CesPasswordField> {
  bool _obscured = true;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: widget.controller,
    validator: widget.validator,
    obscureText: _obscured,
    enableSuggestions: false,
    autocorrect: false,
    keyboardType: TextInputType.visiblePassword,
    textInputAction: TextInputAction.done,
    onFieldSubmitted: widget.onSubmitted,
    autofillHints: [widget.newPassword ? AutofillHints.newPassword : AutofillHints.password],
    decoration: InputDecoration(
      labelText: widget.label,
      helperText: widget.helper,
      suffixIcon: CesIconButton(
        icon: _obscured ? CesIcons.show : CesIcons.hide,
        tooltip: _obscured ? widget.showLabel : widget.hideLabel,
        onPressed: () => setState(() => _obscured = !_obscured),
      ),
    ),
  );
}

enum CesMessageTone { error, info }

/// An inline message about the last action, e.g. why sign-in failed.
class CesMessage extends StatelessWidget {
  const CesMessage({super.key, required this.tone, required this.text});

  final CesMessageTone tone;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (background, foreground, icon) = switch (tone) {
      CesMessageTone.error => (scheme.errorContainer, scheme.onErrorContainer, CesIcons.error),
      CesMessageTone.info => (scheme.secondaryContainer, scheme.onSecondaryContainer, CesIcons.info),
    };
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(CestaRadii.field)),
        child: Padding(
          padding: EdgeInsets.all(context.spacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: foreground, size: 22),
              SizedBox(width: context.spacing.sm),
              Expanded(
                child: Text(text, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: foreground)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _TextKind { body, lead }

/// Running text on a screen. [CesText.lead] is the larger, muted line under a
/// brand or heading, e.g. the welcome tagline.
class CesText extends StatelessWidget {
  const CesText(this.text, {super.key, this.textAlign}) : _kind = _TextKind.body;
  const CesText.lead(this.text, {super.key, this.textAlign}) : _kind = _TextKind.lead;

  final String text;
  final TextAlign? textAlign;
  final _TextKind _kind;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = switch (_kind) {
      _TextKind.body => theme.textTheme.bodyLarge,
      _TextKind.lead => theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
    };
    return Text(text, style: style, textAlign: textAlign);
  }
}

/// Screen heading with an optional supporting line.
class CesHeading extends StatelessWidget {
  const CesHeading({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.headlineMedium),
        if (subtitle case final subtitle?) ...[
          SizedBox(height: context.spacing.sm),
          Text(subtitle, style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ],
      ],
    );
  }
}

/// The Cesta mark: a basket in a soft green disc, with the name below.
class CesBrandMark extends StatelessWidget {
  const CesBrandMark({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(color: theme.colorScheme.primaryContainer, shape: BoxShape.circle),
          child: Padding(
            padding: EdgeInsets.all(context.spacing.lg),
            child: Icon(CesIcons.basket, size: 64, color: theme.colorScheme.onPrimaryContainer),
          ),
        ),
        SizedBox(height: context.spacing.md),
        Text(name, style: theme.textTheme.displaySmall?.copyWith(color: theme.colorScheme.primary)),
      ],
    );
  }
}

/// What a screen shows when it has nothing to list yet.
class CesEmptyState extends StatelessWidget {
  const CesEmptyState({super.key, required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 72, color: theme.colorScheme.primary),
        SizedBox(height: context.spacing.md),
        Text(title, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
        SizedBox(height: context.spacing.sm),
        Text(
          body,
          style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Shows a bottom sheet of [children] (usually a [CesSheetHeader] and [CesSheetItem]s).
Future<void> showCesSheet(BuildContext context, {required List<Widget> children}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (context) => SafeArea(
    child: SingleChildScrollView(
      padding: EdgeInsets.only(bottom: context.spacing.md),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    ),
  ),
);

/// Who or what a bottom sheet is about, e.g. the signed-in User.
class CesSheetHeader extends StatelessWidget {
  const CesSheetHeader({super.key, required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(context.spacing.lg, 0, context.spacing.lg, context.spacing.md),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleLarge),
            if (subtitle case final subtitle?)
              Text(subtitle, style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

/// One action in a bottom sheet. Tapping it closes the sheet, then runs [onTap].
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

  /// Shown in the destructive colour, e.g. "Delete list".
  final bool destructive;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon),
    title: Text(label),
    iconColor: destructive ? Theme.of(context).colorScheme.error : null,
    textColor: destructive ? Theme.of(context).colorScheme.error : null,
    onTap: () {
      Navigator.of(context).pop();
      onTap();
    },
    contentPadding: EdgeInsets.symmetric(horizontal: context.spacing.lg),
  );
}

/// Indeterminate progress with a label; platform-adaptive spinner.
class CesProgress extends StatelessWidget {
  const CesProgress({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const CircularProgressIndicator.adaptive(),
      SizedBox(width: context.spacing.md),
      Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
    ],
  );
}

enum CesTone { positive, warning, neutral }

/// A card that reports a status: icon, title and supporting lines.
class CesStatusCard extends StatelessWidget {
  const CesStatusCard({super.key, required this.tone, required this.title, this.lines = const [], this.caption});

  final CesTone tone;
  final String title;
  final List<String> lines;

  /// Small heading above the title, e.g. "Last known status".
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = context.spacing;
    final (icon, colour) = switch (tone) {
      CesTone.positive => (CesIcons.positive, context.statusColors.success),
      CesTone.warning => (CesIcons.warning, context.statusColors.warning),
      CesTone.neutral => (CesIcons.offline, theme.colorScheme.onSurfaceVariant),
    };
    return Card(
      child: Padding(
        padding: EdgeInsets.all(spacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colour, size: 32),
            SizedBox(width: spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (caption != null)
                    Text(
                      caption!,
                      style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  Text(title, style: theme.textTheme.titleMedium),
                  for (final line in lines) ...[
                    SizedBox(height: spacing.xs),
                    Text(line, style: theme.textTheme.bodyMedium),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The home page layout from the design: the wordmark and [actions] on top,
/// a big [title], then [items] as a column of cards, or [empty] when there
/// are none. [floatingAction] floats bottom-right, e.g. a [CesFab].
class CesHomeScaffold extends StatelessWidget {
  const CesHomeScaffold({
    super.key,
    required this.brand,
    required this.title,
    required this.items,
    required this.empty,
    this.actions = const [],
    this.floatingAction,
  });

  /// The app's name, shown as the wordmark.
  final String brand;
  final String title;
  final List<Widget> items;
  final Widget empty;
  final List<Widget> actions;
  final Widget? floatingAction;

  // Gaps from the design that sit off the 4 dp scale.
  static const _gutter = 20.0;
  static const _cardGap = 10.0;
  static const _fabClearance = 96.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = context.spacing;
    return Scaffold(
      floatingActionButton: floatingAction,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(_gutter, spacing.sm, spacing.sm, 0),
                  sliver: SliverToBoxAdapter(
                    child: Row(
                      children: [
                        Expanded(child: _Wordmark(name: brand)),
                        ...actions,
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(_gutter, spacing.lg, _gutter, _gutter),
                  sliver: SliverToBoxAdapter(
                    child: Semantics(
                      header: true,
                      child: Text(
                        title,
                        style: CestaDisplayType.screenTitle.copyWith(color: theme.colorScheme.onSurface),
                      ),
                    ),
                  ),
                ),
                if (items.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(spacing.lg, 0, spacing.lg, _fabClearance),
                      child: Center(child: empty),
                    ),
                  )
                else
                  SliverPadding(
                    padding: EdgeInsets.fromLTRB(spacing.md, 0, spacing.md, _fabClearance),
                    sliver: SliverList.separated(
                      itemCount: items.length,
                      itemBuilder: (_, i) => items[i],
                      separatorBuilder: (_, _) => const SizedBox(height: _cardGap),
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

/// The Cesta wordmark: the basket and the name in Bricolage.
class _Wordmark extends StatelessWidget {
  const _Wordmark({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final colour = Theme.of(context).colorScheme.primary;
    return Row(
      children: [
        Icon(CesIcons.basket, size: 22, color: colour),
        const SizedBox(width: 6),
        Flexible(
          child: Text(name.toLowerCase(), style: CestaDisplayType.wordmark.copyWith(color: colour)),
        ),
      ],
    );
  }
}

/// A round avatar with [initials] that acts as a button, e.g. the account menu.
class CesAvatarButton extends StatelessWidget {
  const CesAvatarButton({super.key, required this.initials, required this.tooltip, required this.onPressed});

  final String initials;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.toBuy,
          shape: BoxShape.circle,
          border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerLowest, width: 2),
        ),
        child: Text(
          initials,
          textScaler: TextScaler.noScaling,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: palette.onToBuy),
        ),
      ),
    );
  }
}

/// A card for one List: its [name], a [subtitle] and [trailing] widgets
/// (e.g. a [CesCountSign] and an options button).
class CesListCard extends StatelessWidget {
  const CesListCard({super.key, required this.name, required this.subtitle, this.trailing = const []});

  final String name;
  final String subtitle;
  final List<Widget> trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(CestaShapes.listCard),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 18, trailing.isEmpty ? context.spacing.md : context.spacing.xs, 18),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: CestaDisplayType.listName.copyWith(color: theme.colorScheme.onSurface)),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            for (final w in trailing) ...[SizedBox(width: context.spacing.sm), w],
          ],
        ),
      ),
    );
  }
}

/// The sign on a List's card: how many Items are still to buy, on Banana,
/// like a price tag; with nothing to buy, a check on the "bought" colour.
class CesCountSign extends StatelessWidget {
  const CesCountSign({super.key, required this.count, required this.caption, required this.nothingLabel});

  final int count;

  /// Under the number, e.g. "to buy".
  final String caption;

  /// Accessible label when [count] is 0.
  final String nothingLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final empty = count == 0;
    final foreground = empty ? palette.onBought : palette.onToBuy;
    return Semantics(
      label: empty ? nothingLabel : '$count $caption',
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minWidth: 60, minHeight: 64),
        padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
        decoration: BoxDecoration(
          color: empty ? palette.bought : palette.toBuy,
          borderRadius: BorderRadius.circular(CestaShapes.sign),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // The nail hole the sign hangs from.
            Positioned(
              top: -9,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, shape: BoxShape.circle),
              ),
            ),
            if (empty)
              Icon(CesIcons.check, size: 24, color: foreground)
            else
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$count', style: CestaDisplayType.count.copyWith(color: foreground)),
                  Text(
                    caption,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 10, color: foreground),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// The page's main action as a pill floating bottom-right, e.g. "New list".
class CesFab extends StatelessWidget {
  const CesFab({super.key, required this.label, required this.icon, required this.onPressed});

  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FloatingActionButton.extended(
      onPressed: onPressed,
      backgroundColor: scheme.primary,
      foregroundColor: scheme.onPrimary,
      shape: const StadiumBorder(),
      extendedPadding: EdgeInsets.symmetric(horizontal: context.spacing.lg),
      icon: Icon(icon, size: 20),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
    );
  }
}

/// Shows a short message at the bottom of the screen (the design's Toast),
/// with an optional action such as "Undo".
void showCesToast(BuildContext context, {required String message, String? actionLabel, VoidCallback? onAction}) {
  ScaffoldMessenger.of(context)
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

/// Shows a bottom sheet with a [title], a close button and [child] (usually
/// a form), kept above the keyboard.
Future<void> showCesFormSheet(
  BuildContext context, {
  required String title,
  required String closeTooltip,
  required Widget child,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(context.spacing.lg, 0, context.spacing.lg, context.spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, fontSize: 17),
                  ),
                ),
                _SheetCloseButton(tooltip: closeTooltip),
              ],
            ),
            SizedBox(height: context.spacing.md),
            child,
          ],
        ),
      ),
    ),
  ),
);

/// Vertical gap from the spacing scale.
class CesGap extends StatelessWidget {
  const CesGap.sm({super.key}) : _size = _GapSize.sm;
  const CesGap.md({super.key}) : _size = _GapSize.md;
  const CesGap.lg({super.key}) : _size = _GapSize.lg;
  const CesGap.xl({super.key}) : _size = _GapSize.xl;

  final _GapSize _size;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: switch (_size) {
      _GapSize.sm => context.spacing.sm,
      _GapSize.md => context.spacing.md,
      _GapSize.lg => context.spacing.lg,
      _GapSize.xl => context.spacing.xl,
    },
  );
}

enum _GapSize { sm, md, lg, xl }

/// The round close button of a form sheet (Figma 9:440): 36 dp, Alface ground.
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
