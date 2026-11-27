import 'package:material_ui/material_ui.dart';

/// Cesta design tokens. Feature code never uses raw colours, sizes or
/// font styles; it reads them through the theme (see `CestaTheme`) and the
/// in-house components in `components.dart`.
abstract final class CestaColors {
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

  /// The welcome screen's full-bleed ground (Figma "brand-surface"); Folha in light mode.
  static const brandSurface = folha;

  /// Text and outlines on [brandSurface], in both modes (Figma "on-brand").
  static const onBrand = Color(0xFFFFFFFF);

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
  static const brandSurfaceDark = Color(0xFF123A26);

  /// The Toast's ground: deep Tinta in both modes (Figma "on-banana").
  static const toast = Color(0xFF17382A);

  /// Text on the Toast, in both modes.
  static const onToast = onBrand;

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
  static const listCard = 20.0;
  static const sign = 4.0;

  /// Buttons are pills (Figma Button 3:61: 56 dp tall, radius 28). Large
  /// enough to stay a pill when a button grows with the text size.
  static const button = 999.0;
  static const field = 12.0;
  static const sheet = 28.0;
}

/// Shared pill-button geometry and label style (Figma Button 3:61), used by
/// the Material button themes and by Cupertino-adapted buttons.
abstract final class CestaButtonMetrics {
  static const height = 56.0;
  static const horizontalPadding = 24.0;
  static const iconGap = 10.0;
  static const borderWidth = 1.5;
  static const shape = StadiumBorder();
  static const labelStyle = TextStyle(fontFamily: CestaFonts.family, fontWeight: FontWeight.w700, fontSize: 16);
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
  const CestaPalette({
    required this.toBuy,
    required this.onToBuy,
    required this.bought,
    required this.onBought,
    required this.brandSurface,
    required this.onBrand,
  });

  static const light = CestaPalette(
    toBuy: CestaColors.banana,
    onToBuy: CestaColors.onBanana,
    bought: CestaColors.checked,
    onBought: CestaColors.folha,
    brandSurface: CestaColors.brandSurface,
    onBrand: CestaColors.onBrand,
  );
  static const dark = CestaPalette(
    toBuy: CestaColors.bananaDark,
    onToBuy: CestaColors.onBanana,
    bought: CestaColors.checkedDark,
    onBought: CestaColors.folhaDark,
    brandSurface: CestaColors.brandSurfaceDark,
    onBrand: CestaColors.onBrand,
  );

  /// The sign that counts Items still to buy (Banana).
  final Color toBuy;
  final Color onToBuy;

  /// The sign of a List with nothing left to buy (Checked).
  final Color bought;
  final Color onBought;

  /// The welcome screen's ground, and what goes on it.
  final Color brandSurface;
  final Color onBrand;

  @override
  CestaPalette copyWith({
    Color? toBuy,
    Color? onToBuy,
    Color? bought,
    Color? onBought,
    Color? brandSurface,
    Color? onBrand,
  }) => CestaPalette(
    toBuy: toBuy ?? this.toBuy,
    onToBuy: onToBuy ?? this.onToBuy,
    bought: bought ?? this.bought,
    onBought: onBought ?? this.onBought,
    brandSurface: brandSurface ?? this.brandSurface,
    onBrand: onBrand ?? this.onBrand,
  );

  @override
  CestaPalette lerp(CestaPalette? other, double t) => other == null
      ? this
      : CestaPalette(
          toBuy: Color.lerp(toBuy, other.toBuy, t)!,
          onToBuy: Color.lerp(onToBuy, other.onToBuy, t)!,
          bought: Color.lerp(bought, other.bought, t)!,
          onBought: Color.lerp(onBought, other.onBought, t)!,
          brandSurface: Color.lerp(brandSurface, other.brandSurface, t)!,
          onBrand: Color.lerp(onBrand, other.onBrand, t)!,
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

  /// The larger wordmark on the welcome screen.
  static const wordmarkLarge = TextStyle(
    fontFamily: CestaFonts.display,
    fontWeight: FontWeight.w800,
    fontSize: 26,
    letterSpacing: -0.52,
  );

  /// The welcome screen's headline.
  static const headline = TextStyle(
    fontFamily: CestaFonts.display,
    fontWeight: FontWeight.w800,
    fontSize: 40,
    height: 0.98,
    letterSpacing: -1.2,
  );

  /// A form screen's heading, e.g. "What should we call you?".
  static const heading = TextStyle(
    fontFamily: CestaFonts.display,
    fontWeight: FontWeight.w800,
    fontSize: 36,
    height: 1.02,
    letterSpacing: -0.72,
  );

  /// The value of a display field, e.g. the display name being typed.
  static const fieldValue = TextStyle(
    fontFamily: CestaFonts.display,
    fontWeight: FontWeight.w800,
    fontSize: 30,
    height: 1.1,
    letterSpacing: -0.6,
  );

  /// An Item's name on its tile.
  static const itemName = TextStyle(
    fontFamily: CestaFonts.display,
    fontWeight: FontWeight.w800,
    fontSize: 16.5,
    height: 1,
    letterSpacing: -0.165,
  );
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
