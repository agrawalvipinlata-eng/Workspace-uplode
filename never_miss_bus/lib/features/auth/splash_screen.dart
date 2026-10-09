import 'package:flutter/material.dart';

import '../../core/constants/nmb_constants.dart';
import '../../core/theme/nmb_colors.dart';
import '../../core/theme/nmb_typography.dart';

/// Animated splash: the bus drives in from the left along a road, the
/// app name fades up, loading dots pulse. Router redirects away as soon
/// as the session resolves — so this stays smooth and short.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _drive = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  )..forward();

  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  late final Animation<double> _busX = CurvedAnimation(
    parent: _drive,
    curve: Curves.easeOutCubic,
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _drive,
    curve: const Interval(0.35, 1, curve: Curves.easeOut),
  );

  @override
  void dispose() {
    _drive.dispose();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[NmbColors.primaryDark, NmbColors.primary],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: <Widget>[
              const Spacer(flex: 3),

              // ── Bus drives in on a road ──
              SizedBox(
                height: 130,
                child: AnimatedBuilder(
                  animation: _busX,
                  builder: (BuildContext context, Widget? child) {
                    return Stack(
                      children: <Widget>[
                        // Road
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 18,
                          child: Container(
                            height: 6,
                            color: Colors.white24,
                          ),
                        ),
                        // Dashed centre line
                        Positioned(
                          left: 0,
                          right: 0,
                          bottom: 20,
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceEvenly,
                            children: List<Widget>.generate(
                              8,
                              (_) => Container(
                                width: 22,
                                height: 2.5,
                                color: NmbColors.accent,
                              ),
                            ),
                          ),
                        ),
                        // Bus
                        Positioned(
                          left: -120 + (_busX.value * (w / 2 - 40 + 120)),
                          bottom: 24,
                          child: const _MiniBus(size: 96),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 34),

              // ── Name + tagline fade in ──
              FadeTransition(
                opacity: _fade,
                child: Column(
                  children: <Widget>[
                    Text(
                      'SRBS INTERNATIONAL SCHOOL',
                      style: NmbTypography.displayTitle.copyWith(
                        color: Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Never Miss Bus — Ab bus miss nahi hogi!',
                      style: NmbTypography.body
                          .copyWith(color: NmbColors.accent),
                    ),
                    const SizedBox(height: 10),
                    // 🏫 School emblem
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/school_logo.png',
                          width: 52,
                          height: 52,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const SizedBox.shrink(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      NmbConstants.schoolName,
                      style: NmbTypography.bodySecondary
                          .copyWith(color: Colors.white70),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 2),

              // ── Pulsing loading dots ──
              AnimatedBuilder(
                animation: _pulse,
                builder: (BuildContext context, Widget? child) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List<Widget>.generate(3, (int i) {
                      final double t =
                          (_pulse.value + i * 0.33) % 1.0;
                      return Container(
                        margin:
                            const EdgeInsets.symmetric(horizontal: 5),
                        width: 9 + 4 * (1 - (t - 0.5).abs() * 2),
                        height: 9 + 4 * (1 - (t - 0.5).abs() * 2),
                        decoration: BoxDecoration(
                          color: Colors.white
                              .withOpacity(0.5 + 0.5 * (1 - t)),
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  );
                },
              ),
              const SizedBox(height: 14),
              Text(
                'Getting things ready…',
                style: NmbTypography.caption
                    .copyWith(color: Colors.white60),
              ),
              const SizedBox(height: 36),
            ],
          ),
        ),
      ),
    );
  }
}

/// Small painted school bus (side view) used on the splash road.
class _MiniBus extends StatelessWidget {
  const _MiniBus({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 0.55,
      child: CustomPaint(painter: _MiniBusPainter()),
    );
  }
}

class _MiniBusPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size s) {
    final double w = s.width;
    final double h = s.height;

    // Body
    final RRect body = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, h * 0.05, w, h * 0.66),
      Radius.circular(h * 0.16),
    );
    canvas.drawRRect(body, Paint()..color = NmbColors.accent);

    // Windows
    final Paint win = Paint()..color = const Color(0xFFE3F2FD);
    final double winW = w * 0.16;
    for (int i = 0; i < 4; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            w * 0.06 + i * (winW + w * 0.045),
            h * 0.14,
            winW,
            h * 0.26,
          ),
          Radius.circular(h * 0.05),
        ),
        win,
      );
    }

    // Stripe
    canvas.drawRect(
      Rect.fromLTWH(0, h * 0.5, w, h * 0.06),
      Paint()..color = Colors.white,
    );

    // Wheels
    final Paint wheel = Paint()..color = const Color(0xFF263238);
    final Paint hub = Paint()..color = Colors.white;
    for (final double cx in <double>[w * 0.22, w * 0.78]) {
      canvas.drawCircle(Offset(cx, h * 0.8), h * 0.17, wheel);
      canvas.drawCircle(Offset(cx, h * 0.8), h * 0.07, hub);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
