import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_language.dart';
import '../../../core/constants/nmb_constants.dart';
import '../../../core/theme/app_theme_manager.dart';
import '../../../core/theme/nmb_colors.dart';
import '../../../core/theme/nmb_typography.dart';
import '../../../core/widgets/nmb_dialogs.dart';
import '../../../models/app_user.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';
import '../../../services/auth_service.dart';
import '../../shared/student_avatar.dart';

/// v1.1.1 Student side drawer — profile header (avatar, name, class) +
/// navigation items + logout, matching the design mock.
class StudentDrawer extends ConsumerWidget {
  const StudentDrawer({super.key});

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
      message: 'You will need your Class + Roll number + password to sign back in.',
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
    final AppUser? me = ref.watch(myProfileProvider).valueOrNull;
    final int unread = ref.watch(unreadCountProvider);
    final String location = GoRouterState.of(context).matchedLocation;

    void go(String path) {
      Navigator.of(context).pop();
      context.go(path);
    }

    Widget item({
      required IconData icon,
      required String label,
      required String path,
      int badge = 0,
    }) {
      final bool selected = location == path;
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          selected: selected,
          selectedTileColor: NmbColors.primarySoft,
          leading: Icon(icon,
              color: selected ? NmbColors.primary : NmbColors.textSecondary,),
          title: Text(
            label,
            style: NmbTypography.body.copyWith(
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? NmbColors.primary : NmbColors.textPrimary,
            ),
          ),
          trailing: badge > 0
              ? Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3,),
                  decoration: const BoxDecoration(
                    color: NmbColors.danger,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                )
              : null,
          onTap: () => go(path),
        ),
      );
    }

    return Drawer(
      child: Column(
        children: <Widget>[
          // ── Profile header ──
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: themeGradient(),
            ),
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: SafeArea(
              bottom: false,
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 16),
                  if (me != null)
                    StudentAvatar(
                      user: me,
                      radius: 42,
                      showOnlineDot: true,
                      online: true,
                    )
                  else
                    const CircleAvatar(radius: 42),
                  const SizedBox(height: 12),
                  Text(
                    me?.fullName ?? '…',
                    style: NmbTypography.sectionTitle
                        .copyWith(color: Colors.white),
                  ),
                  if (me?.classSection != null)
                    Text(
                      'Class ${me!.classSection}'
                      '${me.rollNumber != null ? ' • Roll ${me.rollNumber}' : ''}',
                      style: NmbTypography.bodySecondary
                          .copyWith(color: Colors.white70),
                    ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      ClipOval(
                        child: Image.asset(
                          'assets/images/school_logo.png',
                          width: 20,
                          height: 20,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        NmbConstants.schoolName,
                        style: NmbTypography.caption
                            .copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Menu ──
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 10),
              children: <Widget>[
                item(
                  icon: Icons.home_rounded,
                  label: tr('Home', 'होम'),
                  path: '/student/home',
                ),
                item(
                  icon: Icons.map_rounded,
                  label: tr('Track My Bus', 'बस ट्रैक करें'),
                  path: '/student/map',
                ),
                item(
                  icon: Icons.pin_drop_rounded,
                  label: tr('My Stop', 'मेरा स्टॉप'),
                  path: '/student/home/stops',
                ),
                item(
                  icon: Icons.schedule_rounded,
                  label: tr('ETA & Schedule', 'समय-सारणी'),
                  path: '/student/home/bus',
                ),
                item(
                  icon: Icons.notifications_rounded,
                  label: tr('Notifications', 'सूचनाएँ'),
                  path: '/student/alerts',
                  badge: unread,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Divider(),
                ),
                item(
                  icon: Icons.person_rounded,
                  label: tr('Profile', 'प्रोफ़ाइल'),
                  path: '/student/profile',
                ),
                item(
                  icon: Icons.settings_rounded,
                  label: tr('Settings', 'सेटिंग्स'),
                  path: '/student/profile/settings',
                ),
              ],
            ),
          ),

          // ── Logout ──
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.all(10),
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              leading:
                  const Icon(Icons.logout_rounded, color: NmbColors.danger),
              title: Text(
                tr('Logout', 'लॉगआउट'),
                style: NmbTypography.body.copyWith(
                  color: NmbColors.danger,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _logout(context, ref);
              },
            ),
          ),
          const SafeArea(top: false, child: SizedBox(height: 4)),
        ],
      ),
    );
  }
}
