import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_language.dart';
import '../../../core/theme/nmb_colors.dart';
import '../../../core/theme/nmb_typography.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/nmb_dialogs.dart';
import '../../../core/widgets/responsive_scaffold_body.dart';
import '../../../providers/app_providers.dart';
import '../../../services/auth_service.dart';

/// FIRST LOGIN FLOW (OTP-alternate security):
/// STEP 1 → language chooser (English / हिंदी) — pehla sawal yahi.
/// STEP 2 → set your own password (chosen language me hi sab text).
class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key, this.forced = false});

  final bool forced;

  @override
  ConsumerState<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}

class _ChangePasswordScreenState
    extends ConsumerState<ChangePasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _pw1 = TextEditingController();
  final TextEditingController _pw2 = TextEditingController();
  bool _ob1 = true;
  bool _ob2 = true;
  bool _saving = false;

  /// Forced (first-login) mode me language pehle choose hoti hai.
  bool _langChosen = false;

  @override
  void initState() {
    super.initState();
    // Normal (settings se aaya) mode me language step skip.
    if (!widget.forced) _langChosen = true;
  }

  @override
  void dispose() {
    _pw1.dispose();
    _pw2.dispose();
    super.dispose();
  }

  Future<void> _chooseLang(String code) async {
    appLanguage.value = code;
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setString('nmb_lang', code);
    } catch (_) {}
    if (mounted) setState(() => _langChosen = true);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final AuthSession? session = ref.read(currentSessionProvider);
    final fs = ref.read(firestoreServiceProvider);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final NavigatorState nav = Navigator.of(context);
    if (session == null) return;

    setState(() => _saving = true);
    try {
      await FirebaseAuth.instance.currentUser!
          .updatePassword(_pw1.text)
          .timeout(const Duration(seconds: 15));
      // Flag hatao — ab normal login flow
      await fs.saveUserSettings(session.uid, <String, dynamic>{
        'mustChangePassword': false,
      });
      if (!mounted) return;
      setState(() => _saving = false);
      if (!widget.forced && nav.canPop()) nav.pop();
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF1E8E3E),
          content: Text(
            tr('Password changed ✓ — remember it!',
                'पासवर्ड बदल गया ✓ — इसे याद रखें!',),
            style: const TextStyle(color: Colors.white),
          ),
        ),
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showNmbSnack(
        context,
        e.code == 'requires-recent-login'
            ? tr(
                'Session is too old — please log out, log in again, and '
                'then change the password right away.',
                'सेशन पुराना है — लॉगआउट करके दोबारा लॉगिन करें, फिर '
                'तुरंत पासवर्ड बदलें।',
              )
            : tr('Password change failed: ${e.message}',
                'पासवर्ड नहीं बदला: ${e.message}',),
        isError: true,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showNmbSnack(context, tr('Failed: $e', 'विफल: $e'), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ── STEP 1: LANGUAGE CHOOSER (sirf first login me) ──
    if (!_langChosen) {
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Container(
                    width: 96,
                    height: 96,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: NmbColors.primarySoft,
                      shape: BoxShape.circle,
                    ),
                    child: const Text('🌐', style: TextStyle(fontSize: 44)),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Choose your language',
                    textAlign: TextAlign.center,
                    style: NmbTypography.screenTitle,
                  ),
                  const Text(
                    'अपनी भाषा चुनें',
                    textAlign: TextAlign.center,
                    style: NmbTypography.screenTitle,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'You can change this anytime in Settings.\n'
                    'आप इसे कभी भी सेटिंग्स में बदल सकते हैं।',
                    textAlign: TextAlign.center,
                    style: NmbTypography.caption,
                  ),
                  const SizedBox(height: 28),
                  FilledButton(
                    onPressed: () => _chooseLang('en'),
                    child: const Text('English 🇬🇧'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(54),
                      side: BorderSide(color: NmbColors.primary, width: 1.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => _chooseLang('hi'),
                    child: const Text('हिंदी 🇮🇳',
                        style: TextStyle(fontSize: 16),),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // ── STEP 2: SET PASSWORD (chosen language me) ──
    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Set Your Password', 'अपना पासवर्ड बनाएं')),
        automaticallyImplyLeading: !widget.forced,
      ),
      body: ResponsiveBody(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: NmbColors.accentSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.shield_rounded,
                        color: NmbColors.accentDark,),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.forced
                            ? tr(
                                'This is your first login! For your safety, '
                                'replace the password given by school with '
                                'YOUR OWN password — one that only you know.',
                                'यह आपका पहला लॉगिन है! अपनी सुरक्षा के लिए '
                                'स्कूल वाला पासवर्ड बदलकर अपना खुद का '
                                'पासवर्ड बनाएं — जो सिर्फ आपको पता हो।',
                              )
                            : tr('Set a new password.',
                                'नया पासवर्ड सेट करें।',),
                        style: NmbTypography.bodySecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _pw1,
                obscureText: _ob1,
                decoration: InputDecoration(
                  hintText: tr('New password', 'नया पासवर्ड'),
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_ob1
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,),
                    onPressed: () => setState(() => _ob1 = !_ob1),
                  ),
                ),
                validator: Validators.strongPassword,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _pw2,
                obscureText: _ob2,
                decoration: InputDecoration(
                  hintText:
                      tr('Confirm new password', 'नया पासवर्ड दोबारा लिखें'),
                  prefixIcon: const Icon(Icons.lock_rounded),
                  suffixIcon: IconButton(
                    icon: Icon(_ob2
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,),
                    onPressed: () => setState(() => _ob2 = !_ob2),
                  ),
                ),
                validator: (String? v) => v != _pw1.text
                    ? tr('Passwords do not match', 'पासवर्ड मेल नहीं खाते')
                    : null,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving
                    ? tr('Saving…', 'सेव हो रहा है…')
                    : tr('Save Password', 'पासवर्ड सेव करें'),),
              ),
              const SizedBox(height: 10),
              Text(
                tr(
                  'Minimum 10 characters, 1 capital letter, 1 number.',
                  'कम से कम 10 अक्षर, 1 बड़ा अक्षर (A-Z), 1 अंक।',
                ),
                style: NmbTypography.caption,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
