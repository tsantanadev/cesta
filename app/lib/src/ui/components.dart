/// In-house UI components. Feature screens build with these instead of
/// styling raw Material or Cupertino widgets, so the Cesta look (and the
/// iOS-adaptive behaviour) lives in one place.
library;

import 'package:cupertino_ui/cupertino_ui.dart' show CupertinoButton;
import 'package:material_ui/material_ui.dart';

import 'tokens.dart';

bool _isCupertino(BuildContext context) => switch (Theme.of(context).platform) {
  TargetPlatform.iOS || TargetPlatform.macOS => true,
  _ => false,
};

/// Page scaffold with an adaptive app bar (centred title on iOS).
class CesScaffold extends StatelessWidget {
  const CesScaffold({super.key, required this.title, required this.body});

  final String title;
  final Widget body;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title), centerTitle: _isCupertino(context)),
    body: SafeArea(
      child: SingleChildScrollView(padding: EdgeInsets.all(context.spacing.md), child: body),
    ),
  );
}

/// Primary action button: a filled Material button, or a filled Cupertino
/// button on iOS.
class CesButton extends StatelessWidget {
  const CesButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    if (_isCupertino(context)) {
      return CupertinoButton.filled(onPressed: onPressed, child: Text(label));
    }
    return FilledButton(onPressed: onPressed, child: Text(label));
  }
}

/// Indeterminate progress with a label; platform-adaptive spinner.
class CesProgress extends StatelessWidget {
  const CesProgress({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const CircularProgressIndicator.adaptive(),
      SizedBox(width: context.spacing.md),
      Expanded(child: Text(label, style: Theme.of(context).textTheme.bodyLarge)),
    ],
  );
}

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
      CesTone.positive => (Icons.check_circle, context.statusColors.success),
      CesTone.warning => (Icons.warning_amber_rounded, context.statusColors.warning),
      CesTone.neutral => (Icons.cloud_off, theme.colorScheme.onSurfaceVariant),
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

/// Vertical gap from the spacing scale.
class CesGap extends StatelessWidget {
  const CesGap.md({super.key}) : _size = _GapSize.md;
  const CesGap.lg({super.key}) : _size = _GapSize.lg;

  final _GapSize _size;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: switch (_size) {
      _GapSize.md => context.spacing.md,
      _GapSize.lg => context.spacing.lg,
    },
  );
}

enum _GapSize { md, lg }
