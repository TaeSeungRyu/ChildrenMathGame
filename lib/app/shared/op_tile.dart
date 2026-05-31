import 'package:flutter/material.dart';

/// Single operation pick tile (큰 기호 + 한글 라벨, 선택 시 primary 채움).
/// Used by mixed/equation/flash select screens in a 2×2 grid so the picker
/// renders consistently and never wraps unpredictably across screen sizes.
class OpTile extends StatelessWidget {
  const OpTile({
    super.key,
    required this.symbol,
    required this.label,
    required this.selected,
    required this.onTap,
    this.enabled = true,
  });

  final String symbol;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  // When false, the tile is greyed and ignores taps — used by mixed mode to
  // lock the last remaining op so the user can't clear the whole selection.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = selected ? scheme.primary : scheme.surfaceContainerHighest;
    final fg = selected ? scheme.onPrimary : scheme.onSurface;
    return Opacity(
      opacity: enabled ? 1.0 : 0.55,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? scheme.primary : scheme.outlineVariant,
                width: 1,
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  symbol,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: fg,
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: fg,
                    ),
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

/// Lays out four [OpTile]-equivalent children as a 2×2 grid with equal-width
/// columns. Children are placed row-major: `children[0..1]` go in the top row,
/// `children[2..3]` in the bottom row. Use 8-12dp spacing depending on parent.
class OpTileGrid extends StatelessWidget {
  const OpTileGrid({
    super.key,
    required this.children,
    this.spacing = 10,
  }) : assert(children.length == 4, 'OpTileGrid expects exactly 4 tiles');

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: children[0]),
            SizedBox(width: spacing),
            Expanded(child: children[1]),
          ],
        ),
        SizedBox(height: spacing),
        Row(
          children: [
            Expanded(child: children[2]),
            SizedBox(width: spacing),
            Expanded(child: children[3]),
          ],
        ),
      ],
    );
  }
}
