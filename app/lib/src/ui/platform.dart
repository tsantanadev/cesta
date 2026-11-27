import 'package:material_ui/material_ui.dart';

/// Whether [context] should render Cupertino-adapted controls and sheets.
bool isCupertino(BuildContext context) => switch (Theme.of(context).platform) {
  TargetPlatform.iOS || TargetPlatform.macOS => true,
  _ => false,
};
