/// In-house UI components. Feature screens build with these instead of
/// styling raw Material or Cupertino widgets, so the Cesta look (and the
/// iOS-adaptive behaviour) lives in one place.
library;

import 'dart:math' as math;

import 'package:cupertino_ui/cupertino_ui.dart'
    show CupertinoActionSheet, CupertinoActionSheetAction, CupertinoButton, CupertinoTextField, showCupertinoModalPopup;
import 'package:flutter/services.dart' show SystemUiOverlayStyle;
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

/// A form page in the design's layout (Figma "02 Your name"): [top] from the
/// top, [bottom] (the form's actions) at the bottom of the screen, with an
/// app bar only when there is a [title].
class CesFormScaffold extends StatelessWidget {
  const CesFormScaffold({super.key, this.title, required this.top, required this.bottom});

  final String? title;
  final List<Widget> top;
  final List<Widget> bottom;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: title == null ? null : AppBar(title: Text(title!), centerTitle: _isCupertino(context)),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: CesPinnedLayout(padding: const EdgeInsets.fromLTRB(24, 8, 24, 34), top: top, bottom: bottom),
        ),
      ),
    ),
  );
}

enum _ButtonKind { primary, secondary, outline }

/// An action button: a 56 dp pill (Figma Button 3:61). [CesButton] is filled
/// with Folha; [CesButton.secondary] is filled with Branco; [CesButton.outline]
/// is see-through with a 1.5 dp stroke, in on-brand colours on a
/// [CesBrandScaffold]. It is a Cupertino button on iOS and a Material one
/// elsewhere. While [busy] it shows a spinner and ignores taps.
class CesButton extends StatelessWidget {
  const CesButton({super.key, required this.label, required this.onPressed, this.icon, this.busy = false})
    : _kind = _ButtonKind.primary;

  const CesButton.secondary({super.key, required this.label, required this.onPressed, this.icon, this.busy = false})
    : _kind = _ButtonKind.secondary;

  const CesButton.outline({super.key, required this.label, required this.onPressed, this.icon, this.busy = false})
    : _kind = _ButtonKind.outline;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool busy;
  final _ButtonKind _kind;

  static const _height = 56.0;
  static const _iconGap = 10.0;
  static const _label = TextStyle(fontFamily: CestaFonts.family, fontWeight: FontWeight.w700, fontSize: 16);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final onBrand = CesBrandScaffold.contains(context);
    final palette = context.palette;
    final (Color background, Color foreground, Color? stroke) = switch (_kind) {
      _ButtonKind.primary => (scheme.primary, scheme.onPrimary, null),
      _ButtonKind.secondary => (scheme.surfaceContainerLowest, scheme.onSurface, null),
      _ButtonKind.outline when onBrand => (Colors.transparent, palette.onBrand, palette.onBrand),
      _ButtonKind.outline => (Colors.transparent, scheme.onSurface, scheme.outlineVariant),
    };
    final onPressed = busy ? null : this.onPressed;
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (busy)
          SizedBox.square(
            dimension: 20,
            child: CircularProgressIndicator.adaptive(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(foreground)),
          )
        else if (icon case final icon?)
          Icon(icon, size: 20, color: foreground),
        if (busy || icon != null) const SizedBox(width: _iconGap),
        Flexible(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: _label.copyWith(color: foreground),
          ),
        ),
      ],
    );
    final shape = StadiumBorder(side: stroke == null ? BorderSide.none : BorderSide(color: stroke, width: 1.5));
    if (_isCupertino(context)) {
      return DecoratedBox(
        decoration: ShapeDecoration(shape: shape),
        child: CupertinoButton(
          onPressed: onPressed,
          color: background,
          disabledColor: background.withValues(alpha: background.a * 0.5),
          foregroundColor: foreground,
          minimumSize: const Size(_height, _height),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          borderRadius: BorderRadius.circular(CestaRadii.button),
          child: content,
        ),
      );
    }
    final style = ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.disabled) ? background.withValues(alpha: background.a * 0.5) : background,
      ),
      foregroundColor: WidgetStatePropertyAll(foreground),
      overlayColor: WidgetStatePropertyAll(foreground.withValues(alpha: 0.08)),
      minimumSize: const WidgetStatePropertyAll(Size(_height, _height)),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 24)),
      shape: WidgetStatePropertyAll(shape),
      side: WidgetStatePropertyAll(shape.side),
    );
    return switch (_kind) {
      _ButtonKind.outline => OutlinedButton(onPressed: onPressed, style: style, child: content),
      _ => FilledButton(onPressed: onPressed, style: style, child: content),
    };
  }
}

/// A low-emphasis, link-like action, e.g. "Sign out" under a form (Figma:
/// Plus Jakarta Sans Bold 15 in Folha, 44 dp tall).
class CesLink extends StatelessWidget {
  const CesLink({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final text = Text(label, textAlign: TextAlign.center);
    if (!_isCupertino(context)) return TextButton(onPressed: onPressed, child: text);
    return CupertinoButton(
      onPressed: onPressed,
      minimumSize: const Size(44, 44),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      foregroundColor: Theme.of(context).colorScheme.primary,
      child: DefaultTextStyle.merge(
        style: const TextStyle(fontFamily: CestaFonts.family, fontWeight: FontWeight.w700, fontSize: 15),
        child: text,
      ),
    );
  }
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

/// A text field for use inside a [Form], with its [label] above it (Figma
/// "Name field" 20:627). [CesTextField.display] shows the value large, in
/// Bricolage, on a Folha underline, for a form's one important field such as
/// the display name. On iOS the input is a Cupertino text field.
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
  }) : _display = false;

  const CesTextField.display({
    super.key,
    required this.label,
    required this.controller,
    this.validator,
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
  }) : _display = true,
       keyboardType = null,
       helper = null;

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
  final bool _display;

  @override
  Widget build(BuildContext context) => _LabelledField(
    label: label,
    child: _FieldInput(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      autofillHints: autofillHints,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      helper: helper,
      autofocus: autofocus,
      textCapitalization: textCapitalization,
      display: _display,
    ),
  );
}

/// A password field with a show/hide toggle; see [CesTextField].
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
  Widget build(BuildContext context) => _LabelledField(
    label: widget.label,
    child: _FieldInput(
      controller: widget.controller,
      validator: widget.validator,
      obscureText: _obscured,
      keyboardType: TextInputType.visiblePassword,
      textInputAction: TextInputAction.done,
      onSubmitted: widget.onSubmitted,
      autofillHints: [widget.newPassword ? AutofillHints.newPassword : AutofillHints.password],
      helper: widget.helper,
      suffix: CesIconButton(
        icon: _obscured ? CesIcons.show : CesIcons.hide,
        tooltip: _obscured ? widget.showLabel : widget.hideLabel,
        onPressed: () => setState(() => _obscured = !_obscured),
      ),
    ),
  );
}

/// A field's label above its input, read out together.
class _LabelledField extends StatelessWidget {
  const _LabelledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MergeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: context.spacing.sm),
          child,
        ],
      ),
    );
  }
}

/// The input of a [CesTextField] or [CesPasswordField]: a Material text field,
/// or on iOS a Cupertino one with the error or [helper] under it.
class _FieldInput extends StatelessWidget {
  const _FieldInput({
    required this.controller,
    this.validator,
    this.keyboardType,
    this.autofillHints,
    this.textInputAction,
    this.onSubmitted,
    this.helper,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.none,
    this.obscureText = false,
    this.suffix,
    this.display = false,
  });

  final TextEditingController controller;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final String? helper;
  final bool autofocus;
  final TextCapitalization textCapitalization;
  final bool obscureText;
  final Widget? suffix;
  final bool display;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final style = display
        ? CestaDisplayType.fieldValue.copyWith(color: scheme.onSurface)
        : theme.textTheme.bodyLarge?.copyWith(color: scheme.onSurface);
    if (!_isCupertino(context)) {
      final underline = UnderlineInputBorder(borderSide: BorderSide(color: scheme.primary, width: 2));
      return TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        autofillHints: autofillHints,
        textInputAction: textInputAction,
        onFieldSubmitted: onSubmitted,
        autofocus: autofocus,
        textCapitalization: textCapitalization,
        obscureText: obscureText,
        enableSuggestions: !obscureText,
        autocorrect: false,
        style: style,
        decoration: display
            ? InputDecoration(
                filled: false,
                isDense: true,
                contentPadding: const EdgeInsets.only(bottom: 8),
                border: underline,
                enabledBorder: underline,
                focusedBorder: underline,
                errorBorder: underline.copyWith(borderSide: BorderSide(color: scheme.error, width: 2)),
                focusedErrorBorder: underline.copyWith(borderSide: BorderSide(color: scheme.error, width: 2)),
              )
            : InputDecoration(helperText: helper, suffixIcon: suffix),
      );
    }
    return FormField<String>(
      initialValue: controller.text,
      validator: validator == null ? null : (_) => validator!(controller.text),
      builder: (field) {
        final border = field.hasError ? scheme.error : (display ? scheme.primary : null);
        final note = field.errorText ?? helper;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CupertinoTextField(
              controller: controller,
              onChanged: field.didChange,
              keyboardType: keyboardType,
              autofillHints: autofillHints,
              textInputAction: textInputAction,
              onSubmitted: onSubmitted,
              autofocus: autofocus,
              textCapitalization: textCapitalization,
              obscureText: obscureText,
              enableSuggestions: !obscureText,
              autocorrect: false,
              style: style,
              cursorColor: scheme.primary,
              suffix: suffix,
              padding: display ? const EdgeInsets.only(bottom: 8) : const EdgeInsets.all(14),
              decoration: display
                  ? BoxDecoration(
                      border: Border(bottom: BorderSide(color: border!, width: 2)),
                    )
                  : BoxDecoration(
                      color: scheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(CestaRadii.field),
                      border: border == null ? null : Border.all(color: border, width: 1.5),
                    ),
            ),
            if (note != null) ...[
              SizedBox(height: context.spacing.xs),
              Text(
                note,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: field.hasError ? scheme.error : scheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
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

enum _TextKind { body, intro }

/// Running text on a screen. [CesText.intro] is the 16 dp line under a
/// [CesDisplayHeading], muted (or on-brand on a [CesBrandScaffold]).
class CesText extends StatelessWidget {
  const CesText(this.text, {super.key, this.textAlign}) : _kind = _TextKind.body;
  const CesText.intro(this.text, {super.key, this.textAlign}) : _kind = _TextKind.intro;

  final String text;
  final TextAlign? textAlign;
  final _TextKind _kind;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onBrand = CesBrandScaffold.contains(context);
    final style = switch (_kind) {
      _TextKind.body => theme.textTheme.bodyLarge,
      _TextKind.intro => theme.textTheme.bodyLarge?.copyWith(
        fontSize: 16,
        height: 1.5,
        letterSpacing: 0,
        fontWeight: onBrand ? FontWeight.w400 : FontWeight.w500,
        color: onBrand ? context.palette.onBrand : theme.colorScheme.onSurfaceVariant,
      ),
    };
    return Text(text, style: style, textAlign: textAlign);
  }
}

/// A screen's big heading in Bricolage: 36 dp, or 40 dp when [large] (the
/// welcome headline). On-brand on a [CesBrandScaffold].
class CesDisplayHeading extends StatelessWidget {
  const CesDisplayHeading(this.text, {super.key, this.large = false});

  final String text;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final colour = CesBrandScaffold.contains(context)
        ? context.palette.onBrand
        : Theme.of(context).colorScheme.onSurface;
    return Semantics(
      header: true,
      child: Text(text, style: (large ? CestaDisplayType.headline : CestaDisplayType.heading).copyWith(color: colour)),
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

/// Shows a menu of [items] about [title] (e.g. the signed-in User, or a
/// List): a bottom sheet, or on iOS an action sheet with a Cancel button.
Future<void> showCesSheet(BuildContext context, {String? title, String? subtitle, required List<CesSheetItem> items}) {
  if (_isCupertino(context)) {
    return showCupertinoModalPopup<void>(
      context: context,
      builder: (context) => CupertinoActionSheet(
        title: title == null ? null : Text(title),
        message: subtitle == null ? null : Text(subtitle),
        actions: items,
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
      ),
    );
  }
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: context.spacing.md),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null) _SheetHeader(title: title, subtitle: subtitle),
            ...items,
          ],
        ),
      ),
    ),
  );
}

/// Who or what a bottom sheet is about, e.g. the signed-in User.
class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.title, this.subtitle});

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

/// One action in a [showCesSheet] menu. Tapping it closes the menu, then runs [onTap].
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

  void _tap(BuildContext context) {
    Navigator.of(context).pop();
    onTap();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCupertino(context)) {
      return CupertinoActionSheetAction(
        isDestructiveAction: destructive,
        onPressed: () => _tap(context),
        child: Text(label),
      );
    }
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      iconColor: destructive ? Theme.of(context).colorScheme.error : null,
      textColor: destructive ? Theme.of(context).colorScheme.error : null,
      onTap: () => _tap(context),
      contentPadding: EdgeInsets.symmetric(horizontal: context.spacing.lg),
    );
  }
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
                        Expanded(
                          child: Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: CesWordmark(name: brand),
                          ),
                        ),
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

/// The Cesta wordmark: the basket and the name in Bricolage. On a
/// [CesBrandScaffold] the basket is Banana and the name on-brand; elsewhere
/// both are Folha. [large] is the welcome screen's size.
class CesWordmark extends StatelessWidget {
  const CesWordmark({super.key, required this.name, this.large = false});

  final String name;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final onBrand = CesBrandScaffold.contains(context);
    final primary = Theme.of(context).colorScheme.primary;
    final iconColour = onBrand ? context.palette.toBuy : primary;
    final textColour = onBrand ? context.palette.onBrand : primary;
    final style = large ? CestaDisplayType.wordmarkLarge : CestaDisplayType.wordmark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(CesIcons.basket, size: large ? 26 : 22, color: iconColour),
        SizedBox(width: large ? 8 : 6),
        Flexible(
          child: Text(name.toLowerCase(), style: style.copyWith(color: textColour)),
        ),
      ],
    );
  }
}

/// A round avatar with [initials] that acts as a button, e.g. the User menu.
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

/// A full-bleed page on the brand surface (Figma "01 Welcome"): no app bar,
/// light status bar icons, and components inside it ([CesButton.outline],
/// [CesWordmark]) switch to their on-brand colours.
class CesBrandScaffold extends StatelessWidget {
  const CesBrandScaffold({super.key, required this.body});

  final Widget body;

  /// Whether [context] is inside a [CesBrandScaffold].
  static bool contains(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_OnBrand>() != null;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: Scaffold(
      backgroundColor: context.palette.brandSurface,
      body: _OnBrand(
        child: DefaultTextStyle.merge(
          style: TextStyle(color: context.palette.onBrand),
          child: SafeArea(child: body),
        ),
      ),
    ),
  );
}

class _OnBrand extends InheritedWidget {
  const _OnBrand({required super.child});

  @override
  bool updateShouldNotify(_OnBrand oldWidget) => false;
}

/// A page whose [top] content starts at the top and whose [bottom] actions sit
/// at the bottom of the screen, as in the design's forms. When the content is
/// taller than the screen (e.g. at large text sizes) the whole page scrolls.
class CesPinnedLayout extends StatelessWidget {
  const CesPinnedLayout({super.key, required this.top, required this.bottom, this.padding = EdgeInsets.zero});

  final List<Widget> top;
  final List<Widget> bottom;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: IntrinsicHeight(
          child: Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [...top, const Spacer(), ...bottom],
            ),
          ),
        ),
      ),
    ),
  );
}

/// An Item as a Banana price tag (Figma "Item tile" 3:46): an [icon] and an
/// optional [quantity] on top, the [name] at the bottom, and the hole the tag
/// hangs from. It is drawn at a fixed size, so it doesn't grow with the text size.
class CesItemTile extends StatelessWidget {
  const CesItemTile({super.key, required this.name, required this.icon, this.quantity, this.size = 112});

  final String name;
  final IconData icon;
  final String? quantity;
  final double size;

  /// Where the hanging string meets the tile, from its top-left corner.
  static const holeCentre = Offset(56, 10);

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final ink = palette.onToBuy;
    return MediaQuery.withNoTextScaling(
      child: Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: palette.toBuy, borderRadius: BorderRadius.circular(CestaShapes.sign)),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, size: 30, color: ink),
                    if (quantity case final quantity?)
                      Flexible(
                        child: Text(
                          quantity,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: CestaFonts.family,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: ink,
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: CestaDisplayType.itemName.copyWith(color: ink),
                ),
              ],
            ),
            // The hole, in the screen's ground colour (positioned from the tile's corner, not its padding).
            Positioned(
              left: holeCentre.dx - 4 - 12,
              top: holeCentre.dy - 4 - 12,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, shape: BoxShape.circle),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Where a [CesItemTile] hangs in a [CesHangingTiles] canvas: its top-left
/// corner at ([left], [top]), turned [degrees] clockwise about that corner, as
/// Figma positions a rotated layer.
class CesHangingTile {
  const CesHangingTile({required this.left, required this.top, required this.degrees, required this.tile});

  final double left;
  final double top;
  final double degrees;
  final CesItemTile tile;

  double get _radians => degrees * math.pi / 180;

  /// The tag hole in canvas coordinates.
  Offset get hole {
    final c = CesItemTile.holeCentre;
    return Offset(
      left + c.dx * math.cos(_radians) - c.dy * math.sin(_radians),
      top + c.dx * math.sin(_radians) + c.dy * math.cos(_radians),
    );
  }
}

/// Item tiles hanging on strings from the top of a [canvas]-sized area, the
/// design's decorative hero. The strings are Banana on a [CesBrandScaffold],
/// muted elsewhere. The canvas scales down to fit narrower screens. It is
/// decoration only, so screen readers skip it.
class CesHangingTiles extends StatelessWidget {
  const CesHangingTiles({super.key, required this.canvas, required this.tiles});

  final Size canvas;
  final List<CesHangingTile> tiles;

  @override
  Widget build(BuildContext context) {
    final stringColour = CesBrandScaffold.contains(context)
        ? context.palette.toBuy
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return ExcludeSemantics(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox.fromSize(
          size: canvas,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final t in tiles)
                Positioned(
                  left: t.hole.dx - 0.75,
                  top: -8,
                  width: 1.5,
                  height: t.hole.dy + 8,
                  child: ColoredBox(color: stringColour),
                ),
              for (final t in tiles)
                Positioned(
                  left: t.left,
                  top: t.top,
                  child: Transform.rotate(angle: t._radians, alignment: Alignment.topLeft, child: t.tile),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
