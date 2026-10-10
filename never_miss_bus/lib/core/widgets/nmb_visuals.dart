import 'package:flutter/material.dart';
import '../theme/app_theme_manager.dart';
import '../theme/nmb_colors.dart';
import '../theme/nmb_typography.dart';

class NmbGradientHeader extends StatelessWidget {
  const NmbGradientHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.auto_awesome_rounded,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 16, 20),
      decoration: BoxDecoration(
        gradient: themeGradient(),
        borderRadius: BorderRadius.circular(24),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: themePrimaryDark().withOpacity(0.22),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: Colors.white, size: 25),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 4),
                  Text(subtitle!,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.78),
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ],
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class NmbMetricTile extends StatelessWidget {
  const NmbMetricTile({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color tone = color ?? NmbColors.primary;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: tone.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: tone.withOpacity(0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: tone, size: 22),
            const SizedBox(height: 10),
            Text(value,
                style: NmbTypography.statLarge
                    .copyWith(fontSize: 24, color: tone)),
            const SizedBox(height: 2),
            Text(label, style: NmbTypography.caption),
          ],
        ),
      ),
    );
  }
}

class NmbStatusPill extends StatelessWidget {
  const NmbStatusPill({super.key, required this.label, this.color});
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final Color tone = color ?? NmbColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: tone.withOpacity(0.11),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(label,
          style: TextStyle(
              color: tone, fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }
}
