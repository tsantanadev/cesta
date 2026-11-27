import 'package:material_ui/material_ui.dart';

/// The icons Cesta uses, from Phosphor (phosphoricons.com, MIT). The icon
/// fonts are bundled in assets/fonts/phosphor; codepoints are from Phosphor's
/// font map. Feature code names icons through this class only, so adding an
/// icon means adding its codepoint here.
abstract final class CesIcons {
  static const basket = IconData(0xe964, fontFamily: _fill);
  static const google = IconData(0xe292, fontFamily: _bold);
  static const email = IconData(0xe218, fontFamily: _bold);
  static const user = IconData(0xe4c4, fontFamily: _regular);
  static const edit = IconData(0xe3b4, fontFamily: _regular);
  static const server = IconData(0xe2ac, fontFamily: _regular);
  static const signOut = IconData(0xe42a, fontFamily: _regular);
  static const show = IconData(0xe220, fontFamily: _regular);
  static const hide = IconData(0xe224, fontFamily: _regular);
  static const error = IconData(0xe4e2, fontFamily: _fill);
  static const info = IconData(0xe184, fontFamily: _fill);
  static const positive = IconData(0xe184, fontFamily: _fill);
  static const warning = IconData(0xe4e0, fontFamily: _fill);
  static const offline = IconData(0xe1b6, fontFamily: _regular);
  static const plus = IconData(0xe3d4, fontFamily: _bold);
  static const check = IconData(0xe182, fontFamily: _bold);
  static const more = IconData(0xe1fe, fontFamily: _bold);
  static const close = IconData(0xe4f6, fontFamily: _regular);
  static const delete = IconData(0xe4a6, fontFamily: _regular);
  static const restore = IconData(0xe038, fontFamily: _regular);
  static const recentlyDeleted = IconData(0xe1a0, fontFamily: _regular);

  // Produce, for Item tiles.
  static const orange = IconData(0xee40, fontFamily: _fill);
  static const bread = IconData(0xe81c, fontFamily: _fill);
  static const coffee = IconData(0xe1c2, fontFamily: _fill);
  static const egg = IconData(0xe812, fontFamily: _fill);
  static const cheese = IconData(0xe9fe, fontFamily: _fill);

  static const _regular = 'PhosphorRegular';
  static const _bold = 'PhosphorBold';
  static const _fill = 'PhosphorFill';
}
