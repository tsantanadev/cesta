import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoButton, CupertinoTextField;
import 'package:material_ui/material_ui.dart';

import 'icons.dart';
import 'platform.dart';
import 'scaffolds.dart';
import 'tokens.dart';

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
        if (busy || icon != null) const SizedBox(width: CestaButtonMetrics.iconGap),
        Flexible(child: Text(label, textAlign: TextAlign.center)),
      ],
    );
    final border = stroke == null ? BorderSide.none : BorderSide(color: stroke, width: CestaButtonMetrics.borderWidth);
    if (isCupertino(context)) {
      return DecoratedBox(
        decoration: ShapeDecoration(shape: StadiumBorder(side: border)),
        child: CupertinoButton(
          onPressed: onPressed,
          color: background,
          disabledColor: background.withValues(alpha: background.a * 0.5),
          foregroundColor: foreground,
          minimumSize: const Size(CestaButtonMetrics.height, CestaButtonMetrics.height),
          padding: const EdgeInsets.symmetric(horizontal: CestaButtonMetrics.horizontalPadding),
          borderRadius: BorderRadius.circular(CestaRadii.button),
          child: DefaultTextStyle.merge(
            style: CestaButtonMetrics.labelStyle.copyWith(color: foreground),
            child: content,
          ),
        ),
      );
    }
    // Height, pill shape, horizontal padding and label text style come from
    // filledButtonTheme / outlinedButtonTheme in CestaTheme.
    final style = ButtonStyle(
      backgroundColor: WidgetStateProperty.resolveWith(
        (states) =>
            states.contains(WidgetState.disabled) ? background.withValues(alpha: background.a * 0.5) : background,
      ),
      foregroundColor: WidgetStatePropertyAll(foreground),
      overlayColor: WidgetStatePropertyAll(foreground.withValues(alpha: 0.08)),
      side: stroke == null ? null : WidgetStatePropertyAll(border),
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
    if (!isCupertino(context)) return TextButton(onPressed: onPressed, child: text);
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
  const CesIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.compact = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  /// Uses a 36 dp footprint (e.g. the card's More button, Figma 35:2094).
  final bool compact;

  @override
  Widget build(BuildContext context) => IconButton(
    icon: Icon(icon),
    tooltip: tooltip,
    onPressed: onPressed,
    style: compact
        ? IconButton.styleFrom(
            fixedSize: const Size(36, 36),
            minimumSize: const Size(36, 36),
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          )
        : null,
  );
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
  Widget build(BuildContext context) => MergeSemantics(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CesFieldLabel(label),
        SizedBox(height: context.spacing.sm),
        child,
      ],
    ),
  );
}

/// The label above a field or a group of controls, e.g. "How much": 13 dp
/// semibold, muted.
class CesFieldLabel extends StatelessWidget {
  const CesFieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.labelMedium?.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

/// What is wrong with a field or a group of controls, under it, in the error colour.
class CesFieldError extends StatelessWidget {
  const CesFieldError(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(text, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error));
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
    if (!isCupertino(context)) {
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
/// welcome headline), with an optional [subtitle] under it as [CesText.intro].
/// On-brand on a [CesBrandScaffold].
class CesDisplayHeading extends StatelessWidget {
  const CesDisplayHeading(this.text, {super.key, this.large = false, this.subtitle});

  final String text;
  final bool large;
  final String? subtitle;

  static const _subtitleGap = 10.0;

  @override
  Widget build(BuildContext context) {
    final colour = CesBrandScaffold.contains(context)
        ? context.palette.onBrand
        : Theme.of(context).colorScheme.onSurface;
    final heading = Semantics(
      header: true,
      child: Text(text, style: (large ? CestaDisplayType.headline : CestaDisplayType.heading).copyWith(color: colour)),
    );
    if (subtitle == null) return heading;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        heading,
        const SizedBox(height: _subtitleGap),
        CesText.intro(subtitle!),
      ],
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
      shape: CestaButtonMetrics.shape,
      extendedPadding: EdgeInsets.symmetric(horizontal: context.spacing.lg),
      icon: Icon(icon, size: 20),
      label: Text(label, style: CestaButtonMetrics.labelStyle),
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
