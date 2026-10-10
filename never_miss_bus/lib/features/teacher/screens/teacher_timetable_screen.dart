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
      appBar: AppBar(title: const Text('My Timetable')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: ref.read(timetableServiceProvider).watchForTeacher(me.uid),
        builder: (_, AsyncSnapshot<List<Map<String, dynamic>>> snap) {
          final List<Map<String, dynamic>> rows =
              snap.data ?? const <Map<String, dynamic>>[];
          final Map<String, Map<String, dynamic>> cells =
              <String, Map<String, dynamic>>{};
          for (final Map<String, dynamic> row in rows
              .where((Map<String, dynamic> r) => r['entryType'] != 'lunchDuty'))
            cells['${row['day']}-${row['period']}'] = row;
          final List<Map<String, dynamic>> duties = rows
              .where((Map<String, dynamic> r) => r['entryType'] == 'lunchDuty')
              .toList();
          return ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              children: <Widget>[
                NmbGradientHeader(
                    title: 'Welcome, ${me.firstName}',
                    subtitle: 'Your assigned classes and lunch duties',
                    icon: Icons.co_present_rounded),
                const SizedBox(height: 16),
                Row(children: <Widget>[
                  NmbMetricTile(
                      value: '${cells.length}',
                      label: 'Classes',
                      icon: Icons.menu_book_rounded,
                      color: NmbColors.primary),
                  const SizedBox(width: 10),
                  NmbMetricTile(
                      value: '${duties.length}',
                      label: 'Lunch duties',
                      icon: Icons.restaurant_rounded,
                      color: NmbColors.accentDark),
                ]),
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
                            style: TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        for (final Map<String, dynamic> duty in duties)
                          ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.restaurant_rounded,
                                  color: NmbColors.accentDark),
                              title: Text('${duty['floor'] ?? 'Floor'}'),
                              subtitle: Text(
                                  '${duty['day'] ?? ''} • ${duty['lunchTime'] ?? '11:00 - 1:00'}')),
                      ])),
                ],
              ]);
        },
      ),
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
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
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
                              fontSize: 12, fontWeight: FontWeight.w800))),
                  title: Text('${cells['$day-$p']?['subject'] ?? 'Free'}'),
                  subtitle: Text(
                      '${cells['$day-$p']?['classSection'] ?? ''} • ${TimetableService.periodTimes[p - 1]}')),
          ])));
}
