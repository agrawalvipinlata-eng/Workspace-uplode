import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/nmb_colors.dart';
import '../../../core/theme/nmb_typography.dart';
import '../../../core/widgets/nmb_card.dart';
import '../../../core/widgets/nmb_dialogs.dart';
import '../../../core/widgets/responsive_scaffold_body.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/app_user.dart';
import '../../../models/bus.dart';
import '../../../models/trip.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';
import '../../../services/auth_service.dart';

class DriverProfileScreen extends ConsumerWidget {
  const DriverProfileScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final AuthSession? session = ref.read(currentSessionProvider);
    // Capture EVERYTHING from ref BEFORE any await/pop — after the widget
    // is disposed, ref must not be touched ("ref after disposed" fix).
    final notifSvc = ref.read(notificationServiceProvider);
    final devSvc = ref.read(deviceSessionServiceProvider);
    final fsSvc = ref.read(firestoreServiceProvider);
    final authSvc = ref.read(authServiceProvider);
    final Trip? trip = ref.read(myBusActiveTripProvider).valueOrNull;
    if (trip != null && trip.isActive) {
      showNmbSnack(
        context,
        'Please end your active trip before logging out.',
        isError: true,
      );
      return;
    }
    final bool confirmed = await showNmbConfirmDialog(
      context,
      title: 'Log out?',
      message: 'You\'ll need your driver account credentials to sign '
          'back in.',
      confirmLabel: 'Log out',
      destructive: true,
      icon: Icons.logout_rounded,
    );
    if (!confirmed) return;
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
    final AsyncValue<AppUser?> profileAsync = ref.watch(myProfileProvider);
    final Bus? bus = ref.watch(myBusProvider).valueOrNull;
    final Map<String, dynamic>? school =
        ref.watch(schoolConfigProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profileAsync.when(
        loading: () => const LoadingView(),
        error: (Object e, _) => ErrorView(
          message: 'Couldn\'t load your profile.',
          onRetry: () => ref.invalidate(myProfileProvider),
        ),
        data: (AppUser? me) {
          if (me == null) {
            return const ErrorView(
              title: 'Profile unavailable',
              message: 'Please contact the transport office.',
            );
          }
          return ResponsiveBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                NmbCard(
                  child: Row(
                    children: <Widget>[
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: NmbColors.accentSoft,
                        child: Icon(Icons.badge_rounded,
                            color: NmbColors.accentDark, size: 30,),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(me.fullName,
                                style: NmbTypography.sectionTitle,),
                            Text(me.email,
                                style: NmbTypography.bodySecondary,),
                            const Text('School bus driver',
                                style: NmbTypography.caption,),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                NmbCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.directions_bus_rounded,
                        color: NmbColors.primary,),
                    title: const Text('Assigned bus'),
                    trailing: Text(
                      bus?.busNumber ?? 'Not assigned',
                      style: NmbTypography.cardTitle,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                if (school?['phone'] != null)
                  NmbCard(
                    child: Row(
                      children: <Widget>[
                        const Icon(Icons.support_agent_rounded,
                            color: NmbColors.info,),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text('Transport office',
                                  style: NmbTypography.cardTitle,),
                              Text(school!['phone'] as String,
                                  style: NmbTypography.bodySecondary,),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: NmbColors.danger,
                    side: const BorderSide(color: NmbColors.danger),
                  ),
                  onPressed: () => _logout(context, ref),
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Log out'),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}
