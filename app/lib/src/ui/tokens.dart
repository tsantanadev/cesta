import 'package:material_ui/material_ui.dart';

/// Cesta design tokens. Feature code never uses raw colours, sizes or
/// font styles; it reads them through the theme (see `CestaTheme`) and the
/// in-house components in `components.dart`.
abstract final class CestaColors {
  /// Brand seed: a fresh-produce green.
  static const seed = Color(0xFF2F7D4F);

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
  static const sheet = 24.0;
}

/// The bundled typeface (assets/fonts, declared in pubspec.yaml).
abstract final class CestaFonts {
  static const family = 'PlusJakartaSans';
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
  CestaStatusColors get statusColors => Theme.of(this).extension<CestaStatusColors>() ?? CestaStatusColors.light;
}
