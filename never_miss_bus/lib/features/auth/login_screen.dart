import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_language.dart';

import '../../core/constants/nmb_constants.dart';
import '../../core/theme/app_theme_manager.dart';
import '../../core/theme/nmb_colors.dart';
import '../../core/theme/nmb_typography.dart';
import '../../core/utils/result.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/nmb_dialogs.dart';
import '../../providers/app_providers.dart';
import '../../services/auth_service.dart';

/// v1.3 Login — premium look:
/// blue curved header with the real bus logo, floating white card with
/// Student / Staff toggle, clean fields, loading state on the button.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _studentMode = true;
  String _lang = 'en'; // 'en' | 'hi'

  @override
  void initState() {
    super.initState();
    _initLanguage();
  }

  /// FIRST-LOGIN LANGUAGE: pehli baar app khulne par language chooser.
  Future<void> _initLanguage() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? saved = prefs.getString('nmb_lang');
    if (saved != null) {
      appLanguage.value = saved;
      if (mounted) setState(() => _lang = saved);
      return;
    }
    if (!mounted) return;
    final String? chosen = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Choose Language / भाषा चुनें'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Text('🇬🇧', style: TextStyle(fontSize: 24)),
              title: const Text('English'),
              onTap: () => Navigator.of(ctx).pop('en'),
            ),
            ListTile(
              leading: const Text('🇮🇳', style: TextStyle(fontSize: 24)),
              title: const Text('हिंदी (Hinglish)'),
              onTap: () => Navigator.of(ctx).pop('hi'),
            ),
          ],
        ),
      ),
    );
    final String lang = chosen ?? 'en';
    await prefs.setString('nmb_lang', lang);
    appLanguage.value = lang;
    if (mounted) setState(() => _lang = lang);
  }

  String t(String en, String hi) => _lang == 'hi' ? hi : en;

  String? _klass;
  String? _section;
  final TextEditingController _roll = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _roll.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);
    final AuthService authSvc = ref.read(authServiceProvider);

    Result<AuthSession> result;
    if (_studentMode) {
      result = const Err<AuthSession>(AppFailure.unknown);
      for (int gen = 1; gen <= StudentLoginId.maxGenerations; gen++) {
        result = await authSvc.signIn(
          email: StudentLoginId.email(
            klass: _klass ?? '',
            section: _section ?? '',
            roll: _roll.text,
            gen: gen,
          ),
          password: _passwordController.text,
        );
        final bool disabled = result is Err<AuthSession> &&
            (result).failure.code == 'user-disabled';
        if (!disabled) break;
      }
    } else {
      result = await authSvc.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    }

    if (!mounted) return;
    setState(() => _loading = false);
    result.when(
      ok: (_) {},
      err: (AppFailure f) => showNmbSnack(
        context,
        _studentMode &&
                (f.code == 'invalid-credential' || f.code == 'user-disabled')
            ? 'Incorrect class, roll number or password. Please try again.'
            : f.message,
        isError: true,
      ),
    );
  }

  /// NO EMAIL RESET — students ke paas real email nahi hota. Password
  /// bhoolne par school hi naya password deta hai (admin/teacher reset).
  Future<void> _forgotPassword() async {
    await showDialog<void>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: Row(
          children: <Widget>[
            Icon(Icons.help_outline_rounded, color: NmbColors.primary),
            const SizedBox(width: 8),
            const Expanded(child: Text('Password bhool gaye?')),
          ],
        ),
        content: const Text(
          'Koi baat nahi! 😊\n\n'
          '1. Apne class teacher ya school office se milo.\n'
          '2. Wo aapko turant naya password de denge.\n'
          '3. Naye password se login karke apna khud ka '
          'password set kar lena.\n\n'
          'Aapka account safe hai — bina school ke koi '
          'password change nahi kar sakta.',
        ),
        actions: <Widget>[
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Samajh gaya'),
          ),
        ],
      ),
    );
  }

  InputDecoration _dec({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) =>
      InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, size: 21),
        suffixIcon: suffix,
        filled: true,
        fillColor: NmbColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: NmbColors.primary, width: 1.6),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: NmbColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: <Widget>[
          SliverToBoxAdapter(
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                // ── Curved blue header ──
                Container(
                  height: 300,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: themeGradient(),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(44),
                      bottomRight: Radius.circular(44),
                    ),
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        const SizedBox(height: 6),
                        // 🏫 ONLY school logo — bada, white ring ke saath
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: Color(0x33000000),
                                blurRadius: 14,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/school_logo.png',
                              width: 110,
                              height: 110,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.school_rounded,
                                size: 80,
                                color: Color(0xFF00A7DE),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          t('Welcome Back! 👋', 'Wapas swagat hai! 👋'),
                          style: NmbTypography.displayTitle
                              .copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          NmbConstants.schoolName,
                          style: NmbTypography.bodySecondary
                              .copyWith(color: Colors.white70),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),

                // ── Floating login card ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 262, 20, 0),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x1A17233B),
                          blurRadius: 24,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          // ── Role toggle ──
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: NmbColors.background,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: <Widget>[
                                _ToggleTab(
                                  label: t('Student', 'Student'),
                                  icon: Icons.school_rounded,
                                  selected: _studentMode,
                                  onTap: () =>
                                      setState(() => _studentMode = true),
                                ),
                                _ToggleTab(
                                  label: 'Driver / Admin',
                                  icon: Icons.badge_rounded,
                                  selected: !_studentMode,
                                  onTap: () =>
                                      setState(() => _studentMode = false),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // ── Fields ──
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            child: _studentMode
                                ? Column(
                                    key: const ValueKey<String>('student'),
                                    children: <Widget>[
                                      Row(
                                        children: <Widget>[
                                          Expanded(
                                            flex: 3,
                                            child: DropdownButtonFormField<
                                                String>(
                                              value: _klass,
                                              decoration: _dec(
                                                hint: 'Class',
                                                icon: Icons.class_outlined,
                                              ),
                                              items: <DropdownMenuItem<
                                                  String>>[
                                                for (final String c
                                                    in SchoolClasses
                                                        .classes)
                                                  DropdownMenuItem<String>(
                                                    value: c,
                                                    child: Text('Class $c'),
                                                  ),
                                              ],
                                              onChanged: (String? v) =>
                                                  setState(
                                                      () => _klass = v,),
                                              validator: (String? v) =>
                                                  v == null
                                                      ? 'Select class'
                                                      : null,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            flex: 2,
                                            child: DropdownButtonFormField<
                                                String>(
                                              value: _section,
                                              decoration: _dec(
                                                hint: 'Sec',
                                                icon: Icons
                                                    .segment_rounded,
                                              ),
                                              items: <DropdownMenuItem<
                                                  String>>[
                                                for (final String s
                                                    in SchoolClasses
                                                        .sections)
                                                  DropdownMenuItem<String>(
                                                    value: s,
                                                    child: Text(s),
                                                  ),
                                              ],
                                              onChanged: (String? v) =>
                                                  setState(
                                                      () => _section = v,),
                                              validator: (String? v) =>
                                                  v == null
                                                      ? 'Select'
                                                      : null,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      TextFormField(
                                        controller: _roll,
                                        keyboardType:
                                            TextInputType.number,
                                        decoration: _dec(
                                          hint: 'Roll number',
                                          icon: Icons.tag_rounded,
                                        ),
                                        validator: (String? v) {
                                          final String r =
                                              (v ?? '').trim();
                                          if (r.isEmpty) {
                                            return 'Enter roll number';
                                          }
                                          if (int.tryParse(r) == null) {
                                            return 'Numbers only';
                                          }
                                          return null;
                                        },
                                      ),
                                    ],
                                  )
                                : TextFormField(
                                    key: const ValueKey<String>('staff'),
                                    controller: _emailController,
                                    keyboardType:
                                        TextInputType.emailAddress,
                                    autofillHints: const <String>[
                                      AutofillHints.username,
                                    ],
                                    decoration: _dec(
                                      hint: 'Email',
                                      icon: Icons.mail_outline_rounded,
                                    ),
                                    validator: Validators.email,
                                  ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscure,
                            autofillHints: const <String>[
                              AutofillHints.password,
                            ],
                            onFieldSubmitted: (_) => _signIn(),
                            decoration: _dec(
                              hint: 'Password',
                              icon: Icons.lock_outline_rounded,
                              suffix: IconButton(
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 21,
                                ),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
                              ),
                            ),
                            validator: Validators.password,
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed:
                                  _loading ? null : _forgotPassword,
                              child: const Text('Forgot password?'),
                            ),
                          ),
                          const SizedBox(height: 6),

                          // ── Sign in button with loading state ──
                          SizedBox(
                            height: 54,
                            child: FilledButton(
                              onPressed: _loading ? null : _signIn,
                              style: FilledButton.styleFrom(
                                backgroundColor: NmbColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(15),
                                ),
                              ),
                              child: _loading
                                  ? const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: <Widget>[
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child:
                                              CircularProgressIndicator(
                                            strokeWidth: 2.4,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(width: 12),
                                        Text('Signing in…'),
                                      ],
                                    )
                                  : Text(t('Sign In', 'Login karo')),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Help note ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: NmbColors.infoSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.school_outlined,
                        color: NmbColors.info, size: 22,),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _studentMode
                            ? 'Your roll number and password are provided '
                                'by the school. Contact your class teacher '
                                'for help.'
                            : 'Accounts are created by the school. If you '
                                'don\'t have one, contact the transport '
                                'office.',
                        style: NmbTypography.caption
                            .copyWith(color: NmbColors.info),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleTab extends StatelessWidget {
  const _ToggleTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 11),
          decoration: BoxDecoration(
            color: selected ? NmbColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                icon,
                size: 18,
                color: selected ? Colors.white : NmbColors.textTertiary,
              ),
              const SizedBox(width: 7),
              Text(
                label,
                style: NmbTypography.caption.copyWith(
                  fontWeight: FontWeight.w700,
                  color:
                      selected ? Colors.white : NmbColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
