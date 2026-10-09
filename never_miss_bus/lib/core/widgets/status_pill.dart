import 'package:flutter/material.dart';
import '../constants/enums.dart';
import '../theme/nmb_colors.dart';
import '../theme/nmb_typography.dart';

/// Small colored capsule used for every status in the app (bus status,
/// tracking status, account status …) so states always look consistent.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    required this.background,
    this.pulse = false,
  });

  final String label;
  final Color color;
  final Color background;

  /// Shows an animated dot for genuinely-live states only.
  final bool pulse;

  factory StatusPill.freshness(LocationFreshness f) {
    switch (f) {
      case LocationFreshness.live:
        return const StatusPill(
          label: 'LIVE',
          color: NmbColors.live,
          background: NmbColors.successSoft,
          pulse: true,
        );
      case LocationFreshness.stale:
        return const StatusPill(
          label: 'DELAYED SIGNAL',
          color: NmbColors.stale,
          background: NmbColors.warningSoft,
        );
      case LocationFreshness.unavailable:
        return const StatusPill(
          label: 'NOT TRACKING',
          color: NmbColors.offline,
          background: NmbColors.divider,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (pulse) ...<Widget>[
            _PulsingDot(color: color),
            const SizedBox(width: 6),
          ] else ...<Widget>[
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: NmbTypography.caption.copyWith(
              color: color,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  const _PulsingDot({required this.color});
  final Color color;

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      ),
      child: Container(
        width: 8,
        height: 8,
        decoration:
            BoxDecoration(color: widget.color, shape: BoxShape.circle),
      ),
    );
  }
}
