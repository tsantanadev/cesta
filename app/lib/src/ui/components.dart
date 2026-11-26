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
  const CesSheetItem({super.key, required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon),
    title: Text(label),
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
