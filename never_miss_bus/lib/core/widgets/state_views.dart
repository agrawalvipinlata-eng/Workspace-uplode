import 'package:flutter/material.dart';
import '../theme/nmb_colors.dart';
import '../theme/nmb_typography.dart';

/// Full-area BRANDED loading — animated bus jo halka bounce karti hai
/// + theme-colored spinner. Har screen pe same premium feel.
class LoadingView extends StatefulWidget {
  const LoadingView({super.key, this.message});
  final String? message;

  @override
  State<LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<LoadingView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            width: 84,
            height: 84,
            child: Stack(
              alignment: Alignment.center,
              children: <Widget>[
                SizedBox(
                  width: 84,
                  height: 84,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: NmbColors.primary.withOpacity(0.85),
                    backgroundColor: NmbColors.divider,
                  ),
                ),
                AnimatedBuilder(
                  animation: _c,
                  builder: (BuildContext ctx, Widget? child) {
                    return Transform.translate(
                      offset: Offset(0, -3 * _c.value),
                      child: child,
                    );
                  },
                  child: Icon(
                    Icons.directions_bus_rounded,
                    size: 36,
                    color: NmbColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            widget.message ?? 'Loading…',
            style: NmbTypography.bodySecondary,
          ),
        ],
      ),
    );
  }
}

/// Friendly empty state with icon, title, message and optional action.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: NmbColors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 42, color: NmbColors.primary),
            ),
            const SizedBox(height: 18),
            Text(title,
                style: NmbTypography.sectionTitle,
                textAlign: TextAlign.center,),
            const SizedBox(height: 8),
            Text(message,
                style: NmbTypography.bodySecondary,
                textAlign: TextAlign.center,),
            if (actionLabel != null && onAction != null) ...<Widget>[
              const SizedBox(height: 20),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Error state with retry — used for network/database failures.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    this.title = 'Something went wrong',
    required this.message,
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.cloud_off_rounded,
      title: title,
      message: message,
      actionLabel: onRetry != null ? 'Try again' : null,
      onAction: onRetry,
    );
  }
}

/// Banner shown when the device is offline.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: NmbColors.warningSoft,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: <Widget>[
              const Icon(Icons.wifi_off_rounded,
                  size: 18, color: NmbColors.warning,),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'You\'re offline. Information may not be up to date.',
                  style: NmbTypography.caption
                      .copyWith(color: NmbColors.warning),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
