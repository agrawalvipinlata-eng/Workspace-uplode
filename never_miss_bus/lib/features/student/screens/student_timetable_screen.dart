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
    if (klass == null)
      return const Scaffold(
          body: EmptyState(
              icon: Icons.schedule_rounded,
              title: 'No class assigned',
              message: 'Timetable will appear after your class is assigned.'));
    return Scaffold(
      appBar: AppBar(title: Text(tr('My Timetable', 'मेरा टाइमटेबल'))),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: ref.read(timetableServiceProvider).watchForClass(klass),
        builder: (BuildContext context,
            AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final List<Map<String, dynamic>> rows = snapshot.data!;
          if (rows.isEmpty)
            return const EmptyState(
                icon: Icons.schedule_rounded,
                title: 'No timetable yet',
                message: 'The school timetable will appear here.');
          final Map<String, Map<String, dynamic>> cells =
              <String, Map<String, dynamic>>{};
          for (final Map<String, dynamic> row in rows)
            cells['${row['day']}-${row['period']}'] = row;
          return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: <Widget>[
                NmbGradientHeader(
                    title: 'Class $klass',
                    subtitle: '8 periods • Monday to Saturday',
                    icon: Icons.calendar_month_rounded),
                const SizedBox(height: 16),
                Row(children: <Widget>[
                  NmbMetricTile(
                      value: '8',
                      label: 'Periods / day',
                      icon: Icons.view_week_rounded,
                      color: NmbColors.primary),
                  const SizedBox(width: 10),
                  NmbMetricTile(
                      value: '${rows.length}',
                      label: 'Classes planned',
                      icon: Icons.menu_book_rounded,
                      color: NmbColors.success),
                ]),
                const SizedBox(height: 20),
                for (final String day in TimetableService.weekdays)
                  _DayGrid(day: day, cells: cells),
              ]);
        },
      ),
    );
  }
}

class _DayGrid extends StatelessWidget {
  const _DayGrid({required this.day, required this.cells});
  final String day;
  final Map<String, Map<String, dynamic>> cells;
  @override
  Widget build(BuildContext context) {
    final int today = DateTime.now().weekday;
    final bool isToday = TimetableService.weekdays.indexOf(day) == today - 1;
    return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: NmbCard(
            borderColor: isToday ? NmbColors.primary.withOpacity(0.45) : null,
            padding: const EdgeInsets.all(14),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(children: <Widget>[
                    Expanded(
                        child: Text(day, style: NmbTypography.sectionTitle)),
                    if (isToday)
                      NmbStatusPill(label: 'Today', color: NmbColors.primary)
                  ]),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(children: <Widget>[
                        for (int p = 1; p <= 8; p++)
                          _PeriodCard(period: p, row: cells['$day-$p'])
                      ])),
                ])));
  }
}

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({required this.period, required this.row});
  final int period;
  final Map<String, dynamic>? row;
  @override
  Widget build(BuildContext context) {
    final bool free = row == null;
    final Color tone = free ? NmbColors.textTertiary : NmbColors.primary;
    return Container(
        width: 132,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
            color: tone.withOpacity(0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: tone.withOpacity(0.15))),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Period $period',
                  style: TextStyle(
                      color: tone, fontSize: 11, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(TimetableService.periodTimes[period - 1],
                  style: NmbTypography.caption),
              const SizedBox(height: 11),
              Text('${row?['subject'] ?? 'Free'}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: NmbTypography.cardTitle.copyWith(color: tone)),
              if (!free) ...<Widget>[
                const SizedBox(height: 5),
                Text('${row?['teacher'] ?? ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: NmbTypography.caption)
              ],
            ]));
  }
}
