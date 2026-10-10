import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_language.dart';
import '../../../core/theme/nmb_colors.dart';
import '../../../core/theme/nmb_typography.dart';
import '../../../core/widgets/nmb_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/app_user.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';

class StudentProgressScreen extends ConsumerWidget {
  const StudentProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppUser? me = ref.watch(myProfileProvider).valueOrNull;
    if (me?.classSection == null) {
      return const Scaffold(
          body: EmptyState(
              icon: Icons.insights_rounded,
              title: 'No progress yet',
              message:
                  'Class details are required to build your progress summary.'));
    }
    final List<Map<String, dynamic>> remarks =
        ref.watch(myRemarksProvider).valueOrNull ??
            const <Map<String, dynamic>>[];
    return Scaffold(
      appBar: AppBar(title: Text(tr('My Progress', 'मेरा प्रोग्रेस'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text(tr('Overall learning snapshot', 'कुल पढ़ाई की झलक'),
              style: NmbTypography.screenTitle),
          const SizedBox(height: 4),
          Text(
              tr('Attendance, results, homework and teacher feedback in one place.',
                  'Attendance, result, homework और teacher feedback एक जगह.'),
              style: NmbTypography.bodySecondary),
          const SizedBox(height: 16),
          FutureBuilder<({int present, int absent, Map<String, bool> days})>(
            future: ref.read(attendanceServiceProvider).myMonth(
                classSection: me!.classSection!,
                uid: me.uid,
                month: DateTime.now()),
            builder: (BuildContext context,
                AsyncSnapshot<
                        ({int present, int absent, Map<String, bool> days})>
                    snapshot) {
              if (!snapshot.hasData) return const LinearProgressIndicator();
              final value = snapshot.data!;
              final int total = value.present + value.absent;
              final int percent =
                  total == 0 ? 0 : (value.present / total * 100).round();
              return _MetricCard(
                  icon: Icons.fact_check_rounded,
                  title: tr('Attendance this month', 'इस महीने की attendance'),
                  value: '$percent%',
                  detail: '${value.present} present • ${value.absent} absent',
                  color: percent >= 75 ? NmbColors.success : NmbColors.warning);
            },
          ),
          const SizedBox(height: 10),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: ref.read(examResultServiceProvider).watchForStudent(me.uid),
            builder: (BuildContext context,
                AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
              final List<Map<String, dynamic>> rows =
                  snapshot.data ?? const <Map<String, dynamic>>[];
              final double marks = rows.fold<double>(0,
                  (double s, Map<String, dynamic> r) => s + _num(r['marks']));
              final double max = rows.fold<double>(
                  0,
                  (double s, Map<String, dynamic> r) =>
                      s + _num(r['maxMarks']));
              final int percent = max == 0 ? 0 : (marks / max * 100).round();
              return _MetricCard(
                  icon: Icons.assessment_rounded,
                  title: tr('Exam performance', 'परीक्षा प्रदर्शन'),
                  value: max == 0 ? '—' : '$percent%',
                  detail:
                      '${rows.length} subject result${rows.length == 1 ? '' : 's'} published',
                  color: NmbColors.primary);
            },
          ),
          const SizedBox(height: 10),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: ref
                .read(schoolworkServiceProvider)
                .watchHomework(me.classSection!),
            builder: (BuildContext context,
                    AsyncSnapshot<List<Map<String, dynamic>>> snapshot) =>
                _MetricCard(
                    icon: Icons.menu_book_rounded,
                    title: tr('Homework posted', 'दिया गया homework'),
                    value: '${snapshot.data?.length ?? 0}',
                    detail: 'Class homework updates',
                    color: NmbColors.accentDark),
          ),
          const SizedBox(height: 10),
          _MetricCard(
              icon: Icons.chat_bubble_outline_rounded,
              title: tr('Teacher feedback', 'Teacher feedback'),
              value: '${remarks.length}',
              detail: remarks.isEmpty
                  ? 'No remarks yet'
                  : 'Latest feedback available',
              color: NmbColors.info),
        ],
      ),
    );
  }

  static double _num(Object? value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(
      {required this.icon,
      required this.title,
      required this.value,
      required this.detail,
      required this.color});
  final IconData icon;
  final String title;
  final String value;
  final String detail;
  final Color color;
  @override
  Widget build(BuildContext context) => NmbCard(
          child: Row(children: <Widget>[
        CircleAvatar(
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color)),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
              Text(title, style: NmbTypography.bodySecondary),
              Text(value,
                  style: NmbTypography.screenTitle.copyWith(color: color)),
              Text(detail, style: NmbTypography.caption)
            ])),
      ]));
}
