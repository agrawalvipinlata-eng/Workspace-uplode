import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/nmb_constants.dart';
import '../../../core/theme/nmb_colors.dart';
import '../../../core/theme/nmb_typography.dart';
import '../../../core/utils/result.dart';
import '../../../core/utils/validators.dart';
import '../../../core/utils/whatsapp_share.dart';
import '../../../core/widgets/nmb_dialogs.dart';
import '../../../models/app_user.dart';
import '../../../models/bus.dart';
import '../../../models/bus_stop.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';

/// Bottom sheet to provision a new student/driver account.
/// Provisioning goes through the admin-only `provisionUser` Cloud Function —
/// the app cannot create privileged accounts by itself.
class UserEditorSheet extends ConsumerStatefulWidget {
  const UserEditorSheet({super.key, required this.role});

  final String role; // 'student' | 'driver'

  static Future<void> show(BuildContext context, {required String role}) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => UserEditorSheet(role: role),
      );

  @override
  ConsumerState<UserEditorSheet> createState() => _UserEditorSheetState();
}

class _UserEditorSheetState extends ConsumerState<UserEditorSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  /// TEACHER CLASS-LOCK: agar teacher student add kar raha hai toh
  /// class+section AUTO-SELECT ho jaati hai aur change nahi hoti.
  bool _classLocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final me = ref.read(myProfileProvider).valueOrNull;
      if (me != null &&
          me.role.name == 'teacher' &&
          widget.role == 'student' &&
          me.classSection != null) {
        final List<String> parts = me.classSection!.split('-');
        setState(() {
          _selectedClass = parts.isNotEmpty ? parts[0] : null;
          _selectedSection = parts.length > 1 ? parts[1] : 'A';
          _classLocked = true;
        });
      }
    });
  }
  final TextEditingController _name = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _roll = TextEditingController();
  String? _selectedClass;
  String? _selectedSection;
  final TextEditingController _phone = TextEditingController();
  String? _busId;
  String? _stopId;
  bool _saving = false;

  bool get isStudent => widget.role == 'student';
  bool get isTeacherRole => widget.role == 'teacher';

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _roll.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    // Messenger/navigator ABHI capture — async ke baad context risky.
    final ScaffoldMessengerState m1 = ScaffoldMessenger.of(context);
    final NavigatorState n1 = Navigator.of(context);
    setState(() => _saving = true);

    // Students: login-id class+section+roll se banta hai (email nahi
    // chahiye). Staff: normal email.
    final String loginEmail = isStudent
        ? StudentLoginId.email(
            klass: _selectedClass!,
            section: _selectedSection!,
            roll: _roll.text,
          )
        : _email.text.trim();

    final Result<String> result =
        await ref.read(adminServiceProvider).provisionUser(
              email: loginEmail,
              fullName: _name.text.trim(),
              role: widget.role,
              temporaryPassword: _password.text,
              busId: _busId,
              stopId: isStudent ? _stopId : null,
              classSection: (isStudent || isTeacherRole) &&
                      _selectedClass != null &&
                      _selectedSection != null
                  ? SchoolClasses.label(_selectedClass!, _selectedSection!)
                  : null,
              rollNumber: isStudent ? _roll.text.trim() : null,
              phone: _phone.text.trim().isNotEmpty
                  ? _phone.text.trim()
                  : null,
              contactEmail: _email.text.trim().isNotEmpty
                  ? _email.text.trim()
                  : null,
            );
    if (!mounted) return;
    setState(() => _saving = false);
    result.when(
      ok: (_) {
        // 💚 WhatsApp share ke liye values ABHI capture karo (pop se
        // pehle) — controllers baad me dispose ho jate hain.
        final String waName = _name.text.trim();
        final String waClass = _selectedClass ?? '';
        final String waSection = _selectedSection ?? '';
        final String waRoll = _roll.text.trim();
        final String waPw = _password.text;
        final String waPhone = _phone.text.trim();
        final bool offerWa = isStudent;
        n1.pop();
        m1.showSnackBar(SnackBar(
          backgroundColor: const Color(0xFF1E8E3E),
          content: Text(
            '${isStudent ? 'Student' : widget.role == 'teacher' ? 'Teacher' : 'Driver'} account created ✓',
            style: const TextStyle(color: Colors.white),
          ),
        ),);
        // Account ban gaya → login details WhatsApp se parent ko bhejo
        if (offerWa) {
          showDialog<void>(
            context: n1.context,
            builder: (BuildContext ctx) => AlertDialog(
              title: const Row(
                children: <Widget>[
                  Icon(Icons.chat_rounded, color: Color(0xFF25D366)),
                  SizedBox(width: 8),
                  Expanded(child: Text('Send login on WhatsApp?')),
                ],
              ),
              content: Text(
                waPhone.isNotEmpty
                    ? 'Login details ka ready-made message parent ke '
                        'number ($waPhone) par WhatsApp me khulega — '
                        'aapko sirf SEND dabana hai.'
                    : 'Phone number nahi dala tha — WhatsApp khulega, '
                        'chat khud choose kar lena. Message ready-typed '
                        'hoga.',
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Later'),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                  ),
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    WhatsAppShare.sendCredentials(
                      phone: waPhone.isEmpty ? null : waPhone,
                      studentName: waName,
                      className: waClass,
                      section: waSection,
                      roll: waRoll,
                      password: waPw,
                      schoolName: NmbConstants.schoolName,
                    );
                  },
                  icon: const Icon(Icons.send_rounded, size: 18),
                  label: const Text('Open WhatsApp'),
                ),
              ],
            ),
          );
        }
      },
      err: (AppFailure f) {
        m1.showSnackBar(SnackBar(
          backgroundColor: const Color(0xFFC5221F),
          content: Text(f.message,
              style: const TextStyle(color: Colors.white),),
        ),);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Bus> buses =
        ref.watch(allBusesProvider).valueOrNull ?? const <Bus>[];
    final List<BusStop> stops = _busId == null
        ? const <BusStop>[]
        : ref.watch(stopsOfBusProvider(_busId!)).valueOrNull ??
            const <BusStop>[];

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  isStudent
                      ? 'Add student'
                      : widget.role == 'teacher'
                          ? 'Add class teacher'
                          : 'Add driver',
                  style: NmbTypography.screenTitle,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _name,
                  decoration:
                      const InputDecoration(hintText: 'Full name'),
                  validator: (String? v) =>
                      Validators.requiredField(v, label: 'Name'),
                ),
                const SizedBox(height: 12),
                // Staff: email REQUIRED (login isi se hota hai).
                // Student: email OPTIONAL (contact ke liye — login roll se).
                if (!isStudent) ...<Widget>[
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration:
                        const InputDecoration(hintText: 'Email'),
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 12),
                ] else ...<Widget>[
                  // 📧 Student/parent email (optional)
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'Email (optional — parent/student)',
                    ),
                    validator: (String? v) =>
                        (v == null || v.trim().isEmpty)
                            ? null
                            : Validators.email(v),
                  ),
                  const SizedBox(height: 12),
                ],
                TextFormField(
                  controller: _password,
                  decoration: InputDecoration(
                    hintText: isStudent ? 'Password' : 'Temporary password',
                    helperText: isStudent
                        ? 'Share this password with the student/parent.'
                        : 'User should change it after first sign-in.',
                  ),
                  validator: Validators.strongPassword,
                ),
                const SizedBox(height: 12),
                if (isStudent || isTeacherRole) ...<Widget>[
                  // Class & section — dropdowns (teacher ki bhi class hoti hai).
                  Row(
                    children: <Widget>[
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String>(
                          value: _selectedClass,
                          decoration:
                              const InputDecoration(hintText: 'Class'),
                          items: <DropdownMenuItem<String>>[
                            for (final String c in SchoolClasses.classes)
                              DropdownMenuItem<String>(
                                value: c,
                                child: Text('Class $c'),
                              ),
                          ],
                          onChanged: _classLocked
                              ? null
                              : (String? v) =>
                                  setState(() => _selectedClass = v),
                          validator: (String? v) =>
                              v == null ? 'Select class' : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: DropdownButtonFormField<String>(
                          value: _selectedSection,
                          decoration:
                              const InputDecoration(hintText: 'Section'),
                          items: <DropdownMenuItem<String>>[
                            for (final String s in SchoolClasses.sections)
                              DropdownMenuItem<String>(
                                value: s,
                                child: Text(s),
                              ),
                          ],
                          onChanged: _classLocked
                              ? null
                              : (String? v) =>
                                  setState(() => _selectedSection = v),
                          validator: (String? v) =>
                              v == null ? 'Select' : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (isStudent)
                  TextFormField(
                    controller: _roll,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      hintText: 'Roll number',
                      helperText:
                          'Student will log in with: Class + Section + '
                          'Roll + Password',
                    ),
                    validator: (String? v) {
                      if (!isStudent) return null;
                      final String r = (v ?? '').trim();
                      if (r.isEmpty) return 'Enter roll number';
                      if (int.tryParse(r) == null) return 'Numbers only';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: 'Parent mobile number (optional)',
                      helperText: 'For school records',
                    ),
                  ),
                  const SizedBox(height: 12),
                ] else ...<Widget>[
                  TextFormField(
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration:
                        const InputDecoration(hintText: 'Phone number'),
                  ),
                  const SizedBox(height: 12),
                ],
                DropdownButtonFormField<String>(
                  value: _busId,
                  decoration:
                      const InputDecoration(hintText: 'Assign to bus'),
                  items: <DropdownMenuItem<String>>[
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('No bus (assign later)'),
                    ),
                    for (final Bus b in buses)
                      DropdownMenuItem<String>(
                        value: b.id,
                        child: Text('${b.busNumber} — ${b.plateNumber}'),
                      ),
                  ],
                  onChanged: (String? v) => setState(() {
                    _busId = v;
                    _stopId = null;
                  }),
                ),
                if (isStudent && _busId != null) ...<Widget>[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _stopId,
                    decoration: const InputDecoration(
                        hintText: 'Assigned bus stop',),
                    items: <DropdownMenuItem<String>>[
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('No stop (assign later)'),
                      ),
                      for (final BusStop s in stops)
                        DropdownMenuItem<String>(
                          value: s.id,
                          child: Text(s.name),
                        ),
                    ],
                    onChanged: (String? v) => setState(() => _stopId = v),
                  ),
                ],
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Create account'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet to reassign an existing user's bus/stop or toggle access.
/// All changes go through admin-only Cloud Functions (claims + audit log).
class UserManageSheet extends ConsumerStatefulWidget {
  const UserManageSheet({super.key, required this.user});

  final AppUser user;

  static Future<void> show(BuildContext context, AppUser user) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => UserManageSheet(user: user),
      );

  @override
  ConsumerState<UserManageSheet> createState() => _UserManageSheetState();
}

class _UserManageSheetState extends ConsumerState<UserManageSheet> {

  /// Sheet band hone ke BAAD bhi message dikhane ke liye messenger/nav
  /// pehle capture karo — warna message kho jaata hai (context dead).
  void _finishOp({
    required NavigatorState nav,
    required ScaffoldMessengerState messenger,
    required Result<void> result,
    required String successMsg,
    bool popOnSuccess = true,
  }) {
    result.when(
      ok: (_) {
        if (popOnSuccess) nav.pop();
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF1E8E3E),
              content: Row(
                children: <Widget>[
                  const Icon(Icons.check_circle_outline_rounded,
                      color: Colors.white, size: 20,),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(successMsg,
                        style: const TextStyle(color: Colors.white),),
                  ),
                ],
              ),
            ),
          );
      },
      err: (AppFailure f) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFFC5221F),
              content: Text(f.message,
                  style: const TextStyle(color: Colors.white),),
            ),
          );
      },
    );
  }
  late String? _busId = widget.user.busId;
  late String? _stopId = widget.user.stopId;
  late final TextEditingController _editName =
      TextEditingController(text: widget.user.fullName);
  late final TextEditingController _editPhone =
      TextEditingController(text: widget.user.phone ?? '');
  bool _saving = false;

  bool get isStudent => widget.user.role.name == 'student';

  bool get isTeacherViewer =>
      ref.read(myProfileProvider).valueOrNull?.role.name == 'teacher';

  @override
  void dispose() {
    _editName.dispose();
    _editPhone.dispose();
    super.dispose();
  }

  Future<void> _saveProfileEdits() async {
    final String name = _editName.text.trim();
    if (name.isEmpty) {
      showNmbSnack(context, 'Name cannot be empty.', isError: true);
      return;
    }
    final adminSvc = ref.read(adminServiceProvider);
    final NavigatorState nav = Navigator.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    Result<void> result;
    try {
      result = await adminSvc.updateUserProfile(
        uid: widget.user.uid,
        data: <String, dynamic>{
          'fullName': name,
          'phone': _editPhone.text.trim().isEmpty
              ? null
              : _editPhone.text.trim(),
        },
      );
    } catch (e) {
      result = Err<void>(AppFailure('edit-crash', 'Save failed: $e'));
    }
    if (mounted) setState(() => _saving = false);
    _finishOp(
      nav: nav,
      messenger: messenger,
      result: result,
      successMsg: 'Profile saved ✓',
      popOnSuccess: false,
    );
  }

  Future<void> _deletePermanently() async {
    // Double confirmation — permanent delete galti se nahi hona chahiye.
    final bool ok1 = await showNmbConfirmDialog(
      context,
      title: 'Delete permanently?',
      message: '${widget.user.fullName} ka account, profile, alerts — sab '
          'HAMESHA ke liye delete ho jayega. Yeh wapas nahi ho sakta!',
      confirmLabel: 'Continue',
      destructive: true,
      icon: Icons.delete_forever_rounded,
    );
    if (!ok1 || !mounted) return;
    final bool ok2 = await showNmbConfirmDialog(
      context,
      title: 'Are you 100% sure?',
      message: 'Type-of-no-return: "${widget.user.fullName}" will be '
          'permanently removed. Confirm final delete?',
      confirmLabel: 'DELETE FOREVER',
      destructive: true,
      icon: Icons.warning_amber_rounded,
    );
    if (!ok2 || !mounted) return;

    // Service + PARENT context sheet band hone se PEHLE capture karo —
    // isi se success message pakka dikhega (sheet ke context se nahi).
    final adminSvc = ref.read(adminServiceProvider);
    final NavigatorState nav = Navigator.of(context);
    final ScaffoldMessengerState messenger =
        ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    Result<void> result;
    try {
      result = await adminSvc.deleteUserPermanently(widget.user);
    } catch (e) {
      result = Err<void>(AppFailure('delete-crash', 'Delete failed: $e'));
    }
    if (mounted) setState(() => _saving = false);
    result.when(
      ok: (_) {
        nav.pop();
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              backgroundColor: Color(0xFF1E8E3E),
              content: Row(
                children: <Widget>[
                  Icon(Icons.check_circle_outline_rounded,
                      color: Colors.white, size: 20,),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text('User permanently deleted ✓',
                        style: TextStyle(color: Colors.white),),
                  ),
                ],
              ),
            ),
          );
      },
      err: (AppFailure f) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFFC5221F),
              content: Text(f.message,
                  style: const TextStyle(color: Colors.white),),
            ),
          );
      },
    );
  }

  Future<void> _forceLogout() async {
    final adminSvc = ref.read(adminServiceProvider);
    final NavigatorState nav = Navigator.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final bool ok = await showNmbConfirmDialog(
      context,
      title: 'Force logout?',
      message: '${widget.user.fullName} will be signed out of their device '
          'immediately.',
      confirmLabel: 'Force logout',
      destructive: true,
      icon: Icons.phonelink_erase_rounded,
    );
    if (!ok || !mounted) return;
    setState(() => _saving = true);
    Result<void> result;
    try {
      result = await adminSvc.forceLogout(widget.user.uid);
    } catch (e) {
      result = Err<void>(AppFailure('fl-crash', 'Failed: $e'));
    }
    if (mounted) setState(() => _saving = false);
    _finishOp(
      nav: nav,
      messenger: messenger,
      result: result,
      successMsg: 'User signed out ✓',
    );
  }

  Future<void> _resetPassword() async {
    final adminSvc = ref.read(adminServiceProvider);
    final NavigatorState nav = Navigator.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final TextEditingController pw = TextEditingController();
    final bool? go = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Set a new password'),
        content: TextField(
          controller: pw,
          decoration: const InputDecoration(
            hintText: 'New password (min 10, capital + number)',
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (go != true || !mounted) return;
    if (Validators.strongPassword(pw.text) != null) {
      showNmbSnack(context,
          'Password too weak — min 10 chars, 1 capital, 1 number.',
          isError: true,);
      return;
    }
    setState(() => _saving = true);
    Result<void> result;
    try {
      result = await adminSvc.resetStudentPassword(
        student: widget.user,
        newPassword: pw.text,
      );
    } catch (e) {
      result = Err<void>(AppFailure('rp-crash', 'Reset failed: $e'));
    }
    if (mounted) setState(() => _saving = false);
    // 💚 PEHLE WhatsApp dialog (root navigator par) — phir sheet pop.
    // (Pop ke baad mounted false ho jata, isliye order ye hai.)
    if (result is Ok<void> && mounted) {
      final List<String> parts =
          (widget.user.classSection ?? '-').split('-');
      showDialog<void>(
        context: context,
        builder: (BuildContext ctx) => AlertDialog(
          title: const Row(
            children: <Widget>[
              Icon(Icons.chat_rounded, color: Color(0xFF25D366)),
              SizedBox(width: 8),
              Expanded(child: Text('Send new password on WhatsApp?')),
            ],
          ),
          content: Text(
            (widget.user.phone ?? '').isNotEmpty
                ? 'Naya password ready-made message ke saath parent ke '
                    'number (${widget.user.phone}) par khulega.'
                : 'Is student ka phone number saved nahi hai — WhatsApp '
                    'khulega, chat khud choose kar lena.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Later'),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF25D366),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                WhatsAppShare.sendCredentials(
                  phone: (widget.user.phone ?? '').isEmpty
                      ? null
                      : widget.user.phone,
                  studentName: widget.user.fullName,
                  className: parts.first,
                  section: parts.length > 1 ? parts[1] : 'A',
                  roll: widget.user.rollNumber ?? '-',
                  password: pw.text,
                  schoolName: NmbConstants.schoolName,
                );
              },
              icon: const Icon(Icons.send_rounded, size: 18),
              label: const Text('Open WhatsApp'),
            ),
          ],
        ),
      );
    }
    _finishOp(
      nav: nav,
      messenger: messenger,
      result: result,
      successMsg: 'Password reset ✓ — student logs in with new password',
    );
  }

  Future<void> _saveAssignment() async {
    final adminSvc = ref.read(adminServiceProvider);
    final NavigatorState nav = Navigator.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    setState(() => _saving = true);
    Result<void> result;
    try {
      result = isStudent
          ? await adminSvc.assignUserToBus(
              uid: widget.user.uid,
              busId: _busId,
              stopId: _stopId,
            )
          : await adminSvc.assignDriverToBus(
              driverUid: widget.user.uid,
              busId: _busId,
            );
    } catch (e) {
      result = Err<void>(AppFailure('save-crash', 'Save failed: $e'));
    }
    if (mounted) setState(() => _saving = false);
    _finishOp(
      nav: nav,
      messenger: messenger,
      result: result,
      successMsg: 'Assignment saved ✓',
    );
  }

  Future<void> _toggleActive() async {
    final bool disable = widget.user.isActive;
    final adminSvc = ref.read(adminServiceProvider);
    final NavigatorState nav = Navigator.of(context);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final bool confirmed = await showNmbConfirmDialog(
      context,
      title: disable ? 'Disable account?' : 'Enable account?',
      message: disable
          ? '${widget.user.fullName} will be signed out and blocked from '
              'the app until re-enabled.'
          : '${widget.user.fullName} will regain access to the app.',
      confirmLabel: disable ? 'Disable' : 'Enable',
      destructive: disable,
      icon: disable ? Icons.block_rounded : Icons.check_circle_outline,
    );
    if (!confirmed || !mounted) return;
    setState(() => _saving = true);
    Result<void> result;
    try {
      result = await adminSvc.setAccountActive(
        uid: widget.user.uid,
        active: !widget.user.isActive,
      );
    } catch (e) {
      result = Err<void>(AppFailure('toggle-crash', 'Failed: $e'));
    }
    if (mounted) setState(() => _saving = false);
    _finishOp(
      nav: nav,
      messenger: messenger,
      result: result,
      successMsg: disable ? 'Account disabled ✓' : 'Account enabled ✓',
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Bus> buses =
        ref.watch(allBusesProvider).valueOrNull ?? const <Bus>[];
    final List<BusStop> stops = _busId == null
        ? const <BusStop>[]
        : ref.watch(stopsOfBusProvider(_busId!)).valueOrNull ??
            const <BusStop>[];

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(widget.user.fullName, style: NmbTypography.screenTitle),
            Text(
              isStudent
                  ? 'Class ${widget.user.classSection ?? '?'} • '
                      'Roll ${widget.user.rollNumber ?? '?'}'
                  : widget.user.email,
              style: NmbTypography.bodySecondary,
            ),
            const SizedBox(height: 18),

            // ── Profile edit ──
            TextField(
              controller: _editName,
              decoration: const InputDecoration(hintText: 'Full name'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _editPhone,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                hintText: isStudent
                    ? 'Parent mobile number'
                    : 'Phone number',
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _saving ? null : _saveProfileEdits,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save profile changes'),
            ),
            const SizedBox(height: 18),
            const Divider(),
            const SizedBox(height: 10),

            if (!isTeacherViewer) DropdownButtonFormField<String>(
              value: _busId,
              decoration: const InputDecoration(hintText: 'Assigned bus'),
              items: <DropdownMenuItem<String>>[
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('No bus'),
                ),
                for (final Bus b in buses)
                  DropdownMenuItem<String>(
                    value: b.id,
                    child: Text('${b.busNumber} — ${b.plateNumber}'),
                  ),
              ],
              onChanged: (String? v) => setState(() {
                _busId = v;
                _stopId = null;
              }),
            ),
            if (!isTeacherViewer && isStudent && _busId != null) ...<Widget>[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: stops.any((BusStop s) => s.id == _stopId)
                    ? _stopId
                    : null,
                decoration:
                    const InputDecoration(hintText: 'Assigned stop'),
                items: <DropdownMenuItem<String>>[
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('No stop'),
                  ),
                  for (final BusStop s in stops)
                    DropdownMenuItem<String>(
                      value: s.id,
                      child: Text(s.name),
                    ),
                ],
                onChanged: (String? v) => setState(() => _stopId = v),
              ),
            ],
            if (!isTeacherViewer) const SizedBox(height: 18),
            if (!isTeacherViewer) FilledButton(
              onPressed: _saving ? null : _saveAssignment,
              child: const Text('Save assignment'),
            ),
            const SizedBox(height: 10),
            // ── Device / login status (single-device security) ──
            if (!isTeacherViewer) const SizedBox(height: 10),
            if (!isTeacherViewer) Builder(
              builder: (BuildContext ctx) {
                final Map<String, dynamic>? dev = widget.user.activeDevice;
                final String? devId = dev?['id'] as String?;
                final bool loggedIn = devId != null &&
                    devId.isNotEmpty &&
                    devId != 'REVOKED';
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: loggedIn
                        ? const Color(0xFFE2F3E7)
                        : const Color(0xFFF1F3F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(
                        loggedIn
                            ? Icons.phone_android_rounded
                            : Icons.phonelink_erase_rounded,
                        color: loggedIn
                            ? const Color(0xFF1E8E3E)
                            : const Color(0xFF8A94A6),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              loggedIn
                                  ? 'Logged in on: '
                                      '${dev!['name'] ?? 'a device'}'
                                  : 'Not logged in on any device',
                              style: NmbTypography.cardTitle
                                  .copyWith(fontSize: 14),
                            ),
                            if (loggedIn && dev!['at'] != null)
                              Text(
                                'Since ${DateTime.fromMillisecondsSinceEpoch(dev['at'] as int).toString().substring(0, 16)}',
                                style: NmbTypography.caption,
                              ),
                          ],
                        ),
                      ),
                      if (loggedIn)
                        TextButton(
                          onPressed: _saving ? null : _forceLogout,
                          child: const Text('Force logout'),
                        ),
                    ],
                  ),
                );
              },
            ),
            if (!isTeacherViewer && isStudent) ...<Widget>[
              const SizedBox(height: 10),
              OutlinedButton.icon(
                onPressed: _saving ? null : _resetPassword,
                icon: const Icon(Icons.lock_reset_rounded),
                label: const Text('Reset student password'),
              ),
            ],
            const SizedBox(height: 10),
            if (!isTeacherViewer) OutlinedButton.icon(
              onPressed: _saving ? null : _toggleActive,
              icon: Icon(
                widget.user.isActive
                    ? Icons.block_rounded
                    : Icons.check_circle_outline_rounded,
              ),
              label: Text(
                widget.user.isActive
                    ? 'Disable account'
                    : 'Enable account',
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: NmbColors.danger,
                side: const BorderSide(color: NmbColors.danger),
              ),
              onPressed: _saving ? null : _deletePermanently,
              icon: const Icon(Icons.delete_forever_rounded),
              label: const Text('Delete permanently'),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
