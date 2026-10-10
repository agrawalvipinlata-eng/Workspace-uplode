import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_language.dart';
import '../../../core/security/app_lock_manager.dart';
import '../../../core/theme/app_theme_manager.dart';

import '../../../core/theme/nmb_colors.dart';
import '../../../core/theme/nmb_typography.dart';
import '../../../core/widgets/nmb_card.dart';
import '../../../core/widgets/nmb_dialogs.dart';
import '../../../core/widgets/responsive_scaffold_body.dart';
import '../../../providers/app_providers.dart';
import '../../../services/auth_service.dart';

/// Notification preferences + permission helper + password reset.
class StudentSettingsScreen extends ConsumerStatefulWidget {
  const StudentSettingsScreen({super.key});

  @override
  ConsumerState<StudentSettingsScreen> createState() =>
      _StudentSettingsScreenState();
}

class _StudentSettingsScreenState extends ConsumerState<StudentSettingsScreen> {
  bool _tripAlerts = true;
  bool _approachingAlerts = true;
  bool _announcementAlerts = true;
  PermissionStatus? _notifPermission;

  @override
  void initState() {
    super.initState();
    Permission.notification.status.then((PermissionStatus s) {
      if (mounted) setState(() => _notifPermission = s);
    });
  }

  final TextEditingController _selfPhone = TextEditingController();
  final TextEditingController _selfAddress = TextEditingController();

  Future<void> _saveSettings() async {
    final AuthSession? session = ref.read(currentSessionProvider);
    if (session == null) return;
    await ref.read(firestoreServiceProvider).saveUserSettings(
      session.uid,
      <String, dynamic>{
        'tripAlerts': _tripAlerts,
        'approachingAlerts': _approachingAlerts,
        'announcementAlerts': _announcementAlerts,
        // STUDENT SELF-EDIT: apna contact update (settings me — safe,
        // rules allow; school records untouched)
        if (_selfPhone.text.trim().isNotEmpty)
          'parentPhoneSelf': _selfPhone.text.trim(),
        if (_selfAddress.text.trim().isNotEmpty)
          'addressSelf': _selfAddress.text.trim(),
      },
    );
    if (mounted)
      showNmbSnack(context, tr('Settings saved ✓', 'सेटिंग्स सेव ✓'),
          isSuccess: true);
  }

  Future<void> _requestNotifPermission() async {
    final PermissionStatus status = await Permission.notification.request();
    if (!mounted) return;
    setState(() => _notifPermission = status);
    if (status.isPermanentlyDenied) {
      final bool open = await showNmbConfirmDialog(
        context,
        title: 'Enable notifications',
        message: 'Notifications are turned off for this app. Open system '
            'settings to enable bus alerts?',
        confirmLabel: 'Open Settings',
      );
      if (open) await openAppSettings();
    }
  }

  @override
  void dispose() {
    _selfPhone.dispose();
    _selfAddress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool notifDenied =
        _notifPermission != null && !_notifPermission!.isGranted;

    return Scaffold(
      appBar: AppBar(title: Text(tr('Settings', 'सेटिंग्स'))),
      body: ResponsiveBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (notifDenied) ...<Widget>[
              NmbCard(
                color: NmbColors.warningSoft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Row(
                      children: <Widget>[
                        Icon(
                          Icons.notifications_off_rounded,
                          color: NmbColors.warning,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Notifications are off — you won\'t receive '
                            'bus alerts.',
                            style: NmbTypography.bodySecondary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton(
                      onPressed: _requestNotifPermission,
                      child: const Text('Enable notifications'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],
            const Text(
              'Notification preferences',
              style: NmbTypography.sectionTitle,
            ),
            const SizedBox(height: 10),
            NmbCard(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 4,
              ),
              child: Column(
                children: <Widget>[
                  SwitchListTile(
                    title: const Text('Trip started / ended'),
                    value: _tripAlerts,
                    onChanged: (bool v) => setState(() => _tripAlerts = v),
                  ),
                  SwitchListTile(
                    title: const Text('Bus approaching my stop'),
                    value: _approachingAlerts,
                    onChanged: (bool v) =>
                        setState(() => _approachingAlerts = v),
                  ),
                  SwitchListTile(
                    title: const Text('School announcements'),
                    value: _announcementAlerts,
                    onChanged: (bool v) =>
                        setState(() => _announcementAlerts = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saveSettings,
              child: const Text('Save preferences'),
            ),
            const SizedBox(height: 24),
            const Text('Language / भाषा', style: NmbTypography.sectionTitle),
            const SizedBox(height: 10),
            NmbCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.translate_rounded,
                    color: NmbColors.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(tr('App language', 'ऐप की भाषा'))),
                  TextButton(
                    onPressed: () async {
                      final SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      final String cur = prefs.getString('nmb_lang') ?? 'en';
                      final String next = cur == 'en' ? 'hi' : 'en';
                      await prefs.setString('nmb_lang', next);
                      // INSTANT: global notifier update — poori app me
                      // language turant badal jaati hai (restart nahi).
                      appLanguage.value = next;
                      if (context.mounted) {
                        setState(() {});
                        showNmbSnack(
                          context,
                          next == 'hi'
                              ? 'भाषा बदल गई ✓ (हिंदी)'
                              : 'Language changed ✓ (English)',
                          isSuccess: true,
                        );
                      }
                    },
                    child: ValueListenableBuilder<String>(
                      valueListenable: appLanguage,
                      builder: (_, String lang, __) => Text(
                        lang == 'hi' ? 'हिंदी → EN' : 'EN → हिंदी',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // ── THEME PICKER: 4 themes, tap = poora app naya color ──
            Text(tr('App Theme', 'ऐप थीम'), style: NmbTypography.sectionTitle),
            const SizedBox(height: 10),
            NmbCard(
              child: ValueListenableBuilder<AppThemeOption>(
                valueListenable: AppThemeManager.current,
                builder: (BuildContext ctx, AppThemeOption cur, _) {
                  return Column(
                    children: <Widget>[
                      for (final AppThemeOption t in AppThemeManager.themes)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: <Color>[
                                  t.primaryDark,
                                  t.primary,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Center(
                              child: Text(
                                t.emoji,
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                          title: Text(
                            appLanguage.value == 'hi' ? t.nameHi : t.name,
                          ),
                          trailing: cur.id == t.id
                              ? Icon(
                                  Icons.check_circle_rounded,
                                  color: t.primary,
                                )
                              : const Icon(
                                  Icons.radio_button_unchecked_rounded,
                                  color: NmbColors.textTertiary,
                                ),
                          onTap: () => AppThemeManager.set(t.id),
                        ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            NmbCard(
              padding: EdgeInsets.zero,
              child: ValueListenableBuilder<bool>(
                valueListenable: AppThemeManager.darkMode,
                builder: (BuildContext context, bool dark, Widget? _) =>
                    SwitchListTile.adaptive(
                  value: dark,
                  onChanged: AppThemeManager.setDarkMode,
                  secondary: Icon(
                    dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: NmbColors.primary,
                  ),
                  title: Text(tr('Dark Mode', 'डार्क मोड')),
                  subtitle: Text(
                    tr('Comfortable dark appearance',
                        'आंखों के लिए आरामदायक डार्क स्क्रीन'),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            NmbCard(
              padding: EdgeInsets.zero,
              child: ValueListenableBuilder<bool>(
                valueListenable: AppLockManager.enabled,
                builder: (BuildContext context, bool locked, Widget? _) =>
                    SwitchListTile.adaptive(
                  value: locked,
                  onChanged: (bool value) async {
                    final bool ok = await AppLockManager.setEnabled(value);
                    if (!ok && context.mounted) {
                      showNmbSnack(
                        context,
                        'Device biometric/PIN lock is not available.',
                        isError: true,
                      );
                    }
                  },
                  secondary:
                      Icon(Icons.fingerprint_rounded, color: NmbColors.primary),
                  title: Text(tr('App Lock', 'ऐप लॉक')),
                  subtitle: Text(
                    tr('Use device PIN or biometrics when reopening',
                        'ऐप खोलते समय फोन PIN या biometric लगाएं'),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'My Contact Info (self-update)',
              style: NmbTypography.sectionTitle,
            ),
            const SizedBox(height: 10),
            NmbCard(
              child: Column(
                children: <Widget>[
                  TextField(
                    controller: _selfPhone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: 'Parent mobile number (update)',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _selfAddress,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Home address (update)',
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Save preferences dabao — school ko update dikh '
                    'jayega.',
                    style: NmbTypography.caption,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(tr('Account', 'अकाउंट'), style: NmbTypography.sectionTitle),
            const SizedBox(height: 10),
            NmbCard(
              onTap: () => context.go('/student/profile/password'),
              child: Row(
                children: <Widget>[
                  Icon(Icons.lock_rounded, color: NmbColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tr('Change my password', 'पासवर्ड बदलें'),
                      style: NmbTypography.cardTitle,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: NmbColors.textTertiary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // 🛡️ PRIVACY POLICY (Play Store requirement)
            NmbCard(
              onTap: () => context.go('/student/profile/privacy'),
              child: Row(
                children: <Widget>[
                  const Icon(
                    Icons.privacy_tip_rounded,
                    color: NmbColors.info,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      tr('Privacy Policy', 'गोपनीयता नीति'),
                      style: NmbTypography.cardTitle,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: NmbColors.textTertiary,
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
}
