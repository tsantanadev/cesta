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
      onPrimary: light ? CestaColors.onFolha : CestaColors.onFolhaDark,
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
    // Figma Button (3:61): 56 dp pills, Plus Jakarta Sans Bold 16.
    const pill = StadiumBorder();
    const buttonLabel = TextStyle(fontWeight: FontWeight.w700, fontSize: 16);
    const buttonSize = Size(64, 56);
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
        // Figma Toast (4:362).
        backgroundColor: CestaColors.toast,
        contentTextStyle: const TextStyle(
          fontFamily: CestaFonts.family,
          color: CestaColors.onToast,
          fontWeight: FontWeight.w500,
          fontSize: 15,
        ),
        actionTextColor: light ? CestaColors.banana : CestaColors.bananaDark,
        insetPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CestaRadii.card)),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CestaRadii.card)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: buttonSize,
          shape: pill,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          textStyle: buttonLabel,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: buttonSize,
          shape: pill,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          textStyle: buttonLabel,
          foregroundColor: scheme.onSurface,
          backgroundColor: scheme.surfaceContainerLow,
          side: BorderSide(color: light ? CestaColors.checked : CestaColors.checkedDark, width: 1.5),
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
        // Figma sheet (9:436): Checked grabber, 28 dp top corners.
        showDragHandle: true,
        dragHandleSize: const Size(40, 4),
        dragHandleColor: light ? CestaColors.checked : CestaColors.checkedDark,
        backgroundColor: scheme.surfaceContainerLow,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(CestaRadii.sheet)),
        ),
      ),
    );
  }
}
