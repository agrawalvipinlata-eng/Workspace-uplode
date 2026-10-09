import 'package:flutter/material.dart';
import '../theme/nmb_colors.dart';
import '../theme/nmb_theme.dart';

/// Rounded card with a soft shadow — the base surface of the design system.
class NmbCard extends StatelessWidget {
  const NmbCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color = NmbColors.surface,
    this.onTap,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final VoidCallback? onTap;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final Widget card = Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(NmbTheme.radiusCard),
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 1.2)
            : null,
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0D17233B),
            blurRadius: 18,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(NmbTheme.radiusCard),
        child: card,
      ),
    );
  }
}
