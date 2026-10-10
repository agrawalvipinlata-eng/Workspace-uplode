import 'package:flutter/material.dart';
import '../constants/nmb_constants.dart';

/// Constrains content width on large screens and applies standard padding.
/// Non-scrollable mode deliberately fills the viewport so child ListViews and
/// Expanded widgets receive finite Android phone constraints.
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
    final Widget padded = Padding(
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: NmbConstants.screenPadding,
            vertical: 12,
          ),
      child: child,
    );
    final Widget content = Center(
      child: ConstrainedBox(
        constraints:
            const BoxConstraints(maxWidth: NmbConstants.maxContentWidth),
        child: scrollable
            ? padded
            : SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: padded,
              ),
      ),
    );

    if (!scrollable) return SafeArea(child: content);
    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: content,
      ),
    );
  }
}
