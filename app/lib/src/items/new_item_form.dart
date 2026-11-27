import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../api/generated/cesta_api.dart';
import '../names.dart';
import '../ui/components.dart';
import 'item_text.dart';

/// A new Item as the New item sheet filled it in.
typedef ItemDraft = ({String name, String? quantity, ItemUnit? unit, String? note});

/// The New item sheet's content (Figma "07 New item" 9:436): the tag preview,
/// Name, How much (a stepper that also takes typed decimals, and unit chips),
/// a note and "Add to [listName]". Closes its sheet, then hands the draft to
/// [onSubmit].
class NewItemForm extends StatefulWidget {
  const NewItemForm({super.key, required this.listName, required this.onSubmit, this.initialName = ''});

  final String listName;
  final String initialName;
  final void Function(ItemDraft draft) onSubmit;

  @override
  State<NewItemForm> createState() => _NewItemFormState();
}

class _NewItemFormState extends State<NewItemForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initialName)..addListener(_changed);
  final _quantity = TextEditingController();
  final _note = TextEditingController();
  ItemUnit? _unit;
  bool _quantityInvalid = false;

  @override
  void initState() {
    super.initState();
    _quantity.addListener(_changed);
  }

  void _changed() => setState(() => _quantityInvalid = false);

  @override
  void dispose() {
    _name.dispose();
    _quantity.dispose();
    _note.dispose();
    super.dispose();
  }

  /// The typed quantity as a number, or null when blank or not a number.
  num? get _quantityValue {
    try {
      final q = parseQuantity(_quantity.text);
      return q == null ? null : num.parse(q);
    } on FormatException {
      return null;
    }
  }

  void _step(int by) {
    final current = _quantityValue ?? 0;
    final next = current + by;
    // Below one the quantity goes away, like the design's tags without one.
    _quantity.text = next < 1 ? '' : _plain(next);
  }

  static String _plain(num n) => n == n.roundToDouble() ? n.toInt().toString() : n.toString();

  void _submit() {
    String? quantity;
    try {
      quantity = parseQuantity(_quantity.text);
    } on FormatException {
      setState(() => _quantityInvalid = true);
    }
    final nameOk = _formKey.currentState?.validate() ?? false;
    if (!nameOk || _quantityInvalid) return;
    final note = _note.text.trim();
    final draft = (name: _name.text.trim(), quantity: quantity, unit: _unit, note: note.isEmpty ? null : note);
    Navigator.of(context).pop();
    widget.onSubmit(draft);
  }

  String? _validateName(AppLocalizations l10n, String? value) =>
      switch (checkName(value ?? '', maxLength: maxItemNameLength)) {
        null => null,
        NameProblem.blank => l10n.errorItemNameRequired,
        NameProblem.tooLong => l10n.errorItemNameTooLong(maxItemNameLength),
        NameProblem.invalidCharacters => l10n.errorItemNameRequired,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    String? previewQuantity;
    try {
      previewQuantity = tagQuantity(l10n, parseQuantity(_quantity.text), _unit);
    } on FormatException {
      previewQuantity = null;
    }
    const gap = SizedBox(height: 18);
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: CesItemPreview(name: _name.text.trim(), quantity: previewQuantity),
          ),
          gap,
          CesTextField.display(
            label: l10n.newItemName,
            controller: _name,
            validator: (value) => _validateName(l10n, value),
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
          ),
          gap,
          Text(
            l10n.newItemHowMuch,
            style: theme.textTheme.labelMedium?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                CesStepper(
                  controller: _quantity,
                  decreaseLabel: l10n.newItemLess,
                  increaseLabel: l10n.newItemMore,
                  valueLabel: l10n.newItemQuantity,
                  onDecrease: () => _step(-1),
                  onIncrease: () => _step(1),
                ),
                const SizedBox(width: 10),
                for (final (i, unit) in unitChoices.indexed) ...[
                  if (i > 0) const SizedBox(width: 6),
                  CesChoiceChip(
                    label: unitLabel(l10n, unit),
                    selected: _unit == unit,
                    onTap: () => setState(() => _unit = _unit == unit ? null : unit),
                  ),
                ],
              ],
            ),
          ),
          if (_quantityInvalid) ...[
            const SizedBox(height: 8),
            Text(
              l10n.errorItemQuantityInvalid,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.error),
            ),
          ],
          gap,
          CesSoftField(controller: _note, hint: l10n.newItemNoteHint, maxLength: maxItemNoteLength),
          gap,
          CesButton(label: l10n.newItemAddTo(widget.listName), icon: CesIcons.plus, onPressed: _submit),
        ],
      ),
    );
  }
}
