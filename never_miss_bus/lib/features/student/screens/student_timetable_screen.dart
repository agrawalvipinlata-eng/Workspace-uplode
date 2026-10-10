import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_language.dart';
import '../../../core/widgets/nmb_card.dart';
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
      return const Scaffold(
        body: EmptyState(
          icon: Icons.schedule_rounded,
          title: 'No class assigned',
          message: 'Timetable will appear after your class is assigned.',
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(tr('Class Timetable', 'क्लास टाइमटेबल'))),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: ref.read(timetableServiceProvider).watchForClass(klass),
        builder: (BuildContext context,
            AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final List<Map<String, dynamic>> rows = snapshot.data!;
          if (rows.isEmpty) {
            return const EmptyState(
              icon: Icons.schedule_rounded,
              title: 'No timetable yet',
              message: 'The school timetable will appear here.',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              for (final String day in TimetableService.weekdays)
                _DayCard(
                    day: day,
                    rows: rows
                        .where((Map<String, dynamic> row) => row['day'] == day)
                        .toList()),
            ],
          );
        },
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.day, required this.rows});
  final String day;
  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return NmbCard(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        initiallyExpanded:
            day == TimetableService.weekdays[DateTime.now().weekday - 1],
        title: Text(day, style: const TextStyle(fontWeight: FontWeight.w800)),
        children: <Widget>[
          for (final Map<String, dynamic> row in rows)
            ListTile(
              leading: CircleAvatar(child: Text('${row['period'] ?? '-'}')),
              title: Text('${row['subject'] ?? 'Period'}'),
              subtitle: Text(
                  '${row['teacher'] ?? ''}${row['room'] == null || row['room'] == '' ? '' : ' • Room ${row['room']}'}'),
            ),
        ],
      ),
    );
  }
}
