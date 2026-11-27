import 'package:flutter/services.dart' show TextInputFormatter, FilteringTextInputFormatter;
import 'package:material_ui/material_ui.dart';

import 'icons.dart';
import 'tokens.dart';

/// A Checked Item In the basket (Figma "Checked item" 3:47): a filled check,
/// the [name] crossed out and who [checkedBy] it. Tapping it runs [onTap].
class CesCheckedItem extends StatelessWidget {
  const CesCheckedItem({
    super.key,
    required this.name,
    required this.checkedBy,
    this.onTap,
    this.onLongPress,
    this.semanticHint,
  });

  final String name;
  final String checkedBy;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? semanticHint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant;
    return Semantics(
      button: onTap != null,
      hint: semanticHint,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(CestaRadii.field),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(color: scheme.primary, shape: BoxShape.circle),
                  child: Icon(CesIcons.check, size: 14, color: scheme.onPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    style: TextStyle(
                      fontFamily: CestaFonts.family,
                      fontWeight: FontWeight.w500,
                      fontSize: 16,
                      color: muted,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: muted,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  checkedBy,
                  style: TextStyle(
                    fontFamily: CestaFonts.family,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: muted,
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

/// A section heading on a List's screen, e.g. "In the basket" (Figma text 1bt75d4).
class CesSectionHeading extends StatelessWidget {
  const CesSectionHeading(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    child: Text(
      text,
      style: TextStyle(
        fontFamily: CestaFonts.family,
        fontWeight: FontWeight.w700,
        fontSize: 15,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    ),
  );
}

/// The bar pinned to the bottom of a List's screen (Figma "Add bar" 4:264):
/// a white panel with a rounded Alface field showing a plus and [label].
class CesAddBar extends StatelessWidget {
  const CesAddBar({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  /// The bar's height above the bottom safe area, which content scrolls clear of.
  static const height = 96.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLowest,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: const [BoxShadow(color: Color(0x1A173829), offset: Offset(0, -4), blurRadius: 20)],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 14, 16, 30 + bottomInset),
        child: Semantics(
          button: true,
          child: Material(
            color: scheme.surface,
            shape: const StadiumBorder(),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              child: SizedBox(
                height: 52,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: [
                      Icon(CesIcons.plus, size: 20, color: scheme.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: CestaFonts.family,
                            fontWeight: FontWeight.w500,
                            fontSize: 16,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A screen's back button (Figma "Back" 4:152): a 44 dp target with a 22 dp caret.
class CesBackButton extends StatelessWidget {
  const CesBackButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: MaterialLocalizations.of(context).backButtonTooltip,
    onPressed: onPressed,
    icon: Icon(CesIcons.back, size: 22, color: Theme.of(context).colorScheme.onSurface),
    style: IconButton.styleFrom(fixedSize: const Size(44, 44), minimumSize: const Size(44, 44)),
  );
}

/// The search field of Add items (Figma "Field" 4:273): a 52 dp white pill
/// with a Folha outline and a magnifying glass.
class CesSearchField extends StatelessWidget {
  const CesSearchField({
    super.key,
    required this.controller,
    required this.label,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
  });

  final TextEditingController controller;

  /// What the field is, for screen readers.
  final String label;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: ShapeDecoration(
        color: scheme.surfaceContainerLowest,
        shape: StadiumBorder(side: BorderSide(color: scheme.primary, width: 2)),
      ),
      child: Row(
        children: [
          Icon(CesIcons.search, size: 20, color: scheme.onSurface),
          const SizedBox(width: 10),
          Expanded(
            child: Semantics(
              label: label,
              child: TextField(
                controller: controller,
                onChanged: onChanged,
                onSubmitted: onSubmitted,
                autofocus: autofocus,
                textInputAction: TextInputAction.done,
                textCapitalization: TextCapitalization.sentences,
                cursorColor: scheme.primary,
                style: TextStyle(
                  fontFamily: CestaFonts.family,
                  fontWeight: FontWeight.w500,
                  fontSize: 17,
                  color: scheme.onSurface,
                ),
                decoration: const InputDecoration(
                  filled: false,
                  isCollapsed: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Add “…” as a new item" on Add items (Figma 4:307): a dashed Folha outline
/// with a plus and [label].
class CesAddAsNew extends StatelessWidget {
  const CesAddAsNew({super.key, required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colour = Theme.of(context).colorScheme.primary;
    return Semantics(
      button: true,
      child: CustomPaint(
        painter: _DashedOutline(colour),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(CestaRadii.sign),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Icon(CesIcons.plus, size: 18, color: colour),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: CestaFonts.family,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: colour,
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

/// A 1.5 dp dashed (6 on, 4 off) rounded outline.
class _DashedOutline extends CustomPainter {
  const _DashedOutline(this.colour);

  final Color colour;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 1.5;
    final rect = (Offset.zero & size).deflate(stroke / 2);
    final path = Path()..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(CestaRadii.sign)));
    final paint = Paint()
      ..color = colour
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    for (final metric in path.computeMetrics()) {
      for (var d = 0.0; d < metric.length; d += 10) {
        canvas.drawPath(metric.extractPath(d, d + 6), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DashedOutline old) => old.colour != colour;
}

/// The quantity stepper of the New item sheet (Figma "Stepper" 9:461): − and
/// + on an Alface pill around the value, which can also be typed (decimals too).
class CesStepper extends StatelessWidget {
  const CesStepper({
    super.key,
    required this.controller,
    required this.onDecrease,
    required this.onIncrease,
    required this.decreaseLabel,
    required this.increaseLabel,
    required this.valueLabel,
  });

  final TextEditingController controller;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final String decreaseLabel;
  final String increaseLabel;
  final String valueLabel;

  static final List<TextInputFormatter> _decimals = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget step(String glyph, String label, VoidCallback onTap) => Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 22,
        child: SizedBox.square(
          dimension: 44,
          child: Center(
            child: Text(
              glyph,
              style: TextStyle(
                fontFamily: CestaFonts.family,
                fontWeight: FontWeight.w700,
                fontSize: 20,
                color: scheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
    return Container(
      height: 44,
      decoration: ShapeDecoration(color: scheme.surface, shape: const StadiumBorder()),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          step('−', decreaseLabel, onDecrease),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 28, maxWidth: 72),
            child: IntrinsicWidth(
              child: Semantics(
                label: valueLabel,
                child: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: _decimals,
                  textAlign: TextAlign.center,
                  cursorColor: scheme.primary,
                  style: TextStyle(
                    fontFamily: CestaFonts.display,
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: scheme.onSurface,
                  ),
                  decoration: const InputDecoration(
                    filled: false,
                    isCollapsed: true,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                  ),
                ),
              ),
            ),
          ),
          step('+', increaseLabel, onIncrease),
        ],
      ),
    );
  }
}

/// A pill choice, e.g. a unit on the New item sheet (Figma "Unit" 9:468):
/// Folha when [selected], outlined otherwise.
class CesChoiceChip extends StatelessWidget {
  const CesChoiceChip({super.key, required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected ? scheme.primary : Colors.transparent,
        shape: StadiumBorder(side: selected ? BorderSide.none : BorderSide(color: scheme.outlineVariant, width: 1.5)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            height: 44,
            constraints: const BoxConstraints(minWidth: 39),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                fontFamily: CestaFonts.family,
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: selected ? scheme.onPrimary : scheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A filled Alface text field with a [hint], e.g. the New item note (Figma 9:497).
class CesSoftField extends StatelessWidget {
  const CesSoftField({super.key, required this.controller, required this.hint, this.maxLength});

  final TextEditingController controller;
  final String hint;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = TextStyle(
      fontFamily: CestaFonts.family,
      fontWeight: FontWeight.w500,
      fontSize: 15,
      color: scheme.onSurface,
    );
    final border = OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none);
    return TextField(
      controller: controller,
      maxLength: maxLength,
      textCapitalization: TextCapitalization.sentences,
      cursorColor: scheme.primary,
      style: style,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: style.copyWith(color: scheme.onSurfaceVariant),
        filled: true,
        fillColor: scheme.surface,
        counterText: '',
        constraints: const BoxConstraints(minHeight: 52),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: border,
        enabledBorder: border,
        focusedBorder: border,
      ),
    );
  }
}

/// A status pill under a List's title (Figma "Offline pill" 38:3844): a
/// muted dot and a [label] on Branco.
class CesStatusPill extends StatelessWidget {
  const CesStatusPill({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: ShapeDecoration(color: scheme.surfaceContainerLow, shape: const StadiumBorder()),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 7, 14, 7),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: scheme.onSurfaceVariant, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: CestaFonts.family,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
