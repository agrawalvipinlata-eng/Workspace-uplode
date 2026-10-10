import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_language.dart';
import '../../../core/theme/nmb_colors.dart';
import '../../../core/theme/nmb_typography.dart';
import '../../../core/widgets/nmb_card.dart';
import '../../../core/widgets/responsive_scaffold_body.dart';
import '../../../models/app_user.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';

/// Parent-facing snapshot of the student's school day.
///
/// This first phase reuses the secured student streams already in the app.
/// It intentionally does not duplicate Firestore data or store documents in
/// Firestore; the document vault will be added in the next phase.
class ParentDashboardScreen extends ConsumerWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppUser? student = ref.watch(myProfileProvider).valueOrNull;
    final int unread = ref.watch(unreadCountProvider);
    final List<Map<String, dynamic>> remarks =
        ref.watch(myRemarksProvider).valueOrNull ?? const [];

    if (student == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final String? classSection = student.classSection;
    final Future<({int present, int absent, Map<String, bool> days})>?
        attendanceFuture = classSection == null
            ? null
            : ref.read(attendanceServiceProvider).myMonth(
                  classSection: classSection,
                  uid: student.uid,
                  month: DateTime.now(),
                );

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Parent Dashboard', 'पैरेंट डैशबोर्ड')),
      ),
      body: ResponsiveBody(
        child: ListView(
          children: <Widget>[
            Text(
              '${tr('Hello', 'नमस्ते')}, ${student.firstName}',
              style: NmbTypography.screenTitle,
            ),
            const SizedBox(height: 4),
            Text(
              tr('Your child’s school snapshot', 'आपके बच्चे की स्कूल जानकारी'),
              style: NmbTypography.bodySecondary,
            ),
            const SizedBox(height: 16),
            NmbCard(
              color: NmbColors.primarySoft,
              child: Row(
                children: <Widget>[
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: NmbColors.primary,
                    child: Text(
                      student.firstName.characters.first.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(student.fullName, style: NmbTypography.cardTitle),
                        const SizedBox(height: 3),
                        Text(
                          '${tr('Class', 'क्लास')}: ${student.classSection ?? '—'}  •  '
                          '${tr('Roll', 'रोल')}: ${student.rollNumber ?? '—'}',
                          style: NmbTypography.bodySecondary,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.currency_rupee_rounded,
                    label: tr('Fee due', 'फीस बाकी'),
                    value: '₹${student.feeDue.toStringAsFixed(0)}',
                    color: student.feeDue > 0
                        ? NmbColors.warning
                        : NmbColors.success,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SummaryCard(
                    icon: Icons.notifications_rounded,
                    label: tr('Alerts', 'सूचनाएं'),
                    value: '$unread',
                    color: NmbColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            NmbCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(tr('This month attendance', 'इस महीने की उपस्थिति'),
                      style: NmbTypography.sectionTitle),
                  const SizedBox(height: 12),
                  if (attendanceFuture == null)
                    Text(
                        tr('Class is not assigned yet.',
                            'क्लास अभी असाइन नहीं है.'),
                        style: NmbTypography.bodySecondary)
                  else
                    FutureBuilder<
                        ({int present, int absent, Map<String, bool> days})>(
                      future: attendanceFuture,
                      builder: (BuildContext context,
                          AsyncSnapshot<
                                  ({
                                    int present,
                                    int absent,
                                    Map<String, bool> days
                                  })>
                              snapshot) {
                        if (!snapshot.hasData) {
                          return const LinearProgressIndicator();
                        }
                        final value = snapshot.data!;
                        final int total = value.present + value.absent;
                        final int percent = total == 0
                            ? 0
                            : ((value.present / total) * 100).round();
                        return Row(
                          children: <Widget>[
                            _AttendanceValue(
                                label: tr('Present', 'उपस्थित'),
                                value: '${value.present}',
                                color: NmbColors.success),
                            _AttendanceValue(
                                label: tr('Absent', 'अनुपस्थित'),
                                value: '${value.absent}',
                                color: NmbColors.danger),
                            _AttendanceValue(
                                label: tr('Rate', 'प्रतिशत'),
                                value: '$percent%',
                                color: NmbColors.primary),
                          ],
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            NmbCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(tr('Homework overview', 'होमवर्क जानकारी'),
                      style: NmbTypography.sectionTitle),
                  const SizedBox(height: 10),
                  if (classSection == null)
                    Text(
                        tr('No class assigned yet.',
                            'क्लास अभी असाइन नहीं है.'),
                        style: NmbTypography.bodySecondary)
                  else
                    StreamBuilder<List<Map<String, dynamic>>>(
                      stream: ref
                          .read(schoolworkServiceProvider)
                          .watchHomework(classSection),
                      builder: (BuildContext context,
                          AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                        if (!snapshot.hasData)
                          return const LinearProgressIndicator();
                        final int count = snapshot.data!.length;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Icon(Icons.menu_book_rounded,
                              color: NmbColors.accentDark),
                          title: Text(
                              '$count ${tr('homework items', 'होमवर्क आइटम')}'),
                          subtitle: Text(tr(
                              'Open Modules → Homework for details.',
                              'विवरण के लिए Modules → Homework खोलें.')),
                        );
                      },
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            NmbCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.star_rounded, color: NmbColors.accentDark),
                title: Text(
                    '${remarks.length} ${tr('teacher remarks', 'टीचर remarks')}'),
                subtitle: Text(tr(
                    'Recent feedback is available in your profile.',
                    'Recent feedback profile में उपलब्ध है.')),
              ),
            ),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => NmbCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(value, style: NmbTypography.sectionTitle),
            Text(label, style: NmbTypography.caption),
          ],
        ),
      );
}

class _AttendanceValue extends StatelessWidget {
  const _AttendanceValue(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Column(
          children: <Widget>[
            Text(value,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w800, color: color)),
            const SizedBox(height: 2),
            Text(label, style: NmbTypography.caption),
          ],
        ),
      );
}
