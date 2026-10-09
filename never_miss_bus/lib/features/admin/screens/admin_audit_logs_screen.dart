import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/nmb_colors.dart';
import '../../../core/theme/nmb_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/nmb_card.dart';
import '../../../core/widgets/responsive_scaffold_body.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/audit_log.dart';
import '../../../providers/data_providers.dart';

/// Read-only audit trail. Entries are written exclusively by Cloud
/// Functions — neither admins nor anyone else can edit or delete them
/// from the client.
class AdminAuditLogsScreen extends ConsumerWidget {
  const AdminAuditLogsScreen({super.key});

  static const Map<String, IconData> _icons = <String, IconData>{
    'USER_PROVISIONED': Icons.person_add_alt_1_rounded,
    'STUDENT_BUS_REASSIGNED': Icons.swap_horiz_rounded,
    'DRIVER_BUS_REASSIGNED': Icons.swap_horiz_rounded,
    'ACCOUNT_DISABLED': Icons.block_rounded,
    'ACCOUNT_ENABLED': Icons.check_circle_outline_rounded,
    'TRIP_STARTED': Icons.play_circle_outline_rounded,
    'TRIP_ENDED': Icons.stop_circle_outlined,
    'TRIP_AUTO_CLOSED': Icons.timer_off_outlined,
    'ANNOUNCEMENT_SENT': Icons.campaign_rounded,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<AuditLog>> logsAsync = ref.watch(auditLogsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Activity Logs')),
      body: logsAsync.when(
        loading: () => const LoadingView(),
        error: (Object e, _) => ErrorView(
          message: 'Couldn\'t load activity logs.',
          onRetry: () => ref.invalidate(auditLogsProvider),
        ),
        data: (List<AuditLog> logs) {
          if (logs.isEmpty) {
            return const EmptyState(
              icon: Icons.receipt_long_outlined,
              title: 'No activity yet',
              message: 'Administrative actions and trip events will be '
                  'recorded here.',
            );
          }
          return ResponsiveBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (final AuditLog log in logs) ...<Widget>[
                  NmbCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Icon(
                          _icons[log.action] ?? Icons.info_outline_rounded,
                          size: 22,
                          color: NmbColors.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                log.action.replaceAll('_', ' '),
                                style: NmbTypography.cardTitle,
                              ),
                              Text(
                                '${log.targetType} ${log.targetId}'
                                '${log.details.isEmpty ? '' : ' • ${log.details}'}',
                                style: NmbTypography.bodySecondary,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'by ${log.actorRole} • '
                                '${Formatters.dateTime(log.at)}',
                                style: NmbTypography.caption,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
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
