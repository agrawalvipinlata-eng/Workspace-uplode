import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/nmb_constants.dart';
import '../../../core/theme/app_theme_manager.dart';
import '../../../core/theme/nmb_colors.dart';
import '../../../core/theme/nmb_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/nmb_card.dart';
import '../../../core/widgets/responsive_scaffold_body.dart';
import '../../../models/app_user.dart';
import '../../../models/audit_log.dart';
import '../../../models/bus.dart';
import '../../../models/trip.dart';
import '../../../providers/data_providers.dart';

/// v1.1.1 Admin Dashboard — design-mock style: greeting + date chip,
/// 4 colored stat cards, live-monitoring banner, quick actions,
/// recent activity and active trips lists.
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<AppUser> students =
        ref.watch(allStudentsProvider).valueOrNull ?? const <AppUser>[];
    final List<AppUser> drivers =
        ref.watch(allDriversProvider).valueOrNull ?? const <AppUser>[];
    final List<Bus> buses =
        ref.watch(allBusesProvider).valueOrNull ?? const <Bus>[];
    final List<Trip> activeTrips =
        ref.watch(activeTripsProvider).valueOrNull ?? const <Trip>[];
    final List<AuditLog> logs =
        ref.watch(auditLogsProvider).valueOrNull ?? const <AuditLog>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      body: ResponsiveBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // ── Greeting + date ──
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '${_greetPart()}, Admin 👋',
                        style: NmbTypography.displayTitle,
                      ),
                      const Text(
                        NmbConstants.schoolName,
                        style: NmbTypography.bodySecondary,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10,),
                  decoration: BoxDecoration(
                    color: NmbColors.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: NmbColors.divider),
                  ),
                  child: Column(
                    children: <Widget>[
                      Text(
                        DateFormat('d MMM yyyy').format(DateTime.now()),
                        style: NmbTypography.cardTitle,
                      ),
                      Text(
                        DateFormat('EEEE').format(DateTime.now()),
                        style: NmbTypography.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ── 4 stat cards ──
            Row(
              children: <Widget>[
                Expanded(
                  child: _StatCard(
                    label: 'Total Buses',
                    value: '${buses.length}',
                    icon: Icons.directions_bus_rounded,
                    color: NmbColors.primary,
                    bg: NmbColors.primarySoft,
                    onTap: () => context.go('/admin/buses'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Active Trips',
                    value: '${activeTrips.length}',
                    icon: Icons.wifi_tethering_rounded,
                    color: NmbColors.success,
                    bg: NmbColors.successSoft,
                    onTap: () => context.go('/admin/monitoring'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: _StatCard(
                    label: 'Students',
                    value: '${students.length}',
                    icon: Icons.groups_rounded,
                    color: const Color(0xFF7B61FF),
                    bg: const Color(0xFFEFEAFF),
                    onTap: () => context.go('/admin/students'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatCard(
                    label: 'Drivers',
                    value: '${drivers.length}',
                    icon: Icons.badge_rounded,
                    color: NmbColors.accentDark,
                    bg: NmbColors.accentSoft,
                    onTap: () => context.go('/admin/drivers'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // ── Live monitoring banner ──
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => context.go('/admin/monitoring'),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: themeGradient(),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 50,
                        height: 50,
                        decoration: const BoxDecoration(
                          color: Colors.white24,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.radar_rounded,
                            color: Colors.white, size: 28,),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('Live Bus Monitoring',
                                style: NmbTypography.sectionTitle
                                    .copyWith(color: Colors.white),),
                            Text(
                              activeTrips.isEmpty
                                  ? 'No buses on a trip right now'
                                  : '${activeTrips.length} bus'
                                      '${activeTrips.length > 1 ? 'es' : ''}'
                                      ' live right now — view on map',
                              style: NmbTypography.bodySecondary
                                  .copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      if (activeTrips.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5,),
                          decoration: BoxDecoration(
                            color: NmbColors.success,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            'LIVE',
                            style: NmbTypography.caption.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Quick Actions ──
            const Text('Quick Actions', style: NmbTypography.sectionTitle),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                _ActionTile(
                  icon: Icons.directions_bus_rounded,
                  color: NmbColors.primary,
                  bg: NmbColors.primarySoft,
                  label: 'Manage\nBuses',
                  onTap: () => context.go('/admin/buses'),
                ),
                _ActionTile(
                  icon: Icons.badge_rounded,
                  color: NmbColors.accentDark,
                  bg: NmbColors.accentSoft,
                  label: 'Manage\nDrivers',
                  onTap: () => context.go('/admin/drivers'),
                ),
                _ActionTile(
                  icon: Icons.route_rounded,
                  color: const Color(0xFF7B61FF),
                  bg: const Color(0xFFEFEAFF),
                  label: 'Routes &\nStops',
                  onTap: () => context.go('/admin/routes'),
                ),
                _ActionTile(
                  icon: Icons.groups_rounded,
                  color: NmbColors.success,
                  bg: NmbColors.successSoft,
                  label: 'Manage\nStudents',
                  onTap: () => context.go('/admin/students'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Active Trips ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text('Active Trips',
                    style: NmbTypography.sectionTitle,),
                TextButton(
                  onPressed: () => context.go('/admin/monitoring'),
                  child: const Text('View All'),
                ),
              ],
            ),
            if (activeTrips.isEmpty)
              const NmbCard(
                child: Row(
                  children: <Widget>[
                    Icon(Icons.nightlight_round,
                        color: NmbColors.textTertiary,),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No buses are on a trip right now.',
                        style: NmbTypography.bodySecondary,
                      ),
                    ),
                  ],
                ),
              )
            else
              NmbCard(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6,),
                child: Column(
                  children: <Widget>[
                    for (final Trip trip in activeTrips.take(4))
                      _ActiveTripRow(
                          trip: trip, buses: buses, drivers: drivers,),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // ── Recent Activity ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text('Recent Activity',
                    style: NmbTypography.sectionTitle,),
                TextButton(
                  onPressed: () => context.go('/admin/audit'),
                  child: const Text('View All'),
                ),
              ],
            ),
            if (logs.isEmpty)
              const NmbCard(
                child: Text(
                  'No activity yet.',
                  style: NmbTypography.bodySecondary,
                ),
              )
            else
              NmbCard(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 6,),
                child: Column(
                  children: <Widget>[
                    for (final AuditLog log in logs.take(5))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        leading: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: NmbColors.primarySoft,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            _logIcon(log.action),
                            size: 18,
                            color: NmbColors.primary,
                          ),
                        ),
                        title: Text(
                          log.action.replaceAll('_', ' '),
                          style: NmbTypography.cardTitle
                              .copyWith(fontSize: 14),
                        ),
                        trailing: Text(
                          Formatters.timeOfDay(log.at),
                          style: NmbTypography.caption,
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _greetPart() {
    final int h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  IconData _logIcon(String action) {
    if (action.contains('TRIP')) return Icons.directions_bus_rounded;
    if (action.contains('PASSWORD')) return Icons.lock_reset_rounded;
    if (action.contains('ANNOUNCEMENT')) return Icons.campaign_rounded;
    if (action.contains('DISABLED')) return Icons.block_rounded;
    return Icons.person_rounded;
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NmbCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(value, style: NmbTypography.statLarge),
          Text(label, style: NmbTypography.bodySecondary),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.color,
    required this.bg,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final Color bg;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Column(
          children: <Widget>[
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: NmbTypography.caption
                  .copyWith(color: NmbColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveTripRow extends ConsumerWidget {
  const _ActiveTripRow({
    required this.trip,
    required this.buses,
    required this.drivers,
  });

  final Trip trip;
  final List<Bus> buses;
  final List<AppUser> drivers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Bus? bus;
    for (final Bus b in buses) {
      if (b.id == trip.busId) bus = b;
    }
    AppUser? driver;
    for (final AppUser d in drivers) {
      if (d.uid == trip.driverId) driver = d;
    }

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: NmbColors.accentSoft,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.directions_bus_rounded,
            color: NmbColors.accentDark,),
      ),
      title: Text(bus?.busNumber ?? trip.busId,
          style: NmbTypography.cardTitle,),
      subtitle: Text(
        '${driver?.fullName ?? 'Driver'} • '
        '${trip.startedAt != null ? 'Started at ${Formatters.timeOfDay(trip.startedAt!)}' : trip.direction.label}',
        style: NmbTypography.bodySecondary,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: NmbColors.successSoft,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          'Live',
          style: NmbTypography.caption.copyWith(
            color: NmbColors.success,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      onTap: () => context.go('/admin/monitoring'),
    );
  }
}
