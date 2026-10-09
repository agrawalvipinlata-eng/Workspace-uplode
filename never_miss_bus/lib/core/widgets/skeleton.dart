import 'package:flutter/material.dart';

import '../theme/nmb_colors.dart';

/// YouTube-style shimmer skeleton loading.
///
/// Instead of a blank screen or a spinner, screens show grey placeholder
/// shapes that shimmer until real data arrives — the app feels fast and
/// alive from the first frame.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (BuildContext context, Widget? child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (Rect bounds) {
            final double slide = _controller.value * 2.4 - 1.2;
            return LinearGradient(
              begin: Alignment(-1 + slide, -0.2),
              end: Alignment(0.2 + slide, 0.2),
              colors: const <Color>[
                Color(0xFFE4E9F2),
                Color(0xFFF5F7FB),
                Color(0xFFE4E9F2),
              ],
              stops: const <double>[0.25, 0.5, 0.75],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// A single grey placeholder block.
class Bone extends StatelessWidget {
  const Bone({
    super.key,
    this.width,
    this.height = 14,
    this.radius = 8,
    this.circle = false,
  });

  final double? width;
  final double height;
  final double radius;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: circle ? height : width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFFE4E9F2),
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(radius),
      ),
    );
  }
}

/// Ready-made skeleton for the student home screen (matches its layout:
/// header, bus card, banner, quick actions, list items).
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: <Widget>[
            // Header block
            Container(
              height: 190,
              decoration: const BoxDecoration(
                color: Color(0xFFE4E9F2),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
              child: const Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Bone(width: 120, height: 14),
                        SizedBox(height: 10),
                        Bone(width: 180, height: 24),
                        SizedBox(height: 8),
                        Bone(width: 150, height: 12),
                      ],
                    ),
                  ),
                  Bone(height: 64, circle: true),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: <Widget>[
                  _cardBone(height: 92),
                  const SizedBox(height: 14),
                  _cardBone(height: 84),
                  const SizedBox(height: 20),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Column(children: <Widget>[
                        Bone(height: 54, circle: true),
                        SizedBox(height: 8),
                        Bone(width: 52, height: 10),
                      ],),
                      Column(children: <Widget>[
                        Bone(height: 54, circle: true),
                        SizedBox(height: 8),
                        Bone(width: 52, height: 10),
                      ],),
                      Column(children: <Widget>[
                        Bone(height: 54, circle: true),
                        SizedBox(height: 8),
                        Bone(width: 52, height: 10),
                      ],),
                      Column(children: <Widget>[
                        Bone(height: 54, circle: true),
                        SizedBox(height: 8),
                        Bone(width: 52, height: 10),
                      ],),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _cardBone(height: 110),
                  const SizedBox(height: 14),
                  _cardBone(height: 130),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cardBone({required double height}) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE4E9F2),
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }
}

/// Generic list skeleton (alerts, students, trips…).
class ListSkeleton extends StatelessWidget {
  const ListSkeleton({super.key, this.items = 6});

  final int items;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        itemCount: items,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: NmbColors.divider),
          ),
          child: const Row(
            children: <Widget>[
              Bone(height: 44, circle: true),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Bone(width: 160, height: 14),
                    SizedBox(height: 8),
                    Bone(width: 220, height: 11),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
