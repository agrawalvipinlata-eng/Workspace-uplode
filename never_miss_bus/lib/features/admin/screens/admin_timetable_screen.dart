import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/nmb_colors.dart';
import '../../../core/theme/nmb_typography.dart';
import '../../../core/utils/result.dart';
import '../../../core/widgets/nmb_card.dart';
import '../../../core/widgets/nmb_visuals.dart';
import '../../../core/widgets/responsive_scaffold_body.dart';
import '../../../models/app_user.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';
import '../../../services/timetable_service.dart';

class AdminTimetableScreen extends ConsumerStatefulWidget {
  const AdminTimetableScreen({super.key});
  @override
  ConsumerState<AdminTimetableScreen> createState() =>
      _AdminTimetableScreenState();
}

class _AdminTimetableScreenState extends ConsumerState<AdminTimetableScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _subject = TextEditingController();
  final TextEditingController _room = TextEditingController();
  String? _class;
  String? _teacherUid;
  String _day = TimetableService.weekdays.first;
  int _period = 1;
  String _floor = TimetableService.lunchFloors.first;
  bool _saving = false;
  bool _savingDuty = false;

  @override
  void dispose() {
    _subject.dispose();
    _room.dispose();
    super.dispose();
  }

  void _snack(String message, {bool error = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(message),
          backgroundColor: error ? NmbColors.danger : NmbColors.success));

  Future<void> _savePeriod(List<AppUser> teachers) async {
    final AppUser? teacher =
        teachers.where((AppUser t) => t.uid == _teacherUid).firstOrNull;
    if (_class == null || teacher == null || _subject.text.trim().isEmpty)
      return _snack('Class, teacher और subject भरें.', error: true);
    setState(() => _saving = true);
    final Result<void> result = await ref.read(timetableServiceProvider).save(
        classSection: _class!,
        day: _day,
        period: _period,
        subject: _subject.text,
        teacher: teacher.fullName,
        teacherUid: teacher.uid,
        room: _room.text);
    if (!mounted) return;
    setState(() => _saving = false);
    result.when(
        ok: (_) {
          _subject.clear();
          _room.clear();
          _snack('Period saved successfully.');
        },
        err: (AppFailure f) => _snack(f.message, error: true));
  }

  Future<void> _saveDuty(List<AppUser> teachers) async {
    final AppUser? teacher =
        teachers.where((AppUser t) => t.uid == _teacherUid).firstOrNull;
    if (teacher == null)
      return _snack('Select a teacher for lunch duty.', error: true);
    setState(() => _savingDuty = true);
    final Result<void> result = await ref
        .read(timetableServiceProvider)
        .saveLunchDuty(
            teacher: teacher.fullName,
            teacherUid: teacher.uid,
            floor: _floor,
            day: _day);
    if (!mounted) return;
    setState(() => _savingDuty = false);
    result.when(
        ok: (_) => _snack('Lunch duty assigned.'),
        err: (AppFailure f) => _snack(f.message, error: true));
  }

  @override
  Widget build(BuildContext context) {
    final List<AppUser> teachers =
        ref.watch(allTeachersProvider).valueOrNull ?? const <AppUser>[];
    final List<AppUser> students =
        ref.watch(allStudentsProvider).valueOrNull ?? const <AppUser>[];
    final List<String> classes = students
        .map((AppUser s) => s.classSection ?? '')
        .where((String s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar:
            AppBar(title: const Text('Timetable Management'), actions: <Widget>[
          IconButton(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh_rounded))
        ]),
        body: ResponsiveBody(
            child: ListView(children: <Widget>[
          const NmbGradientHeader(
              title: 'Timetable Management',
              subtitle: 'Manage teacher duties and class schedules',
              icon: Icons.calendar_month_rounded),
          const SizedBox(height: 14),
          const TabBar(tabs: <Widget>[
            Tab(text: 'Admin • All Teachers'),
            Tab(text: 'Students • Class Preview')
          ]),
          const SizedBox(height: 14),
          NmbCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                Text('Create timetable entry',
                    style: NmbTypography.sectionTitle),
                const SizedBox(height: 12),
                Row(children: <Widget>[
                  Expanded(
                      child: DropdownButtonFormField<String>(
                          value: _class,
                          decoration: const InputDecoration(
                              labelText: 'Class • Section'),
                          items: <DropdownMenuItem<String>>[
                            for (final String c in classes)
                              DropdownMenuItem(value: c, child: Text(c))
                          ],
                          onChanged: (String? v) =>
                              setState(() => _class = v))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: DropdownButtonFormField<String>(
                          value: _teacherUid,
                          decoration:
                              const InputDecoration(labelText: 'Teacher'),
                          items: <DropdownMenuItem<String>>[
                            for (final AppUser t in teachers)
                              DropdownMenuItem(
                                  value: t.uid, child: Text(t.fullName))
                          ],
                          onChanged: (String? v) =>
                              setState(() => _teacherUid = v))),
                ]),
                const SizedBox(height: 10),
                Row(children: <Widget>[
                  Expanded(
                      child: DropdownButtonFormField<String>(
                          value: _day,
                          decoration: const InputDecoration(labelText: 'Day'),
                          items: <DropdownMenuItem<String>>[
                            for (final String d in TimetableService.weekdays)
                              DropdownMenuItem(value: d, child: Text(d))
                          ],
                          onChanged: (String? v) =>
                              setState(() => _day = v ?? _day))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: DropdownButtonFormField<int>(
                          value: _period,
                          decoration:
                              const InputDecoration(labelText: 'Period'),
                          items: <DropdownMenuItem<int>>[
                            for (final int p in TimetableService.periods)
                              DropdownMenuItem(
                                  value: p,
                                  child: Text(
                                      'Period $p  •  ${TimetableService.periodTimes[p - 1]}'))
                          ],
                          onChanged: (int? v) =>
                              setState(() => _period = v ?? _period))),
                ]),
                const SizedBox(height: 10),
                Row(children: <Widget>[
                  Expanded(
                    child: TextField(
                        controller: _subject,
                        decoration: const InputDecoration(
                            labelText: 'Subject / class')),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                      child: TextField(
                          controller: _room,
                          decoration: const InputDecoration(
                              labelText: 'Room (optional)'))),
                ]),
                const SizedBox(height: 12),
                FilledButton.icon(
                    onPressed: _saving ? null : () => _savePeriod(teachers),
                    icon: const Icon(Icons.add_rounded),
                    label: Text(_saving ? 'Saving…' : 'Add period')),
              ])),
          const SizedBox(height: 14),
          NmbCard(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                Row(children: <Widget>[
                  Expanded(
                      child: Text('Lunch duties',
                          style: NmbTypography.sectionTitle)),
                  NmbStatusPill(
                      label: '11:00 - 1:00', color: NmbColors.accentDark)
                ]),
                const SizedBox(height: 10),
                Row(children: <Widget>[
                  Expanded(
                      child: DropdownButtonFormField<String>(
                          value: _floor,
                          decoration:
                              const InputDecoration(labelText: 'Duty area'),
                          items: <DropdownMenuItem<String>>[
                            for (final String floor
                                in TimetableService.lunchFloors)
                              DropdownMenuItem(value: floor, child: Text(floor))
                          ],
                          onChanged: (String? v) =>
                              setState(() => _floor = v ?? _floor))),
                  const SizedBox(width: 10),
                  Expanded(
                      child: FilledButton.icon(
                          onPressed:
                              _savingDuty ? null : () => _saveDuty(teachers),
                          icon: const Icon(Icons.restaurant_rounded),
                          label:
                              Text(_savingDuty ? 'Saving…' : 'Assign duty'))),
                ]),
                const SizedBox(height: 12),
                StreamBuilder<List<Map<String, dynamic>>>(
                    stream:
                        ref.read(timetableServiceProvider).watchLunchDuties(),
                    builder:
                        (_, AsyncSnapshot<List<Map<String, dynamic>>> snap) {
                      final List<Map<String, dynamic>> duties =
                          snap.data ?? const <Map<String, dynamic>>[];
                      return Wrap(spacing: 8, runSpacing: 8, children: <Widget>[
                        for (final String floor in TimetableService.lunchFloors)
                          _DutyChip(
                              floor: floor,
                              teacher: duties
                                      .where((Map<String, dynamic> d) =>
                                          d['floor'] == floor)
                                      .map((Map<String, dynamic> d) =>
                                          '${d['teacher'] ?? 'Unassigned'}')
                                      .firstOrNull ??
                                  'Unassigned')
                      ]);
                    }),
              ])),
          const SizedBox(height: 14),
          SizedBox(
              height: 610,
              child: TabBarView(children: <Widget>[
                _TeacherMatrix(),
                _StudentPreview(classes: classes),
              ])),
        ])),
      ),
    );
  }
}

class _DutyChip extends StatelessWidget {
  const _DutyChip({required this.floor, required this.teacher});
  final String floor;
  final String teacher;
  @override
  Widget build(BuildContext context) => Container(
      width: 170,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: NmbColors.primarySoft,
          borderRadius: BorderRadius.circular(14)),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(floor,
                style: NmbTypography.cardTitle
                    .copyWith(color: NmbColors.primaryDark)),
            const SizedBox(height: 4),
            Text(teacher, style: NmbTypography.caption)
          ]));
}

class _TeacherMatrix extends ConsumerWidget {
  const _TeacherMatrix();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: ref.read(timetableServiceProvider).watchAll(),
      builder: (_, AsyncSnapshot<List<Map<String, dynamic>>> snap) {
        if (snap.hasError)
          return Center(child: Text('Timetable could not load: ${snap.error}'));
        final List<Map<String, dynamic>> rows =
            snap.data ?? const <Map<String, dynamic>>[];
        final Map<String, List<Map<String, dynamic>>> byTeacher =
            <String, List<Map<String, dynamic>>>{};
        for (final Map<String, dynamic> row in rows
            .where((Map<String, dynamic> r) => r['entryType'] != 'lunchDuty')) {
          (byTeacher['${row['teacher'] ?? 'Teacher'}'] ??=
                  <Map<String, dynamic>>[])
              .add(row);
        }
        if (byTeacher.isEmpty)
          return const Center(child: Text('No teacher timetable entries yet.'));
        return ListView(
          scrollDirection: Axis.horizontal,
          children: <Widget>[
            DataTable(
              columns: <DataColumn>[
                const DataColumn(label: Text('Teacher')),
                for (int p = 1; p <= 8; p++)
                  DataColumn(
                      label:
                          Text('P$p\n${TimetableService.periodTimes[p - 1]}')),
              ],
              rows: <DataRow>[
                for (final MapEntry<String, List<Map<String, dynamic>>> entry
                    in byTeacher.entries)
                  DataRow(cells: <DataCell>[
                    DataCell(Text(entry.key,
                        style: const TextStyle(fontWeight: FontWeight.w800))),
                    for (int p = 1; p <= 8; p++)
                      DataCell(Text(entry.value
                              .where(
                                  (Map<String, dynamic> r) => r['period'] == p)
                              .map((Map<String, dynamic> r) =>
                                  '${r['subject'] ?? 'Free'}\n${r['classSection'] ?? ''}')
                              .firstOrNull ??
                          'Free')),
                  ]),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _StudentPreview extends ConsumerStatefulWidget {
  const _StudentPreview({required this.classes});
  final List<String> classes;
  @override
  ConsumerState<_StudentPreview> createState() => _StudentPreviewState();
}

class _StudentPreviewState extends ConsumerState<_StudentPreview> {
  String? selected;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Align(
          alignment: Alignment.centerLeft,
          child: SizedBox(
            width: 240,
            child: DropdownButtonFormField<String>(
              value: selected,
              decoration: const InputDecoration(labelText: 'Select class'),
              items: <DropdownMenuItem<String>>[
                for (final String c in widget.classes)
                  DropdownMenuItem(value: c, child: Text(c)),
              ],
              onChanged: (String? v) => setState(() => selected = v),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (selected == null)
          const Expanded(
              child: Center(
                  child:
                      Text('Select a class to preview its weekly timetable.')))
        else
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream:
                  ref.read(timetableServiceProvider).watchForClass(selected!),
              builder: (_, AsyncSnapshot<List<Map<String, dynamic>>> snap) {
                final List<Map<String, dynamic>> rows =
                    snap.data ?? const <Map<String, dynamic>>[];
                final Map<String, Map<String, dynamic>> cells =
                    <String, Map<String, dynamic>>{};
                for (final Map<String, dynamic> row in rows)
                  cells['${row['day']}-${row['period']}'] = row;
                return ListView(
                  scrollDirection: Axis.horizontal,
                  children: <Widget>[
                    DataTable(
                      columns: <DataColumn>[
                        const DataColumn(label: Text('Day')),
                        for (int p = 1; p <= 8; p++)
                          DataColumn(
                              label: Text(
                                  'Period $p\n${TimetableService.periodTimes[p - 1]}')),
                      ],
                      rows: <DataRow>[
                        for (final String day in TimetableService.weekdays)
                          DataRow(cells: <DataCell>[
                            DataCell(Text(day)),
                            for (int p = 1; p <= 8; p++)
                              DataCell(Text(
                                  '${cells['$day-$p']?['subject'] ?? 'Free'}\n${cells['$day-$p']?['teacher'] ?? ''}')),
                          ]),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );
  }
}
