import 'package:material_ui/material_ui.dart';

import 'tokens.dart';

/// The Material 3 Cesta theme, in light and dark variants.
abstract final class CestaTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final light = brightness == Brightness.light;
    // Material roles mapped from the design palette; the seed fills the rest.
    final scheme = ColorScheme.fromSeed(seedColor: CestaColors.seed, brightness: brightness).copyWith(
      primary: light ? CestaColors.folha : CestaColors.folhaDark,
      onPrimary: light ? CestaColors.branco : CestaColors.onFolhaDark,
      surface: light ? CestaColors.alface : CestaColors.alfaceDark,
      onSurface: light ? CestaColors.tinta : CestaColors.tintaDark,
      onSurfaceVariant: light ? CestaColors.tintaMuted : CestaColors.tintaMutedDark,
      surfaceContainerLowest: light ? CestaColors.branco : CestaColors.brancoDark,
      surfaceContainerLow: light ? CestaColors.branco : CestaColors.brancoDark,
      error: light ? CestaColors.beterraba : CestaColors.beterrabaDark,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      fontFamily: CestaFonts.family,
    );
    final buttonShape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(CestaRadii.button));
    final fieldBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(CestaRadii.field),
      borderSide: BorderSide.none,
    );
    return base.copyWith(
      textTheme: cestaTextTheme(base.textTheme),
      extensions: [
        const CestaSpacing(),
        if (light) CestaStatusColors.light else CestaStatusColors.dark,
        if (light) CestaPalette.light else CestaPalette.dark,
      ],
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.onSurface,
        contentTextStyle: base.textTheme.bodyLarge?.copyWith(color: scheme.surface, fontWeight: FontWeight.w600),
        actionTextColor: light ? CestaColors.banana : CestaColors.folha,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CestaRadii.card)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CestaRadii.card)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size(64, 52), shape: buttonShape),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          shape: buttonShape,
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(minimumSize: const Size(48, 48), shape: buttonShape),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
        border: fieldBorder,
        enabledBorder: fieldBorder,
        focusedBorder: fieldBorder.copyWith(borderSide: BorderSide(color: scheme.primary, width: 2)),
        errorBorder: fieldBorder.copyWith(borderSide: BorderSide(color: scheme.error)),
        focusedErrorBorder: fieldBorder.copyWith(borderSide: BorderSide(color: scheme.error, width: 2)),
        errorMaxLines: 3,
        helperMaxLines: 3,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        showDragHandle: true,
        backgroundColor: scheme.surfaceContainerLow,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(CestaRadii.sheet)),
        ),
      ),
    );
  }
}
