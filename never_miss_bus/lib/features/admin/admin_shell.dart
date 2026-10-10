import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/nmb_colors.dart';
import '../../core/theme/nmb_typography.dart';
import '../../core/widgets/nmb_dialogs.dart';
import '../../core/widgets/state_views.dart';
import '../../providers/app_providers.dart';
import '../../services/auth_service.dart';

/// Admin shell with a navigation drawer (admin has more sections than fit a
/// bottom bar, but the design stays friendly, not "corporate dashboard").
class AdminShell extends ConsumerWidget {
  const AdminShell({super.key, required this.child});

  final Widget child;

  static const List<(String, String, IconData)> _items =
      <(String, String, IconData)>[
    ('/admin/dashboard', 'Dashboard', Icons.dashboard_rounded),
    ('/admin/students', 'Students', Icons.school_rounded),
    ('/admin/documents', 'Documents', Icons.folder_copy_rounded),
    ('/admin/results', 'Exam Results', Icons.assessment_rounded),
    ('/admin/timetable', 'Timetable', Icons.schedule_rounded),
    ('/admin/attendance', 'Attendance', Icons.fact_check_rounded),
    ('/admin/teachers', 'Class Teachers', Icons.co_present_rounded),
    ('/admin/drivers', 'Drivers', Icons.badge_rounded),
    ('/admin/buses', 'Buses', Icons.directions_bus_rounded),
    ('/admin/routes', 'Routes & Stops', Icons.route_rounded),
    ('/admin/monitoring', 'Live Monitoring', Icons.radar_rounded),
    ('/admin/notifications', 'Notifications', Icons.campaign_rounded),
    ('/admin/trips', 'Trip History', Icons.history_rounded),
    ('/admin/errors', 'Error Reports', Icons.bug_report_rounded),
    ('/admin/audit', 'Activity Logs', Icons.receipt_long_rounded),
    ('/admin/settings', 'Settings', Icons.settings_rounded),
  ];

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final AuthSession? session = ref.read(currentSessionProvider);
    // Capture EVERYTHING from ref BEFORE any await/pop — after the widget
    // is disposed, ref must not be touched ("ref after disposed" fix).
    final notifSvc = ref.read(notificationServiceProvider);
    final devSvc = ref.read(deviceSessionServiceProvider);
    final fsSvc = ref.read(firestoreServiceProvider);
    final authSvc = ref.read(authServiceProvider);
    final bool ok = await showNmbConfirmDialog(
      context,
      title: 'Log out?',
      message: 'End your admin session?',
      confirmLabel: 'Log out',
      destructive: true,
      icon: Icons.logout_rounded,
    );
    if (!ok) return;
    if (session != null) {
      try {
        await notifSvc.unregisterDevice(session.uid);
      } catch (_) {/* best effort */}
      try {
        final String devId = await devSvc.getDeviceId();
        await fsSvc.clearActiveDevice(
          uid: session.uid,
          deviceId: devId,
        );
      } catch (_) {/* best effort */}
    }
    await authSvc.signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String location = GoRouterState.of(context).matchedLocation;
    final bool online = ref.watch(isOnlineProvider).valueOrNull ?? true;

    // Back button: kisi section me ho → Dashboard; Dashboard pe ho → exit.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        final GoRouter router = GoRouter.of(context);
        if (router.canPop()) {
          router.pop();
        } else if (location != '/admin/dashboard') {
          context.go('/admin/dashboard');
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        drawer: Drawer(
          child: SafeArea(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: NmbColors.primary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.directions_bus_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Never Miss Bus',
                              style: NmbTypography.sectionTitle,
                            ),
                            Text(
                              'Admin Console',
                              style: NmbTypography.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    children: <Widget>[
                      for (final (String path, String label, IconData icon)
                          in _items)
                        ListTile(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          selected: location.startsWith(path),
                          selectedTileColor: NmbColors.primarySoft,
                          leading: Icon(icon),
                          title: Text(
                            label,
                            style: NmbTypography.body.copyWith(
                              fontWeight: location.startsWith(path)
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                          onTap: () {
                            Navigator.of(context).pop();
                            context.go(path);
                          },
                        ),
                    ],
                  ),
                ),
                const Divider(),
                ListTile(
                  leading:
                      const Icon(Icons.logout_rounded, color: NmbColors.danger),
                  title: Text(
                    'Log out',
                    style: NmbTypography.body.copyWith(color: NmbColors.danger),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _logout(context, ref);
                  },
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        body: Column(
          children: <Widget>[
            if (!online) const OfflineBanner(),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}
