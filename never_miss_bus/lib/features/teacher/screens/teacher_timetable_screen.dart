import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/nmb_colors.dart';
import '../../../core/widgets/nmb_card.dart';
import '../../../core/widgets/nmb_visuals.dart';
import '../../../models/app_user.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';
import '../../../services/timetable_service.dart';

class TeacherTimetableScreen extends ConsumerWidget {
  const TeacherTimetableScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppUser? me = ref.watch(myProfileProvider).valueOrNull;
    if (me == null) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Timetable'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(myProfileProvider),
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: ref.read(timetableServiceProvider).watchForTeacher(me.uid),
        builder: (BuildContext context,
            AsyncSnapshot<List<Map<String, dynamic>>> teacherSnapshot) {
          if (teacherSnapshot.hasError) {
            return _ErrorView(message: '${teacherSnapshot.error}');
          }
          if (teacherSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final List<Map<String, dynamic>> teacherRows =
              teacherSnapshot.data ?? const <Map<String, dynamic>>[];
          final String? classSection = me.classSection;
          if (classSection == null || classSection.trim().isEmpty) {
            return _TimetableContent(me: me, rows: teacherRows);
          }

          // A class teacher must also see the complete timetable of the class
          // assigned to them, not only periods where they teach personally.
          return StreamBuilder<List<Map<String, dynamic>>>(
            stream:
                ref.read(timetableServiceProvider).watchForClass(classSection),
            builder: (BuildContext context,
                AsyncSnapshot<List<Map<String, dynamic>>> classSnapshot) {
              if (classSnapshot.hasError) {
                return _ErrorView(message: '${classSnapshot.error}');
              }
              final Map<String, Map<String, dynamic>> merged =
                  <String, Map<String, dynamic>>{};
              for (final Map<String, dynamic> row in teacherRows) {
                merged['${row['id']}'] = row;
              }
              for (final Map<String, dynamic> row
                  in classSnapshot.data ?? const <Map<String, dynamic>>[]) {
                merged['${row['id']}'] = row;
              }
              return _TimetableContent(
                me: me,
                rows: merged.values.toList(),
                classSection: classSection,
              );
            },
          );
        },
      ),
    );
  }
}

class _TimetableContent extends StatelessWidget {
  const _TimetableContent({
    required this.me,
    required this.rows,
    this.classSection,
  });

  final AppUser me;
  final List<Map<String, dynamic>> rows;
  final String? classSection;

  @override
  Widget build(BuildContext context) {
    final Map<String, Map<String, dynamic>> cells =
        <String, Map<String, dynamic>>{};
    for (final Map<String, dynamic> row in rows
        .where((Map<String, dynamic> r) => r['entryType'] != 'lunchDuty')) {
      cells['${row['day']}-${row['period']}'] = row;
    }
    final List<Map<String, dynamic>> duties = rows
        .where((Map<String, dynamic> r) => r['entryType'] == 'lunchDuty')
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: <Widget>[
        NmbGradientHeader(
          title: 'Welcome, ${me.firstName}',
          subtitle: classSection == null
              ? 'Your assigned classes and lunch duties'
              : 'Teacher schedule • Class $classSection',
          icon: Icons.co_present_rounded,
        ),
        const SizedBox(height: 16),
        Row(
          children: <Widget>[
            NmbMetricTile(
              value: '${cells.length}',
              label: 'Periods shown',
              icon: Icons.menu_book_rounded,
              color: NmbColors.primary,
            ),
            const SizedBox(width: 10),
            NmbMetricTile(
              value: '${duties.length}',
              label: 'Lunch duties',
              icon: Icons.restaurant_rounded,
              color: NmbColors.accentDark,
            ),
          ],
        ),
        if (classSection != null) ...<Widget>[
          const SizedBox(height: 10),
          Text(
            'Class timetable updates appear here automatically.',
            style: TextStyle(color: NmbColors.textSecondary, fontSize: 12),
          ),
        ],
        const SizedBox(height: 18),
        for (final String day in TimetableService.weekdays)
          _TeacherDay(day: day, cells: cells),
        if (duties.isNotEmpty) ...<Widget>[
          const SizedBox(height: 8),
          NmbCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Lunch duty assignments',
                    style:
                        TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                for (final Map<String, dynamic> duty in duties)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.restaurant_rounded,
                        color: NmbColors.accentDark),
                    title: Text('${duty['floor'] ?? 'Floor'}'),
                    subtitle: Text(
                        '${duty['day'] ?? ''} • ${duty['lunchTime'] ?? '11:00 - 1:00'}'),
                  ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _TeacherDay extends StatelessWidget {
  const _TeacherDay({required this.day, required this.cells});
  final String day;
  final Map<String, Map<String, dynamic>> cells;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: NmbCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(day,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              for (int p = 1; p <= 8; p++)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  leading: CircleAvatar(
                    radius: 16,
                    backgroundColor: NmbColors.primarySoft,
                    child: Text('$p',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w800)),
                  ),
                  title: Text('${cells['$day-$p']?['subject'] ?? 'Free'}'),
                  subtitle: Text(
                      '${cells['$day-$p']?['classSection'] ?? ''} • ${TimetableService.periodTimes[p - 1]}'),
                ),
            ],
          ),
        ),
      );
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: NmbCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.error_outline_rounded,
                    color: NmbColors.danger, size: 42),
                const SizedBox(height: 10),
                const Text('Timetable could not load',
                    style: TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(message, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
}
