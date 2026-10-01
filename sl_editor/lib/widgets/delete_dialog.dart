import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class DeleteDialog extends StatelessWidget {
  final String name;
  final VoidCallback onDelete;

  const DeleteDialog({
    super.key,
    required this.name,
    required this.onDelete,
  });

  void _confirm(BuildContext context) {
    onDelete();
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
              text: 'Delete ',
              style: TextStyle(fontWeight: .normal),
            ),
            TextSpan(
              text: name,
              style: TextStyle(fontWeight: .bold),
            ),
            TextSpan(
              text: '?',
              style: TextStyle(fontWeight: .normal),
            ),
          ],
        ),
      ),
      gap: 24.0,
      actions: [
        ShadButton.outline(
          onPressed: () => _cancel(context),
          child: Text('Back'),
        ),
        ShadButton.destructive(
          onPressed: () => _confirm(context),
          child: Text('Delete'),
        ),
      ],
    );
  }
}
