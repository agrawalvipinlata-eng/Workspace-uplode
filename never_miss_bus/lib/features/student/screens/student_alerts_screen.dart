import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/enums.dart';
import '../../../core/theme/nmb_colors.dart';
import '../../../core/theme/nmb_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/nmb_card.dart';
import '../../../core/widgets/responsive_scaffold_body.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/app_notification.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';
import '../../../services/auth_service.dart';

/// Notification inbox. Items are fanned out server-side per user, so this
/// list can only ever contain notifications addressed to this student.
class StudentAlertsScreen extends ConsumerWidget {
  const StudentAlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<AppNotification>> inboxAsync =
        ref.watch(inboxProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Alerts')),
      body: inboxAsync.when(
        loading: () => const ListSkeleton(),
        error: (Object e, _) => ErrorView(
          message: 'Couldn\'t load alerts.',
          onRetry: () => ref.invalidate(inboxProvider),
        ),
        data: (List<AppNotification> items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'No alerts yet',
              message: 'Bus updates and school announcements will '
                  'appear here.',
            );
          }
          return ResponsiveBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (final AppNotification n in items) ...<Widget>[
                  _AlertTile(notification: n),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AlertTile extends ConsumerWidget {
  const _AlertTile({required this.notification});

  final AppNotification notification;

  (IconData, Color, Color) get _style => switch (notification.type) {
        NotificationType.tripStarted => (
            Icons.play_circle_rounded,
            NmbColors.success,
            NmbColors.successSoft
          ),
        NotificationType.busApproaching => (
            Icons.near_me_rounded,
            NmbColors.primary,
            NmbColors.primarySoft
          ),
        NotificationType.busReachedStop => (
            Icons.pin_drop_rounded,
            NmbColors.accentDark,
            NmbColors.accentSoft
          ),
        NotificationType.busReachedSchool => (
            Icons.school_rounded,
            NmbColors.info,
            NmbColors.infoSoft
          ),
        NotificationType.busDelayed => (
            Icons.schedule_rounded,
            NmbColors.warning,
            NmbColors.warningSoft
          ),
        NotificationType.trackingUnavailable => (
            Icons.location_off_rounded,
            NmbColors.textTertiary,
            NmbColors.divider
          ),
        NotificationType.announcement => (
            Icons.campaign_rounded,
            NmbColors.primary,
            NmbColors.primarySoft
          ),
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (IconData icon, Color color, Color bg) = _style;
    final AuthSession? session = ref.watch(currentSessionProvider);

    return NmbCard(
      onTap: notification.read || session == null
          ? null
          : () => ref
              .read(firestoreServiceProvider)
              .markInboxRead(session.uid, notification.id),
      borderColor:
          notification.read ? null : NmbColors.primary.withOpacity(0.35),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        notification.title,
                        style: NmbTypography.cardTitle.copyWith(
                          fontWeight: notification.read
                              ? FontWeight.w500
                              : FontWeight.w700,
                        ),
                      ),
                    ),
                    if (!notification.read)
                      Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: NmbColors.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(notification.body, style: NmbTypography.bodySecondary),
                const SizedBox(height: 6),
                Text(
                  Formatters.relativeTime(notification.receivedAt),
                  style: NmbTypography.caption,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
