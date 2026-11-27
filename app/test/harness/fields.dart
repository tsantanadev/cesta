import 'package:cesta/src/ui/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

bool _labelled(Widget w, String label) => switch (w) {
  CesTextField(label: final l) || CesPasswordField(label: final l) => l == label,
  _ => false,
};

/// The editable text of the field labelled [label], on any platform.
Finder field(String label) =>
    find.descendant(of: find.byWidgetPredicate((w) => _labelled(w, label)), matching: find.byType(EditableText));

/// The controller of the field labelled [label].
TextEditingController fieldController(WidgetTester tester, String label) =>
    tester.widget<EditableText>(field(label)).controller;
