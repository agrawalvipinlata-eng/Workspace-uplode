import 'package:flutter/material.dart';
import '../constants/nmb_constants.dart';

/// Constrains content width on large screens and applies standard padding —
/// keeps layouts responsive without hard-coded dimensions in screens.
class ResponsiveBody extends StatelessWidget {
  const ResponsiveBody({
    super.key,
    required this.child,
    this.scrollable = true,
    this.padding,
  });

  final Widget child;
  final bool scrollable;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final Widget constrained = Center(
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(maxWidth: NmbConstants.maxContentWidth),
        child: Padding(
          padding: padding ??
              const EdgeInsets.symmetric(
                horizontal: NmbConstants.screenPadding,
                vertical: 12,
              ),
          child: child,
        ),
      ),
    );

    if (!scrollable) return SafeArea(child: constrained);
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: constrained,
      ),
    );
  }
}
