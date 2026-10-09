import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/app_language.dart';
import '../../../core/constants/nmb_constants.dart';
import '../../../core/theme/app_theme_manager.dart';
import '../../../core/theme/nmb_colors.dart';
import '../../../core/theme/nmb_typography.dart';
import '../../../core/widgets/nmb_card.dart';
import '../../../core/widgets/nmb_dialogs.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/app_user.dart';
import '../../../models/bus.dart';
import '../../../models/bus_stop.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';
import '../../../services/auth_service.dart';
import '../../../services/attendance_service.dart';
import '../../shared/student_avatar.dart';
import '../widgets/digital_id_card.dart';

/// v1.1.1 Profile — blue gradient header with big avatar + name + class,
/// then info cards (assignment, school contact) and actions.
class StudentProfileScreen extends ConsumerWidget {
  const StudentProfileScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final AuthSession? session = ref.read(currentSessionProvider);
    // Capture EVERYTHING from ref BEFORE any await/pop — after the widget
    // is disposed, ref must not be touched ("ref after disposed" fix).
    final notifSvc = ref.read(notificationServiceProvider);
    final devSvc = ref.read(deviceSessionServiceProvider);
    final fsSvc = ref.read(firestoreServiceProvider);
    final authSvc = ref.read(authServiceProvider);
    final bool confirmed = await showNmbConfirmDialog(
      context,
      title: 'Log out?',
      message:
          'You will need your Class + Roll number + password to sign back in.',
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
    final BusStop? stop = ref.watch(myAssignedStopProvider);
    final Map<String, dynamic>? school =
        ref.watch(schoolConfigProvider).valueOrNull;

    return Scaffold(
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
              message: 'Please contact the school office.',
            );
          }
          final List<Map<String, dynamic>> remarks =
              ref.watch(myRemarksProvider).valueOrNull ??
                  const <Map<String, dynamic>>[];
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: <Widget>[
              // ── Header ──
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: themeGradient(),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(28),
                      bottomRight: Radius.circular(28),
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Text(
                              tr('Profile', 'प्रोफ़ाइल'),
                              style: NmbTypography.screenTitle
                                  .copyWith(color: Colors.white),
                            ),
                            const Spacer(),
                            IconButton(
                              tooltip: 'Settings',
                              onPressed: () =>
                                  context.go('/student/profile/settings'),
                              icon: const Icon(
                                Icons.settings_outlined,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        StudentAvatar(
                          user: me,
                          radius: 46,
                          showOnlineDot: true,
                          online: true,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          me.fullName,
                          style: NmbTypography.screenTitle
                              .copyWith(color: Colors.white),
                        ),
                        if (me.classSection != null)
                          Text(
                            'Class ${me.classSection}'
                            '${me.rollNumber != null ? ' • Roll ${me.rollNumber}' : ''}',
                            style: NmbTypography.bodySecondary
                                .copyWith(color: Colors.white70),
                          ),
                        Text(
                          NmbConstants.schoolName,
                          style: NmbTypography.caption
                              .copyWith(color: Colors.white60),
                        ),
                        const SizedBox(height: 10),
                        // Quick chips: age, blood, admission
                        Wrap(
                          spacing: 8,
                          children: <Widget>[
                            if (me.ageYears != null)
                              _headerChip('🎂 ${me.ageYears} yrs'),
                            if (me.bloodGroup != null)
                              _headerChip('🩸 ${me.bloodGroup}'),
                            if (bus != null) _headerChip('🚌 ${bus.busNumber}'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate(<Widget>[
                    // ── DIGITAL ID CARD ──
                    DigitalIdCard(student: me, bus: bus),
                    const SizedBox(height: 14),

                    // ── MY ATTENDANCE (class — teacher lagata hai) ──
                    if (me.classSection != null) ...<Widget>[
                      _AttendanceCard(me: me),
                      const SizedBox(height: 14),
                    ],

                    // ── Assignment ──
                    NmbCard(
                      child: Column(
                        children: <Widget>[
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: NmbColors.accentSoft,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.directions_bus_rounded,
                                color: NmbColors.accentDark,
                              ),
                            ),
                            title: Text(tr('Assigned bus', 'असाइन बस')),
                            trailing: Text(
                              bus?.busNumber ??
                                  tr('Not assigned', 'असाइन नहीं'),
                              style: NmbTypography.cardTitle,
                            ),
                          ),
                          const Divider(),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: const Color(0xFFEFEAFF),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.pin_drop_rounded,
                                color: Color(0xFF7B61FF),
                              ),
                            ),
                            title: Text(tr('Assigned stop', 'असाइन स्टॉप')),
                            trailing: Text(
                              stop?.name ?? tr('Not assigned', 'असाइन नहीं'),
                              style: NmbTypography.cardTitle,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Bus and stop assignments are managed by the school.',
                            style: NmbTypography.caption,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Personal details — HAMESHA dikhta hai; missing
                    //    fields "—" (school office bharega) ──
                    NmbCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            tr('Personal Details', 'व्यक्तिगत जानकारी'),
                            style: NmbTypography.sectionTitle,
                          ),
                          const SizedBox(height: 10),
                          _InfoLine(
                            label: tr("Father's Name", 'पिता का नाम'),
                            value: me.fatherName ?? '—',
                          ),
                          _InfoLine(
                            label: tr("Mother's Name", 'माता का नाम'),
                            value: me.motherName ?? '—',
                          ),
                          _InfoLine(
                            label: tr('Date of Birth', 'जन्म तिथि'),
                            value: me.dobFormatted ?? '—',
                          ),
                          _InfoLine(
                            label: tr('Blood Group', 'ब्लड ग्रुप'),
                            value: me.bloodGroup ?? '—',
                          ),
                          _InfoLine(
                            label: tr('Admission No.', 'प्रवेश संख्या'),
                            value: me.admissionNumber ?? '—',
                          ),
                          _InfoLine(
                            label: tr('Address', 'पता'),
                            value: me.address ??
                                me.settingsMapValue('addressSelf') ??
                                '—',
                          ),
                          _InfoLine(
                            label: tr('Email', 'ईमेल'),
                            value: me.contactEmail ?? '—',
                          ),
                          _InfoLine(
                            label: tr('Parent Phone', 'अभिभावक फोन'),
                            value: me.phone ??
                                me.settingsMapValue('parentPhoneSelf') ??
                                '—',
                          ),
                          const SizedBox(height: 4),
                          Text(
                            tr(
                              'Missing info? School office can update it.',
                              'जानकारी अधूरी है? स्कूल ऑफिस अपडेट कर सकता है।',
                            ),
                            style: NmbTypography.caption,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Documents — HAMESHA dikhta hai; har doc ka
                    //    Submitted/Pending status ──
                    NmbCard(
                      color:
                          me.pendingDocuments.isEmpty && me.documents.isNotEmpty
                              ? NmbColors.successSoft
                              : NmbColors.warningSoft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Icon(
                                me.pendingDocuments.isEmpty &&
                                        me.documents.isNotEmpty
                                    ? Icons.task_alt_rounded
                                    : Icons.description_outlined,
                                color: me.pendingDocuments.isEmpty &&
                                        me.documents.isNotEmpty
                                    ? NmbColors.success
                                    : NmbColors.warning,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  tr('My Documents', 'मेरे दस्तावेज़'),
                                  style: NmbTypography.sectionTitle,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          for (final String d in SchoolDocuments.all)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: <Widget>[
                                  Icon(
                                    (me.documents[d] ?? false)
                                        ? Icons.check_circle_rounded
                                        : Icons.radio_button_unchecked,
                                    size: 18,
                                    color: (me.documents[d] ?? false)
                                        ? NmbColors.success
                                        : NmbColors.textTertiary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(d, style: NmbTypography.body),
                                  ),
                                  Text(
                                    (me.documents[d] ?? false)
                                        ? tr('Submitted ✓', 'जमा ✓')
                                        : tr('Pending', 'बाकी'),
                                    style: NmbTypography.caption.copyWith(
                                      color: (me.documents[d] ?? false)
                                          ? NmbColors.success
                                          : NmbColors.warning,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          if (me.pendingDocuments.isNotEmpty ||
                              me.documents.isEmpty) ...<Widget>[
                            const SizedBox(height: 4),
                            Text(
                              tr(
                                'Please submit pending documents to the school office.',
                                'कृपया बाकी दस्तावेज़ स्कूल ऑफिस में जमा करें।',
                              ),
                              style: NmbTypography.bodySecondary,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    if (remarks.isNotEmpty) ...<Widget>[
                      NmbCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Teacher remarks',
                              style: NmbTypography.sectionTitle,
                            ),
                            const SizedBox(height: 8),
                            for (final Map<String, dynamic> remark
                                in remarks.take(8))
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Icon(
                                      Icons.star_rounded,
                                      color: NmbColors.accentDark,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        '${remark['category']}: ${remark['text']}',
                                        style: NmbTypography.body,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // ── Fees ──
                    if (me.feeTotal > 0) ...<Widget>[
                      NmbCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              tr('School Fees', 'स्कूल फीस'),
                              style: NmbTypography.sectionTitle,
                            ),
                            const SizedBox(height: 12),
                            // Progress bar: kitna paid
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: me.feeTotal > 0
                                    ? (me.feePaid / me.feeTotal).clamp(0.0, 1.0)
                                    : 0,
                                minHeight: 10,
                                backgroundColor: NmbColors.divider,
                                valueColor: const AlwaysStoppedAnimation<Color>(
                                  NmbColors.success,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              me.feeTotal > 0
                                  ? '${((me.feePaid / me.feeTotal) * 100).clamp(0, 100).toStringAsFixed(0)}% paid'
                                  : '',
                              style: NmbTypography.caption.copyWith(
                                color: NmbColors.success,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: _FeeBox(
                                    label: 'Total',
                                    value: me.feeTotal,
                                    color: NmbColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _FeeBox(
                                    label: 'Paid',
                                    value: me.feePaid,
                                    color: NmbColors.success,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _FeeBox(
                                    label: 'Due',
                                    value: me.feeDue,
                                    color: me.feeDue > 0
                                        ? NmbColors.danger
                                        : NmbColors.success,
                                  ),
                                ),
                              ],
                            ),
                            if (me.feeDueDate != null &&
                                me.feeDue > 0) ...<Widget>[
                              const SizedBox(height: 8),
                              Text(
                                'Due date: ${me.feeDueDate}',
                                style: NmbTypography.caption.copyWith(
                                  color: NmbColors.warning,
                                ),
                              ),
                            ],
                            // FEES 2.0: Payment history (PhonePe style)
                            if ((me.fees?['history'] as List?)?.isNotEmpty ??
                                false) ...<Widget>[
                              const SizedBox(height: 10),
                              const Divider(),
                              Text(
                                'Payment History',
                                style: NmbTypography.caption.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              for (final dynamic h
                                  in ((me.fees!['history'] as List?) ??
                                          <dynamic>[])
                                      .take(5))
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: Row(
                                    children: <Widget>[
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: NmbColors.success,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Rs. ${((h as Map)['amount'] as num?)?.toStringAsFixed(0) ?? '?'}',
                                          style: NmbTypography.body.copyWith(
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        h['at'] != null
                                            ? DateTime
                                                .fromMillisecondsSinceEpoch(
                                                h['at'] as int,
                                              ).toString().substring(0, 10)
                                            : '',
                                        style: NmbTypography.caption,
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                            if (me.feeDue > 0 &&
                                (school?['upiId'] as String?) !=
                                    null) ...<Widget>[
                              const SizedBox(height: 12),
                              FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: NmbColors.success,
                                ),
                                onPressed: () => _payViaUpi(
                                  context,
                                  upiId: school!['upiId'] as String,
                                  schoolName:
                                      (school['name'] as String?) ?? 'School',
                                  amount: me.feeDue,
                                  student: me,
                                ),
                                icon: const Icon(
                                  Icons.currency_rupee_rounded,
                                ),
                                label: Text(
                                  'Pay Rs. ${me.feeDue.toStringAsFixed(0)} via UPI',
                                ),
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Opens your UPI app (GPay/PhonePe/Paytm). '
                                'After payment, school office will update '
                                'your record.',
                                style: NmbTypography.caption,
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],

                    // ── School contact ──
                    NmbCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            tr('Contact School', 'स्कूल से संपर्क'),
                            style: NmbTypography.sectionTitle,
                          ),
                          const SizedBox(height: 10),
                          _ContactRow(
                            icon: Icons.school_rounded,
                            text: (school?['name'] as String?) ??
                                NmbConstants.schoolName,
                          ),
                          if (school?['phone'] != null)
                            _ContactRow(
                              icon: Icons.call_rounded,
                              text: school!['phone'] as String,
                            ),
                          if (school?['email'] != null)
                            _ContactRow(
                              icon: Icons.mail_rounded,
                              text: school!['email'] as String,
                            ),
                          if (school?['address'] != null)
                            _ContactRow(
                              icon: Icons.location_on_rounded,
                              text: school!['address'] as String,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Actions ──
                    NmbCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 4,
                      ),
                      child: Column(
                        children: <Widget>[
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.settings_outlined,
                              color: NmbColors.textSecondary,
                            ),
                            title: Text(tr('Settings', 'सेटिंग्स')),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () =>
                                context.go('/student/profile/settings'),
                          ),
                          const Divider(height: 1),
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: const Icon(
                              Icons.info_outline_rounded,
                              color: NmbColors.textSecondary,
                            ),
                            title: Text(tr('About App', 'ऐप के बारे में')),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            // LICENSE-FREE about (no license page)
                            onTap: () => showDialog<void>(
                              context: context,
                              builder: (BuildContext ctx) => AlertDialog(
                                title: const Text(NmbConstants.appName),
                                content: const Text(
                                  'Version 1.0\n'
                                  '${NmbConstants.schoolName}\n'
                                  'Secure school bus tracking app.',
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () => Navigator.of(ctx).pop(),
                                    child: const Text('OK'),
                                  ),
                                ],
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
                      label: Text(tr('Logout', 'लॉगआउट')),
                    ),
                    const SizedBox(height: 24),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

Future<void> _payViaUpi(
  BuildContext context, {
  required String upiId,
  required String schoolName,
  required double amount,
  required AppUser student,
}) async {
  final String note = Uri.encodeComponent(
    'Fees ${student.fullName} ${student.classSection ?? ''}',
  );
  final Uri uri = Uri.parse(
    'upi://pay?pa=$upiId&pn=${Uri.encodeComponent(schoolName)}'
    '&am=${amount.toStringAsFixed(2)}&cu=INR&tn=$note',
  );
  try {
    final bool ok = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (!ok && context.mounted) {
      showNmbSnack(
        context,
        'No UPI app found. Please pay at the school office.',
        isError: true,
      );
    }
  } catch (_) {
    if (context.mounted) {
      showNmbSnack(
        context,
        'Could not open UPI app. Please pay at the school office.',
        isError: true,
      );
    }
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 110,
            child: Text(label, style: NmbTypography.caption),
          ),
          Expanded(
            child: Text(
              value,
              style: NmbTypography.body.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeeBox extends StatelessWidget {
  const _FeeBox({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final double value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: NmbColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: <Widget>[
          Text(
            'Rs. ${value.toStringAsFixed(0)}',
            style: NmbTypography.cardTitle.copyWith(color: color),
          ),
          Text(label, style: NmbTypography.caption),
        ],
      ),
    );
  }
}

class _AttendanceCard extends ConsumerWidget {
  const _AttendanceCard({required this.me});

  final AppUser me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AttendanceService svc = ref.watch(attendanceServiceProvider);
    return FutureBuilder<({int present, int absent, Map<String, bool> days})>(
      future: svc.myMonth(
        classSection: me.classSection!,
        uid: me.uid,
        month: DateTime.now(),
      ),
      builder: (BuildContext ctx, snapshot) {
        final int present = snapshot.data?.present ?? 0;
        final int absent = snapshot.data?.absent ?? 0;
        final int total = present + absent;
        final double pct = total > 0 ? present / total : 1.0;
        return NmbCard(
          onTap: () => context.go('/student/home/attendance'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Icon(
                    Icons.fact_check_rounded,
                    color: NmbColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tr('My Attendance', 'मेरी उपस्थिति'),
                      style: NmbTypography.sectionTitle,
                    ),
                  ),
                  Text(
                    tr('Calendar →', 'कैलेंडर →'),
                    style: NmbTypography.caption.copyWith(
                      color: NmbColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (snapshot.connectionState == ConnectionState.waiting)
                const LinearProgressIndicator(minHeight: 6)
              else if (total == 0)
                const Text(
                  'Abhi attendance nahi lagi. Class teacher lagayenge.',
                  style: NmbTypography.bodySecondary,
                )
              else ...<Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _attStat(
                        'Present',
                        '$present',
                        NmbColors.success,
                        NmbColors.successSoft,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _attStat(
                        'Absent',
                        '$absent',
                        NmbColors.danger,
                        NmbColors.dangerSoft,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _attStat(
                        'Percent',
                        '${(pct * 100).toStringAsFixed(0)}%',
                        pct >= 0.75 ? NmbColors.success : NmbColors.warning,
                        pct >= 0.75
                            ? NmbColors.successSoft
                            : NmbColors.warningSoft,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: pct,
                    minHeight: 8,
                    backgroundColor: NmbColors.divider,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      pct >= 0.75 ? NmbColors.success : NmbColors.warning,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _attStat(String label, String value, Color fg, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: <Widget>[
          Text(
            value,
            style: NmbTypography.cardTitle.copyWith(color: fg),
          ),
          Text(label, style: NmbTypography.caption),
        ],
      ),
    );
  }
}

Widget _headerChip(String text) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: Colors.white24,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 12,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 18, color: NmbColors.textTertiary),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: NmbTypography.bodySecondary)),
        ],
      ),
    );
  }
}
