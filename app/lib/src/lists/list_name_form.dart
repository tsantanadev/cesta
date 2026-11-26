import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../ui/components.dart';
import 'lists_controller.dart';
import 'lists_screen.dart';

/// The name field and button of the New list and Rename list sheets. Closes
/// its sheet once [onSubmit] succeeds; otherwise says why it didn't.
class ListNameForm extends StatefulWidget {
  const ListNameForm({super.key, required this.submitLabel, required this.onSubmit, this.initialName = ''});

  final String submitLabel;
  final String initialName;
  final Future<ListOutcome> Function(String name) onSubmit;

  @override
  State<ListNameForm> createState() => _ListNameFormState();
}

class _ListNameFormState extends State<ListNameForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initialName);
  bool _busy = false;
  ListOutcome? _outcome;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String? _validate(String? value) {
    final l10n = AppLocalizations.of(context);
    final name = (value ?? '').trim();
    if (name.isEmpty) return l10n.errorListNameRequired;
    if (name.runes.length > maxListNameLength) return l10n.errorListNameTooLong;
    if (name.runes.any((r) => r < 0x20 || (r >= 0x7f && r < 0xa0))) return l10n.errorListNameInvalid;
    return null;
  }

  Future<void> _submit() async {
    if (_busy || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _outcome = null;
    });
    final outcome = await widget.onSubmit(_name.text);
    if (!mounted) return;
    if (outcome == ListOutcome.done) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _busy = false;
      _outcome = outcome;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CesTextField(
            label: l10n.fieldListName,
            controller: _name,
            validator: _validate,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          if (_outcome case final outcome?) ...[
            const CesGap.md(),
            CesMessage(tone: CesMessageTone.error, text: listOutcomeMessage(l10n, outcome)),
          ],
          const CesGap.lg(),
          CesButton(label: widget.submitLabel, busy: _busy, onPressed: _submit),
        ],
      ),
    );
  }
}
