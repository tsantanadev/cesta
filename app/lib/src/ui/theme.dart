import 'package:material_ui/material_ui.dart';

import 'tokens.dart';

/// The Material 3 Cesta theme, in light and dark variants.
abstract final class CestaTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(seedColor: CestaColors.seed, brightness: brightness);
    final base = ThemeData(useMaterial3: true, colorScheme: scheme, brightness: brightness);
    return base.copyWith(
      textTheme: cestaTextTheme(base.textTheme),
      extensions: [
        const CestaSpacing(),
        brightness == Brightness.light ? CestaStatusColors.light : CestaStatusColors.dark,
      ],
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CestaRadii.card)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CestaRadii.button)),
        ),
      ),
    );
  }
}
