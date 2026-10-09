import 'package:flutter/material.dart';

import '../../core/theme/nmb_colors.dart';

/// School-bus map marker as a plain Flutter widget (flutter_map renders
/// widgets directly — no bitmap pipeline needed).
///
/// Amber rounded bus with windows and wheels on a white circular badge,
/// matching the app's design system.
class BusMarkerWidget extends StatelessWidget {
  const BusMarkerWidget({super.key, this.size = 56});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Color(0x40000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: SizedBox(
          width: size * 0.62,
          height: size * 0.52,
          child: CustomPaint(painter: _BusPainter()),
        ),
      ),
    );
  }
}

class _BusPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final double w = s.width;
    final double h = s.height;

    // Body
    final RRect body = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, h * 0.08, w, h * 0.64),
      Radius.circular(w * 0.14),
    );
    canvas.drawRRect(body, Paint()..color = NmbColors.accent);

    // Windows
    final Paint windowPaint = Paint()..color = const Color(0xFFE3F2FD);
    final double winW = w * 0.20;
    final double winH = h * 0.22;
    for (int i = 0; i < 3; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            w * 0.08 + i * (winW + w * 0.06),
            h * 0.18,
            winW,
            winH,
          ),
          Radius.circular(w * 0.04),
        ),
        windowPaint,
      );
    }

    // Stripe
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.50, w, h * 0.05),
      Paint()..color = Colors.white,
    );

    // Wheels
    final Paint wheelPaint = Paint()..color = const Color(0xFF37474F);
    canvas.drawCircle(Offset(w * 0.24, h * 0.82), h * 0.14, wheelPaint);
    canvas.drawCircle(Offset(w * 0.76, h * 0.82), h * 0.14, wheelPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
