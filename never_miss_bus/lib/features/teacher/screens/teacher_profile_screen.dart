import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_language.dart';
import '../../../core/theme/app_theme_manager.dart';
import '../../../core/constants/nmb_constants.dart';
import '../../../core/theme/nmb_colors.dart';
import '../../../core/theme/nmb_typography.dart';
import '../../../core/widgets/nmb_card.dart';
import '../../../core/widgets/nmb_dialogs.dart';
import '../../../core/widgets/responsive_scaffold_body.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/app_user.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';
import '../../../services/auth_service.dart';

/// TEACHER PROFILE — apna info + language switch + logout.
class TeacherProfileScreen extends ConsumerWidget {
  const TeacherProfileScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final AuthSession? session = ref.read(currentSessionProvider);
    final notifSvc = ref.read(notificationServiceProvider);
    final devSvc = ref.read(deviceSessionServiceProvider);
    final fsSvc = ref.read(firestoreServiceProvider);
    final authSvc = ref.read(authServiceProvider);
    final bool ok = await showNmbConfirmDialog(
      context,
      title: tr('Log out?', 'लॉग आउट?'),
      message: tr('You will need your email and password to sign back in.',
          'Wapas aane ke liye email/password chahiye hoga.',),
      confirmLabel: tr('Log out', 'लॉग आउट'),
      destructive: true,
      icon: Icons.logout_rounded,
    );
    if (!ok) return;
    if (session != null) {
      try {
        await notifSvc.unregisterDevice(session.uid);
      } catch (_) {}
      try {
        final String devId = await devSvc.getDeviceId();
        await fsSvc.clearActiveDevice(
            uid: session.uid, deviceId: devId,);
      } catch (_) {}
    }
    await authSvc.signOut();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AppUser?> profileAsync = ref.watch(myProfileProvider);

    return Scaffold(
      appBar: AppBar(title: Text(tr('Profile', 'प्रोफ़ाइल'))),
      body: profileAsync.when(
        loading: () => const LoadingView(),
        error: (Object e, _) => ErrorView(
          message: tr("Couldn't load profile.", 'प्रोफ़ाइल लोड नहीं हुई।'),
          onRetry: () => ref.invalidate(myProfileProvider),
        ),
        data: (AppUser? me) {
          if (me == null) {
            return const ErrorView(
              title: 'Profile unavailable',
              message: 'Contact the school office.',
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
                        backgroundColor: NmbColors.primarySoft,
                        child: Icon(Icons.co_present_rounded,
                            color: NmbColors.primary, size: 30,),
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
                            if (me.classSection != null)
                              Text(
                                '${tr('Class Teacher of', 'क्लास टीचर')} '
                                '${me.classSection}',
                                style: NmbTypography.caption.copyWith(
                                  color: NmbColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                const Text(NmbConstants.schoolName,
                    style: NmbTypography.caption,
                    textAlign: TextAlign.center,),
                const SizedBox(height: 14),
                // Language switch
                NmbCard(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8,),
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.translate_rounded,
                          color: NmbColors.primary,),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(tr('App language', 'ऐप भाषा')),),
                      TextButton(
                        onPressed: () async {
                          final SharedPreferences prefs =
                              await SharedPreferences.getInstance();
                          final String next =
                              appLanguage.value == 'en' ? 'hi' : 'en';
                          await prefs.setString('nmb_lang', next);
                          appLanguage.value = next;
                        },
                        child: Text(
                          appLanguage.value == 'hi'
                              ? 'हिंदी → EN'
                              : 'EN → हिंदी',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Theme quick-switch
                NmbCard(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10,),
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.palette_rounded,
                          color: NmbColors.primary,),
                      const SizedBox(width: 12),
                      Expanded(child: Text(tr('Theme', 'थीम'))),
                      for (final AppThemeOption t
                          in AppThemeManager.themes)
                        GestureDetector(
                          onTap: () => AppThemeManager.set(t.id),
                          child: Container(
                            margin: const EdgeInsets.only(left: 6),
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: t.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppThemeManager.current.value.id ==
                                        t.id
                                    ? Colors.black54
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
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
                  label: Text(tr('Log out', 'लॉग आउट')),
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
