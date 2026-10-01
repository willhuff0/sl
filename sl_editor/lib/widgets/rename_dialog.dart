import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:sl_editor/widgets/disable_shortcuts.dart';

class RenameDialog extends StatefulWidget {
  final String name;
  final String? Function(String value) validate;
  final void Function(String value) onSave;

  const RenameDialog({
    super.key,
    required this.name,
    required this.validate,
    required this.onSave,
  });

  @override
  State<RenameDialog> createState() => _AssetRenameDialogState();
}

class _AssetRenameDialogState extends State<RenameDialog> {
  final _formKey = GlobalKey();
  late final TextEditingController _textEditingController;

  @override
  void initState() {
    _textEditingController = TextEditingController(text: widget.name);
    super.initState();
  }

  void _confirm(BuildContext context) {
    if (_formKey.currentContext == null) return;
    final formState = _formKey.currentState as FormState;

    if (!formState.validate()) return;
    formState.save();

    Navigator.pop(context);
  }

  void _cancel(BuildContext context) {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return ShadDialog.alert(
      title: Text.rich(
        TextSpan(
          children: [
            TextSpan(
              text: 'Rename ',
              style: TextStyle(fontWeight: .normal),
            ),
            TextSpan(
              text: widget.name,
              style: TextStyle(fontWeight: .bold),
            ),
            TextSpan(
              text: '.',
              style: TextStyle(fontWeight: .normal),
            ),
          ],
        ),
      ),
      description: DisableShortcuts(
        child: Form(
          key: _formKey,
          child: ShadInputFormField(
            controller: _textEditingController,
            autofocus: true,
            maxLength: 128,
            validator: widget.validate,
            onSaved: (value) => widget.onSave(value!),
            onEditingComplete: () => _confirm(context),
          ),
        ),
      ),
      gap: 24.0,
      actions: [
        ShadButton.outline(
          onPressed: () => _cancel(context),
          child: Text('Back'),
        ),
        ShadButton(
          onPressed: () => _confirm(context),
          child: Text('Rename'),
        ),
      ],
    );
  }
}
