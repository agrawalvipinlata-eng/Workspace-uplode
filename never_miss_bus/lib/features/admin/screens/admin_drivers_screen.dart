import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/nmb_colors.dart';
import '../../../core/theme/nmb_typography.dart';
import '../../../core/widgets/nmb_card.dart';
import '../../../core/widgets/responsive_scaffold_body.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../models/app_user.dart';
import '../../../models/bus.dart';
import '../../../providers/data_providers.dart';
import '../widgets/user_editor_sheet.dart';

/// Manage drivers: list, add, assign to bus, enable/disable.
class AdminDriversScreen extends ConsumerWidget {
  const AdminDriversScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<AppUser>> driversAsync =
        ref.watch(allDriversProvider);
    final List<Bus> buses =
        ref.watch(allBusesProvider).valueOrNull ?? const <Bus>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Drivers')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => UserEditorSheet.show(context, role: 'driver'),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add driver'),
      ),
      body: driversAsync.when(
        loading: () => const LoadingView(),
        error: (Object e, _) => ErrorView(
          message: 'Couldn\'t load drivers.',
          onRetry: () => ref.invalidate(allDriversProvider),
        ),
        data: (List<AppUser> drivers) {
          if (drivers.isEmpty) {
            return const EmptyState(
              icon: Icons.badge_outlined,
              title: 'No drivers yet',
              message: 'Add your first driver with the button below.',
            );
          }
          return ResponsiveBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (final AppUser d in drivers) ...<Widget>[
                  _DriverTile(driver: d, buses: buses),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 90),
              ],
            ),
          );
        },
      ),
    );
  }
}

bool _isLoggedIn(AppUser u) {
  final String? id = u.activeDevice?['id'] as String?;
  return id != null && id.isNotEmpty && id != 'REVOKED';
}

class _DriverTile extends StatelessWidget {
  const _DriverTile({required this.driver, required this.buses});

  final AppUser driver;
  final List<Bus> buses;

  @override
  Widget build(BuildContext context) {
    String busLabel = 'No bus assigned';
    for (final Bus b in buses) {
      if (b.id == driver.busId) busLabel = b.busNumber;
    }
    return NmbCard(
      onTap: () => UserManageSheet.show(context, driver),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            backgroundColor: NmbColors.accentSoft,
            child:
                Icon(Icons.badge_rounded, color: NmbColors.accentDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(driver.fullName, style: NmbTypography.cardTitle),
                Text(busLabel, style: NmbTypography.bodySecondary),
              ],
            ),
          ),
          if (!driver.isActive)
            const StatusPill(
              label: 'DISABLED',
              color: NmbColors.danger,
              background: NmbColors.dangerSoft,
            )
          else if (_isLoggedIn(driver))
            const StatusPill(
              label: 'LOGGED IN',
              color: NmbColors.success,
              background: NmbColors.successSoft,
            )
          else
            const StatusPill(
              label: 'NOT LOGGED IN',
              color: NmbColors.textTertiary,
              background: NmbColors.divider,
            ),
          const Icon(Icons.chevron_right_rounded,
              color: NmbColors.textTertiary,),
        ],
      ),
    );
  }
}
