import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_language.dart';
import '../../../core/theme/nmb_colors.dart';
import '../../../core/theme/nmb_typography.dart';
import '../../../core/widgets/nmb_card.dart';
import '../../../core/widgets/nmb_visuals.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/app_user.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';
import '../../../services/timetable_service.dart';

class StudentTimetableScreen extends ConsumerWidget {
  const StudentTimetableScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppUser? me = ref.watch(myProfileProvider).valueOrNull;
    final String? klass = me?.classSection;
    if (klass == null) {
      return Scaffold(
        appBar: AppBar(title: Text(tr('My Timetable', 'मेरा टाइमटेबल'))),
        body: const EmptyState(
          icon: Icons.schedule_rounded,
          title: 'No class assigned',
          message: 'Timetable will appear after your class is assigned.',
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(tr('My Timetable', 'मेरा टाइमटेबल'))),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: ref.read(timetableServiceProvider).watchForClass(klass),
        builder: (BuildContext context,
            AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return EmptyState(
              icon: Icons.error_outline_rounded,
              title: 'Could not load timetable',
              message: '${snapshot.error}',
            );
          }
          final List<Map<String, dynamic>> rows =
              snapshot.data ?? const <Map<String, dynamic>>[];
          final Map<String, Map<String, dynamic>> cells =
              <String, Map<String, dynamic>>{};
          for (final Map<String, dynamic> row in rows) {
            cells['${row['day']}-${row['period']}'] = row;
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            children: <Widget>[
              NmbGradientHeader(
                title: 'Class $klass',
                subtitle: 'Monday to Saturday • Period 1 to 8',
                icon: Icons.calendar_month_rounded,
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  NmbMetricTile(
                    value: '8',
                    label: 'Periods / day',
                    icon: Icons.view_week_rounded,
                    color: NmbColors.primary,
                  ),
                  const SizedBox(width: 10),
                  NmbMetricTile(
                    value: '${rows.length}',
                    label: 'Entries planned',
                    icon: Icons.person_rounded,
                    color: NmbColors.success,
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _StudentGrid(cells: cells),
              const SizedBox(height: 12),
              Text(
                'Subjects are hidden in the student timetable. The cell shows the teacher assigned for that period.',
                style: NmbTypography.caption,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _StudentGrid extends StatelessWidget {
  const _StudentGrid({required this.cells});
  final Map<String, Map<String, dynamic>> cells;

  @override
  Widget build(BuildContext context) {
    return NmbCard(
      padding: EdgeInsets.zero,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStatePropertyAll<Color>(NmbColors.primarySoft),
          columnSpacing: 14,
          columns: <DataColumn>[
            const DataColumn(label: Text('Period')),
            for (final String day in TimetableService.weekdays)
              DataColumn(label: Text(day)),
          ],
          rows: <DataRow>[
            for (final int period in TimetableService.periods)
              DataRow(cells: <DataCell>[
                DataCell(SizedBox(
                  width: 84,
                  child: Text(
                    'Period $period',
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                )),
                for (final String day in TimetableService.weekdays)
                  DataCell(_TeacherCell(row: cells['$day-$period'])),
              ]),
          ],
        ),
      ),
    );
  }
}

class _TeacherCell extends StatelessWidget {
  const _TeacherCell({required this.row});
  final Map<String, dynamic>? row;

  @override
  Widget build(BuildContext context) {
    final bool free = row == null;
    return SizedBox(
      width: 112,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: (free ? NmbColors.textTertiary : NmbColors.primary)
              .withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          free ? 'Free' : '${row?['teacher'] ?? 'Teacher'}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: free ? NmbColors.textTertiary : NmbColors.primaryDark,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
