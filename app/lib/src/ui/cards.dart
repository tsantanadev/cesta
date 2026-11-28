import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import 'icons.dart';
import 'scaffolds.dart';
import 'tokens.dart';

enum CesTone { positive, warning, neutral }

/// A card that reports a status: icon, title and supporting lines.
class CesStatusCard extends StatelessWidget {
  const CesStatusCard({super.key, required this.tone, required this.title, this.lines = const [], this.caption});

  final CesTone tone;
  final String title;
  final List<String> lines;

  /// Small heading above the title, e.g. "Last known status".
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = context.spacing;
    final (icon, colour) = switch (tone) {
      CesTone.positive => (CesIcons.positive, context.statusColors.success),
      CesTone.warning => (CesIcons.warning, context.statusColors.warning),
      CesTone.neutral => (CesIcons.offline, theme.colorScheme.onSurfaceVariant),
    };
    return Card(
      child: Padding(
        padding: EdgeInsets.all(spacing.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: colour, size: 32),
            SizedBox(width: spacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (caption != null)
                    Text(
                      caption!,
                      style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  Text(title, style: theme.textTheme.titleMedium),
                  for (final line in lines) ...[
                    SizedBox(height: spacing.xs),
                    Text(line, style: theme.textTheme.bodyMedium),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A card for one List: its [name], a [subtitle], an optional top-right
/// [action] (e.g. the options button, Figma 35:2085) and [trailing] widgets
/// (e.g. a [CesCountSign]). Tapping it runs [onTap] (opens the List).
class CesListCard extends StatelessWidget {
  const CesListCard({
    super.key,
    required this.name,
    required this.subtitle,
    this.action,
    this.trailing = const [],
    this.onTap,
  });

  final String name;
  final String subtitle;
  final Widget? action;
  final List<Widget> trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasAction = action != null;
    final radius = BorderRadius.circular(CestaRadii.listCard);
    return Material(
      color: theme.colorScheme.surfaceContainerLowest,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: hasAction
              ? const EdgeInsets.fromLTRB(20, 12, 12, 16)
              : EdgeInsets.fromLTRB(20, 18, trailing.isEmpty ? context.spacing.md : 12, 18),
          child: Row(
            crossAxisAlignment: hasAction ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(top: hasAction ? 6 : 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: CestaDisplayType.listName.copyWith(color: theme.colorScheme.onSurface)),
                      const SizedBox(height: 6),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (hasAction) ...[
                const SizedBox(width: 12),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [action!, ...trailing],
                ),
              ] else
                for (final w in trailing) ...[SizedBox(width: context.spacing.sm), w],
            ],
          ),
        ),
      ),
    );
  }
}

/// The sign on a List's card: how many Items are still to buy, on Banana,
/// like a price tag; with nothing to buy, a check on the "bought" colour.
class CesCountSign extends StatelessWidget {
  const CesCountSign({super.key, required this.count, required this.caption, required this.nothingLabel});

  final int count;

  /// Under the number, e.g. "to buy".
  final String caption;

  /// Accessible label when [count] is 0.
  final String nothingLabel;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final empty = count == 0;
    final foreground = empty ? palette.onBought : palette.onToBuy;
    return Semantics(
      label: empty ? nothingLabel : '$count $caption',
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minWidth: 60, minHeight: 64),
        padding: const EdgeInsets.fromLTRB(4, 14, 4, 8),
        decoration: BoxDecoration(
          color: empty ? palette.bought : palette.toBuy,
          borderRadius: BorderRadius.circular(CestaRadii.sign),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // The nail hole the sign hangs from.
            Positioned(
              top: -9,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, shape: BoxShape.circle),
              ),
            ),
            if (empty)
              Icon(CesIcons.check, size: 24, color: foreground)
            else
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('$count', style: CestaDisplayType.count.copyWith(color: foreground)),
                  Text(
                    caption,
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 10, color: foreground),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// An Item as a Banana price tag (Figma "Item tile" 3:46): an optional
/// [quantity] on top, the [name] at the bottom, and the hole the tag hangs
/// from. The welcome screen's decorative tags also carry an [icon], with the
/// quantity small beside it. It is drawn at a fixed size, so it doesn't grow
/// with the text size. With [onTap] or [onLongPress] it is a button.
class CesItemTile extends StatelessWidget {
  const CesItemTile({
    super.key,
    required this.name,
    this.icon,
    this.quantity,
    this.size = 112,
    this.onTap,
    this.onLongPress,
    this.semanticHint,
    this.toAdd = false,
  });

  /// An empty white tag (Figma "Item tile" State=Suggestion 3:39, as the empty
  /// List shows it): Branco with a Checked outline and hole.
  const CesItemTile.blank({super.key, this.size = 112})
    : name = '',
      icon = null,
      quantity = null,
      onTap = null,
      onLongPress = null,
      semanticHint = null,
      toAdd = true;

  /// A white tag with an outline (Figma "Item tile" State=Suggestion 3:39):
  /// something to add, such as an entry under Bought before, rather than
  /// an Item on the List.
  final bool toAdd;

  final String name;
  final IconData? icon;
  final String? quantity;
  final double size;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// What tapping does, for screen readers (e.g. "Check").
  final String? semanticHint;

  /// Where the hanging string meets the tile, from its top-left corner.
  static const holeCentre = Offset(56, 10);

  /// The quantity on a List's tag (Figma text 2eywko): Bricolage 24, -2%.
  static const _quantityStyle = TextStyle(
    fontFamily: CestaFonts.display,
    fontWeight: FontWeight.w800,
    fontSize: 24,
    height: 1,
    letterSpacing: -0.48,
  );

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final scheme = Theme.of(context).colorScheme;
    final ink = toAdd ? scheme.onSurface : palette.onToBuy;
    final icon = this.icon;
    final quantity = this.quantity;
    final nameText = Text(
      name,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: CestaDisplayType.itemName.copyWith(color: ink),
    );
    final Widget content = icon == null
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (quantity != null)
                Text(
                  quantity,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _quantityStyle.copyWith(color: ink),
                )
              else
                const SizedBox.shrink(),
              nameText,
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 30, color: ink),
                  if (quantity != null)
                    Flexible(
                      child: Text(
                        quantity,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: CestaFonts.family,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: ink,
                        ),
                      ),
                    ),
                ],
              ),
              nameText,
            ],
          );
    final radius = BorderRadius.circular(CestaRadii.sign);
    final interactive = onTap != null || onLongPress != null;
    final outline = BorderSide(color: palette.bought, width: 1.5);
    Widget tile = Material(
      color: toAdd ? scheme.surfaceContainerLow : palette.toBuy,
      shape: RoundedRectangleBorder(borderRadius: radius, side: toAdd ? outline : BorderSide.none),
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          // The List's tags leave room for the hole above the quantity (Figma 3:32).
          padding: icon == null ? const EdgeInsets.fromLTRB(12, 22, 12, 12) : const EdgeInsets.all(12),
          child: content,
        ),
      ),
    );
    if (interactive) {
      tile = Semantics(
        button: true,
        hint: semanticHint,
        label: [?quantity, name].join(' '),
        excludeSemantics: true,
        child: tile,
      );
    }
    return MediaQuery.withNoTextScaling(
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(child: tile),
            // The hole, in the screen's ground colour.
            Positioned(
              left: holeCentre.dx - 4,
              top: holeCentre.dy - 4,
              child: IgnorePointer(
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: toAdd
                      ? BoxDecoration(border: Border.fromBorderSide(outline), shape: BoxShape.circle)
                      : BoxDecoration(color: scheme.surface, shape: BoxShape.circle),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Where a [CesItemTile] hangs in a [_HangingTiles] canvas: its top-left
/// corner at ([left], [top]), turned [degrees] clockwise about that corner, as
/// Figma positions a rotated layer.
class _HangingTile {
  const _HangingTile({required this.left, required this.top, required this.degrees, required this.tile});

  final double left;
  final double top;
  final double degrees;
  final CesItemTile tile;

  double get _radians => degrees * math.pi / 180;

  /// The tag hole in canvas coordinates.
  Offset get hole {
    final c = CesItemTile.holeCentre;
    return Offset(
      left + c.dx * math.cos(_radians) - c.dy * math.sin(_radians),
      top + c.dx * math.sin(_radians) + c.dy * math.cos(_radians),
    );
  }
}

/// Item tiles hanging on strings from the top of a [canvas]-sized area, the
/// design's decorative hero. The strings are Banana on a [CesBrandScaffold],
/// muted elsewhere. The canvas scales down to fit narrower screens. It is
/// decoration only, so screen readers skip it.
class _HangingTiles extends StatelessWidget {
  const _HangingTiles({required this.canvas, required this.tiles});

  final Size canvas;
  final List<_HangingTile> tiles;

  @override
  Widget build(BuildContext context) {
    final stringColour = CesBrandScaffold.contains(context)
        ? context.palette.toBuy
        : Theme.of(context).colorScheme.onSurfaceVariant;
    return ExcludeSemantics(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox.fromSize(
          size: canvas,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final t in tiles)
                Positioned(
                  left: t.hole.dx - 0.75,
                  top: -8,
                  width: 1.5,
                  height: t.hole.dy + 8,
                  child: ColoredBox(color: stringColour),
                ),
              for (final t in tiles)
                Positioned(
                  left: t.left,
                  top: t.top,
                  child: Transform.rotate(angle: t._radians, alignment: Alignment.topLeft, child: t.tile),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The welcome screen's decorative hero (Figma "01 Welcome"): five sample
/// [CesItemTile]s hanging on strings in the design's 390 × 330 frame.
class CesWelcomeHero extends StatelessWidget {
  const CesWelcomeHero({super.key, required this.tiles});

  final List<CesItemTile> tiles;

  static const _canvas = Size(390, 330);
  static const _slots = [
    (left: 20.0, top: 92.0, degrees: 7.0),
    (left: 142.0, top: 40.0, degrees: -4.0),
    (left: 262.0, top: 104.0, degrees: 4.0),
    (left: 72.0, top: 214.0, degrees: -6.0),
    (left: 204.0, top: 226.0, degrees: 5.0),
  ];

  @override
  Widget build(BuildContext context) {
    assert(tiles.length == _slots.length, 'CesWelcomeHero expects ${_slots.length} tiles');
    return _HangingTiles(
      canvas: _canvas,
      tiles: [
        for (var i = 0; i < tiles.length && i < _slots.length; i++)
          _HangingTile(left: _slots[i].left, top: _slots[i].top, degrees: _slots[i].degrees, tile: tiles[i]),
      ],
    );
  }
}

/// A large Item tile showing [name] under a basket, hanging on a string: the
/// display name screen's preview of the name being typed (Figma 20:624).
class CesNamePreview extends StatelessWidget {
  const CesNamePreview({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) => _HangingTiles(
    canvas: const Size(342, 196),
    tiles: [
      _HangingTile(
        left: 97,
        top: 44,
        degrees: 3,
        tile: CesItemTile(name: name, icon: CesIcons.basket, size: 148),
      ),
    ],
  );
}

/// The New item sheet's preview (Figma "Preview" 9:443): the Item's tag, as
/// it will look on the List, hanging on a string.
class CesItemPreview extends StatelessWidget {
  const CesItemPreview({super.key, required this.name, this.quantity});

  final String name;
  final String? quantity;

  @override
  Widget build(BuildContext context) => _HangingTiles(
    canvas: const Size(350, 138),
    tiles: [
      _HangingTile(
        left: 119,
        top: 22,
        degrees: 3,
        tile: CesItemTile(name: name, quantity: quantity),
      ),
    ],
  );
}

/// A List with no Items (Figma "15 Empty list" 39:3859): an empty tag on its
/// string, a [title] and a [body], centred.
class CesEmptyListState extends StatelessWidget {
  const CesEmptyListState({super.key, required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _HangingTiles(
          canvas: Size(350, 138),
          tiles: [_HangingTile(left: 119, top: 22, degrees: 3, tile: CesItemTile.blank())],
        ),
        const SizedBox(height: 12),
        Semantics(
          header: true,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: CestaFonts.display,
              fontWeight: FontWeight.w800,
              fontSize: 24,
              letterSpacing: -0.48,
              color: scheme.onSurface,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          body,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: CestaFonts.family,
            fontWeight: FontWeight.w500,
            fontSize: 15,
            height: 1.4,
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
