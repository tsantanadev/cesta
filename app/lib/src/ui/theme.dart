import 'package:material_ui/material_ui.dart';

import 'tokens.dart';

/// The Material 3 Cesta theme, in light and dark variants.
abstract final class CestaTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final light = brightness == Brightness.light;
    final scheme = light ? _lightScheme : _darkScheme;
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      brightness: brightness,
      fontFamily: CestaFonts.family,
    );
    // Figma Button (3:61): 56 dp pills, Plus Jakarta Sans Bold 16.
    const pill = StadiumBorder();
    const buttonLabel = TextStyle(fontFamily: CestaFonts.family, fontWeight: FontWeight.w700, fontSize: 16);
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
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 44),
          shape: pill,
          textStyle: const TextStyle(fontFamily: CestaFonts.family, fontWeight: FontWeight.w700, fontSize: 15),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
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

  // Every Material role from the Figma palette ("Cesta color" and "Cesta
  // color (dark)"), so nothing is derived from a seed colour.
  static const _lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: CestaColors.folha,
    onPrimary: CestaColors.onFolha,
    primaryContainer: CestaColors.checked,
    onPrimaryContainer: CestaColors.folha,
    secondary: CestaColors.banana,
    onSecondary: CestaColors.onBanana,
    secondaryContainer: CestaColors.checked,
    onSecondaryContainer: CestaColors.tinta,
    error: CestaColors.beterraba,
    onError: CestaColors.onFolha,
    errorContainer: Color(0xFFF8DDE2),
    onErrorContainer: CestaColors.beterraba,
    surface: CestaColors.alface,
    onSurface: CestaColors.tinta,
    onSurfaceVariant: CestaColors.tintaMuted,
    surfaceContainerLowest: CestaColors.branco,
    surfaceContainerLow: CestaColors.branco,
    surfaceContainer: CestaColors.branco,
    surfaceContainerHigh: CestaColors.branco,
    surfaceContainerHighest: CestaColors.checked,
    outline: CestaColors.tintaMuted,
    outlineVariant: CestaColors.checked,
    inverseSurface: CestaColors.toast,
    onInverseSurface: CestaColors.onToast,
    inversePrimary: CestaColors.banana,
  );

  static const _darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: CestaColors.folhaDark,
    onPrimary: CestaColors.onFolhaDark,
    primaryContainer: CestaColors.checkedDark,
    onPrimaryContainer: CestaColors.folhaDark,
    secondary: CestaColors.bananaDark,
    onSecondary: CestaColors.onBanana,
    secondaryContainer: CestaColors.checkedDark,
    onSecondaryContainer: CestaColors.tintaDark,
    error: CestaColors.beterrabaDark,
    onError: CestaColors.onFolhaDark,
    errorContainer: Color(0xFF3A1A22),
    onErrorContainer: CestaColors.beterrabaDark,
    surface: CestaColors.alfaceDark,
    onSurface: CestaColors.tintaDark,
    onSurfaceVariant: CestaColors.tintaMutedDark,
    surfaceContainerLowest: CestaColors.brancoDark,
    surfaceContainerLow: CestaColors.brancoDark,
    surfaceContainer: CestaColors.brancoDark,
    surfaceContainerHigh: CestaColors.brancoDark,
    surfaceContainerHighest: CestaColors.checkedDark,
    outline: CestaColors.tintaMutedDark,
    outlineVariant: CestaColors.checkedDark,
    inverseSurface: CestaColors.toast,
    onInverseSurface: CestaColors.onToast,
    inversePrimary: CestaColors.bananaDark,
  );
}
