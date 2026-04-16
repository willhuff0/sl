import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:sl_editor/importers/importers.dart';
import 'package:sl_editor/pages/editor.dart';

void main() async {
  registerImporters();
  WidgetsFlutterBinding.ensureInitialized();
  await BrowserContextMenu.disableContextMenu();
  runApp(const EditorApp());
}

class EditorApp extends StatelessWidget {
  const EditorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ShadApp(
      debugShowCheckedModeBanner: false,
      theme: ShadThemeData(
        colorScheme: ShadVioletColorScheme.dark(),
        brightness: Brightness.dark,
        ghostButtonTheme: ShadButtonTheme(
          foregroundColor: ShadVioletColorScheme.dark().foreground,
        ),
        outlineButtonTheme: ShadButtonTheme(
          foregroundColor: ShadVioletColorScheme.dark().foreground,
        ),
      ),
      home: EditorClientLoader(),
    );
  }
}
