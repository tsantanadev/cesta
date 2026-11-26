import 'package:material_ui/material_ui.dart';

import '../../l10n/app_localizations.dart';
import '../ui/components.dart';
import 'list_messages.dart';
import 'lists_controller.dart';

/// The name field and button of the New list and Rename list sheets. Closes
/// its sheet once [onSubmit] succeeds; otherwise says why it didn't.
class ListNameForm extends StatefulWidget {
  const ListNameForm({super.key, required this.submitLabel, required this.onSubmit, this.initialName = ''});

  final String submitLabel;
  final String initialName;

  /// Saves the name; null when it went through.
  final Future<ListFailure?> Function(String name) onSubmit;

  @override
  State<ListNameForm> createState() => _ListNameFormState();
}

class _ListNameFormState extends State<ListNameForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.initialName);
  bool _busy = false;
  ListFailure? _failure;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _busy = true;
      _failure = null;
    });
    final failure = await widget.onSubmit(_name.text);
    if (!mounted) return;
    if (failure == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _busy = false;
      _failure = failure;
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
            validator: (value) => validateListName(l10n, value),
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
          ),
          if (_failure case final failure?) ...[
            const CesGap.md(),
            CesMessage(tone: CesMessageTone.error, text: listFailureMessage(l10n, failure)),
          ],
          const CesGap.lg(),
          CesButton(label: widget.submitLabel, busy: _busy, onPressed: _submit),
        ],
      ),
    );
  }
}
