import 'dart:math' as math;

import 'package:flutter/services.dart' show SystemUiOverlayStyle;
import 'package:material_ui/material_ui.dart';

import 'icons.dart';
import 'platform.dart';
import 'tokens.dart';

/// Page scaffold with an adaptive app bar (centred title on iOS). The body
/// scrolls, so it stays usable at large text sizes.
class CesScaffold extends StatelessWidget {
  const CesScaffold({super.key, required this.title, required this.body, this.actions = const []}) : _appBar = true;

  /// A page without an app bar, e.g. the welcome screen.
  const CesScaffold.bare({super.key, required this.body}) : title = '', actions = const [], _appBar = false;

  final String title;
  final Widget body;
  final List<Widget> actions;
  final bool _appBar;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: _appBar ? AppBar(title: Text(title), centerTitle: isCupertino(context), actions: actions) : null,
    body: SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: EdgeInsets.all(context.spacing.lg),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: math.max(0.0, constraints.maxHeight - 2 * context.spacing.lg)),
            child: Center(
              child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 480), child: body),
            ),
          ),
        ),
      ),
    ),
  );
}

/// A form page in the design's layout (Figma "02 Your name"): [top] from the
/// top, [bottom] (the form's actions) at the bottom of the screen, with an
/// app bar only when there is a [title].
class CesFormScaffold extends StatelessWidget {
  const CesFormScaffold({super.key, this.title, required this.top, required this.bottom});

  final String? title;
  final List<Widget> top;
  final List<Widget> bottom;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: title == null ? null : AppBar(title: Text(title!), centerTitle: isCupertino(context)),
    body: SafeArea(
      minimum: const EdgeInsets.only(bottom: 34),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: CesPinnedLayout(padding: const EdgeInsets.fromLTRB(24, 8, 24, 0), top: top, bottom: bottom),
        ),
      ),
    ),
  );
}

/// The home page layout from the design: the wordmark and [actions] on top,
/// a big [title], then [items] as a column of cards, or [empty] when there
/// are none. [floatingAction] floats bottom-right, e.g. a [CesFab].
class CesHomeScaffold extends StatelessWidget {
  const CesHomeScaffold({
    super.key,
    required this.brand,
    required this.title,
    required this.items,
    required this.empty,
    this.actions = const [],
    this.floatingAction,
  });

  /// The app's name, shown as the wordmark.
  final String brand;
  final String title;
  final List<Widget> items;
  final Widget empty;
  final List<Widget> actions;
  final Widget? floatingAction;

  // Gaps from the design that sit off the 4 dp scale.
  static const _gutter = 20.0;
  static const _cardGap = 10.0;
  static const _fabClearance = 96.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = context.spacing;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Scaffold(
      floatingActionButton: floatingAction,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(_gutter, spacing.sm, spacing.sm, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: CesWordmark(name: brand),
                        ),
                      ),
                      ...actions,
                    ],
                  ),
                ),
                Expanded(
                  child: CustomScrollView(
                    // Only scroll when content exceeds the viewport, without
                    // pulling the whole screen down at the top.
                    physics: const ClampingScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(_gutter, spacing.lg, _gutter, _gutter),
                        sliver: SliverToBoxAdapter(
                          child: Semantics(
                            header: true,
                            child: Text(
                              title,
                              style: CestaDisplayType.screenTitle.copyWith(color: theme.colorScheme.onSurface),
                            ),
                          ),
                        ),
                      ),
                      if (items.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(spacing.lg, 0, spacing.lg, _fabClearance + bottomInset),
                            child: Center(child: empty),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: EdgeInsets.fromLTRB(spacing.md, 0, spacing.md, _fabClearance + bottomInset),
                          sliver: SliverList.separated(
                            itemCount: items.length,
                            itemBuilder: (_, i) => items[i],
                            separatorBuilder: (_, _) => const SizedBox(height: _cardGap),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The Cesta wordmark: the basket and the name in Bricolage. On a
/// [CesBrandScaffold] the basket is Banana and the name on-brand; elsewhere
/// both are Folha. [large] is the welcome screen's size.
class CesWordmark extends StatelessWidget {
  const CesWordmark({super.key, required this.name, this.large = false});

  final String name;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final onBrand = CesBrandScaffold.contains(context);
    final primary = Theme.of(context).colorScheme.primary;
    final iconColour = onBrand ? context.palette.toBuy : primary;
    final textColour = onBrand ? context.palette.onBrand : primary;
    final style = large ? CestaDisplayType.wordmarkLarge : CestaDisplayType.wordmark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(CesIcons.basket, size: large ? 26 : 22, color: iconColour),
        SizedBox(width: large ? 8 : 6),
        Flexible(
          child: Text(name.toLowerCase(), style: style.copyWith(color: textColour)),
        ),
      ],
    );
  }
}

/// A round avatar with [initials] that acts as a button, e.g. the User menu.
class CesAvatarButton extends StatelessWidget {
  const CesAvatarButton({super.key, required this.initials, required this.tooltip, required this.onPressed});

  final String initials;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Container(
        width: 32,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: palette.toBuy,
          shape: BoxShape.circle,
          border: Border.all(color: Theme.of(context).colorScheme.surfaceContainerLowest, width: 2),
        ),
        child: Text(
          initials,
          textScaler: TextScaler.noScaling,
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: palette.onToBuy),
        ),
      ),
    );
  }
}

/// What a screen shows when it has nothing to list yet.
class CesEmptyState extends StatelessWidget {
  const CesEmptyState({super.key, required this.icon, required this.title, required this.body});

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 72, color: theme.colorScheme.primary),
        SizedBox(height: context.spacing.md),
        Text(title, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
        SizedBox(height: context.spacing.sm),
        Text(
          body,
          style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// A full-bleed page on the brand surface (Figma "01 Welcome"): a [hero]
/// from the top, an [intro] under it and the [actions] at the bottom of the
/// screen. Light status bar icons; components inside it ([CesButton.outline],
/// [CesWordmark], [CesDisplayHeading], [CesText.intro]) switch to their
/// on-brand colours.
class CesBrandScaffold extends StatelessWidget {
  const CesBrandScaffold({super.key, required this.hero, required this.intro, required this.actions});

  final Widget hero;
  final List<Widget> intro;
  final List<Widget> actions;

  // The design's insets, off the 4 dp scale's named steps.
  static const _introPadding = EdgeInsets.fromLTRB(28, 20, 28, 0);
  static const _actionsPadding = EdgeInsets.fromLTRB(24, 16, 24, 0);
  static const _actionGap = 12.0;

  /// Whether [context] is inside a [CesBrandScaffold].
  static bool contains(BuildContext context) => context.dependOnInheritedWidgetOfExactType<_OnBrand>() != null;

  @override
  Widget build(BuildContext context) => AnnotatedRegion<SystemUiOverlayStyle>(
    value: SystemUiOverlayStyle.light,
    child: Scaffold(
      backgroundColor: context.palette.brandSurface,
      body: _OnBrand(
        child: DefaultTextStyle.merge(
          style: TextStyle(color: context.palette.onBrand),
          child: SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: 40),
            child: CesPinnedLayout(
              top: [
                hero,
                Padding(
                  padding: _introPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final (i, w) in intro.indexed) ...[if (i > 0) SizedBox(height: context.spacing.md), w],
                    ],
                  ),
                ),
              ],
              bottom: [
                Padding(
                  padding: _actionsPadding,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final (i, w) in actions.indexed) ...[if (i > 0) const SizedBox(height: _actionGap), w],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

class _OnBrand extends InheritedWidget {
  const _OnBrand({required super.child});

  @override
  bool updateShouldNotify(_OnBrand oldWidget) => false;
}

/// A page whose [top] content starts at the top and whose [bottom] actions sit
/// at the bottom of the screen, as in the design's forms. When the content is
/// taller than the screen (e.g. at large text sizes) the whole page scrolls.
class CesPinnedLayout extends StatelessWidget {
  const CesPinnedLayout({super.key, required this.top, required this.bottom, this.padding = EdgeInsets.zero});

  final List<Widget> top;
  final List<Widget> bottom;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: constraints.maxHeight),
        child: IntrinsicHeight(
          child: Padding(
            padding: padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [...top, const Spacer(), ...bottom],
            ),
          ),
        ),
      ),
    ),
  );
}
