import 'package:material_ui/material_ui.dart';

/// Cesta design tokens. Feature code never uses raw colours, sizes or
/// font styles; it reads them through the theme (see `CestaTheme`) and the
/// in-house components in `components.dart`.
abstract final class CestaColors {
  /// Brand seed: Folha, the actions green.
  static const seed = folha;

  // The design palette (Figma "Cesta — App design", Foundations / Palette).
  // Names are the design's produce words.

  /// Actions: buttons, the wordmark.
  static const folha = Color(0xFF1E6B43);

  /// Text.
  static const tinta = Color(0xFF17382A);

  /// Secondary text.
  static const tintaMuted = Color(0xFF5E7466);

  /// Screen background.
  static const alface = Color(0xFFEDF3EA);

  /// Cards.
  static const branco = Color(0xFFFFFFFF);

  /// Items to buy: the count sign.
  static const banana = Color(0xFFFFD43B);

  /// Text on [banana].
  static const onBanana = Color(0xFF17382A);

  /// Bought: the "everything's bought" sign.
  static const checked = Color(0xFFDCE5D8);

  /// Destructive actions.
  static const beterraba = Color(0xFFC8324F);

  /// Text and icons on [folha].
  static const onFolha = Color(0xFFFFFFFF);

  // Dark variants: Figma "Cesta color (dark)" collection.
  static const bananaDark = Color(0xFFF2C934);
  static const folhaDark = Color(0xFF4CB97A);
  static const onFolhaDark = Color(0xFF0F2318);
  static const tintaDark = Color(0xFFE4EEE6);
  static const tintaMutedDark = Color(0xFF93A89A);
  static const alfaceDark = Color(0xFF0E1A14);
  static const brancoDark = Color(0xFF18271F);
  static const checkedDark = Color(0xFF26382D);
  static const beterrabaDark = Color(0xFFF0647F);

  /// The Toast's ground: deep Tinta in both modes (Figma "on-banana").
  static const toast = Color(0xFF17382A);

  /// Text on the Toast and on brand surfaces, in both modes (Figma "on-brand").
  static const onToast = Color(0xFFFFFFFF);

  /// Status colours, used for health and sync indicators.
  static const success = Color(0xFF2E7D32);
  static const successDark = Color(0xFF81C784);
  static const warning = Color(0xFFB26A00);
  static const warningDark = Color(0xFFFFB74D);
}

/// Spacing scale on a 4 dp grid.
@immutable
class CestaSpacing extends ThemeExtension<CestaSpacing> {
  const CestaSpacing({this.xs = 4, this.sm = 8, this.md = 16, this.lg = 24, this.xl = 32});

  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;

  @override
  CestaSpacing copyWith({double? xs, double? sm, double? md, double? lg, double? xl}) =>
      CestaSpacing(xs: xs ?? this.xs, sm: sm ?? this.sm, md: md ?? this.md, lg: lg ?? this.lg, xl: xl ?? this.xl);

  @override
  CestaSpacing lerp(CestaSpacing? other, double t) => other ?? this;
}

/// Corner radii.
abstract final class CestaRadii {
  static const card = 16.0;
  static const button = 12.0;
  static const field = 12.0;
  static const sheet = 28.0;
}

/// The bundled typefaces (assets/fonts, declared in pubspec.yaml).
abstract final class CestaFonts {
  /// Plus Jakarta Sans: everything but display text.
  static const family = 'PlusJakartaSans';

  /// Bricolage Grotesque ExtraBold: List names, screen titles, the wordmark.
  static const display = 'BricolageGrotesque';
}

/// Colours of the design palette that Material's [ColorScheme] has no role
/// for, in light and dark variants.
@immutable
class CestaPalette extends ThemeExtension<CestaPalette> {
  const CestaPalette({required this.toBuy, required this.onToBuy, required this.bought, required this.onBought});

  static const light = CestaPalette(
    toBuy: CestaColors.banana,
    onToBuy: CestaColors.onBanana,
    bought: CestaColors.checked,
    onBought: CestaColors.folha,
  );
  static const dark = CestaPalette(
    toBuy: CestaColors.bananaDark,
    onToBuy: CestaColors.onBanana,
    bought: CestaColors.checkedDark,
    onBought: CestaColors.folhaDark,
  );

  /// The sign that counts Items still to buy (Banana).
  final Color toBuy;
  final Color onToBuy;

  /// The sign of a List with nothing left to buy (Checked).
  final Color bought;
  final Color onBought;

  @override
  CestaPalette copyWith({Color? toBuy, Color? onToBuy, Color? bought, Color? onBought}) => CestaPalette(
    toBuy: toBuy ?? this.toBuy,
    onToBuy: onToBuy ?? this.onToBuy,
    bought: bought ?? this.bought,
    onBought: onBought ?? this.onBought,
  );

  @override
  CestaPalette lerp(CestaPalette? other, double t) => other == null
      ? this
      : CestaPalette(
          toBuy: Color.lerp(toBuy, other.toBuy, t)!,
          onToBuy: Color.lerp(onToBuy, other.onToBuy, t)!,
          bought: Color.lerp(bought, other.bought, t)!,
          onBought: Color.lerp(onBought, other.onBought, t)!,
        );
}

/// Display text styles in Bricolage Grotesque. Sizes are in logical pixels
/// and scale with the user's text size; colours come from the theme.
abstract final class CestaDisplayType {
  /// A screen's big title, e.g. "Your Lists".
  static const screenTitle = TextStyle(
    fontFamily: CestaFonts.display,
    fontWeight: FontWeight.w800,
    fontSize: 40,
    height: 1,
    letterSpacing: -1.2,
  );

  /// A List's name on its card.
  static const listName = TextStyle(
    fontFamily: CestaFonts.display,
    fontWeight: FontWeight.w800,
    fontSize: 24,
    height: 1.05,
    letterSpacing: -0.48,
  );

  /// The number on a count sign.
  static const count = TextStyle(
    fontFamily: CestaFonts.display,
    fontWeight: FontWeight.w800,
    fontSize: 28,
    height: 1,
    letterSpacing: -0.56,
  );

  /// The "cesta" wordmark.
  static const wordmark = TextStyle(
    fontFamily: CestaFonts.display,
    fontWeight: FontWeight.w800,
    fontSize: 22,
    letterSpacing: -0.44,
  );
}

/// Radii from the design beyond [CestaRadii].
abstract final class CestaShapes {
  static const listCard = 20.0;
  static const sign = 4.0;
  static const pill = 28.0;
}

/// Semantic status colours that follow light/dark mode.
@immutable
class CestaStatusColors extends ThemeExtension<CestaStatusColors> {
  const CestaStatusColors({required this.success, required this.warning});

  static const light = CestaStatusColors(success: CestaColors.success, warning: CestaColors.warning);
  static const dark = CestaStatusColors(success: CestaColors.successDark, warning: CestaColors.warningDark);

  final Color success;
  final Color warning;

  @override
  CestaStatusColors copyWith({Color? success, Color? warning}) =>
      CestaStatusColors(success: success ?? this.success, warning: warning ?? this.warning);

  @override
  CestaStatusColors lerp(CestaStatusColors? other, double t) => other == null
      ? this
      : CestaStatusColors(
          success: Color.lerp(success, other.success, t)!,
          warning: Color.lerp(warning, other.warning, t)!,
        );
}

/// Type scale: Material 3 sizes with Cesta weights. Sizes are in logical
/// pixels and scale with the user's text size setting.
TextTheme cestaTextTheme(TextTheme base) => base.copyWith(
  displaySmall: base.displaySmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5),
  headlineMedium: base.headlineMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.25),
  headlineSmall: base.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
  titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w700),
  titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w600),
  labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w600),
);

extension CestaTokensContext on BuildContext {
  CestaSpacing get spacing => Theme.of(this).extension<CestaSpacing>() ?? const CestaSpacing();
  CestaPalette get palette => Theme.of(this).extension<CestaPalette>() ?? CestaPalette.light;
  CestaStatusColors get statusColors => Theme.of(this).extension<CestaStatusColors>() ?? CestaStatusColors.light;
}
