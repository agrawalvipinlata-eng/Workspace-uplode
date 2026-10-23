import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/nmb_colors.dart';
import '../../../core/theme/nmb_typography.dart';
import '../../../core/constants/enums.dart';
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

class _AdminTimetableScreenState extends ConsumerState<AdminTimetableScreen> {
  int _selectedSection = 0;
  String? _selectedClass;

  @override
  void dispose() {
    super.dispose();
  }

  void _message(String text, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      backgroundColor: error ? NmbColors.danger : NmbColors.success,
    ));
  }

  Future<void> _openEntryDialog({
    required List<AppUser> teachers,
    required List<String> classes,
    String? initialClass,
    String? initialTeacherUid,
    String? initialDay,
    int? initialPeriod,
  }) async {
    if (teachers.isEmpty || classes.isEmpty) {
      _message('पहले teachers और students की class-section data add करें.',
          error: true);
      return;
    }
    String? teacherUid = initialTeacherUid ?? teachers.first.uid;
    String classSection = initialClass ?? classes.first;
    String day = initialDay ?? TimetableService.weekdays.first;
    int period = initialPeriod ?? 1;
    final TextEditingController subject = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter setModalState) {
          final AppUser? teacher = teachers
              .where((AppUser item) => item.uid == teacherUid)
              .firstOrNull;
          return AlertDialog(
            title: const Text('Add timetable entry'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  DropdownButtonFormField<String>(
                    value: teacherUid,
                    decoration: const InputDecoration(labelText: 'Teacher'),
                    items: <DropdownMenuItem<String>>[
                      for (final AppUser item in teachers)
                        DropdownMenuItem<String>(
                          value: item.uid,
                          child: Text(item.fullName),
                        ),
                    ],
                    onChanged: (String? value) =>
                        setModalState(() => teacherUid = value),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: classSection,
                    decoration:
                        const InputDecoration(labelText: 'Class • Section'),
                    items: <DropdownMenuItem<String>>[
                      for (final String item in classes)
                        DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        ),
                    ],
                    onChanged: (String? value) => setModalState(() {
                      if (value != null) classSection = value;
                    }),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: day,
                    decoration: const InputDecoration(labelText: 'Day'),
                    items: <DropdownMenuItem<String>>[
                      for (final String item in TimetableService.weekdays)
                        DropdownMenuItem<String>(
                          value: item,
                          child: Text(item),
                        ),
                    ],
                    onChanged: (String? value) => setModalState(() {
                      if (value != null) day = value;
                    }),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: period,
                    decoration: const InputDecoration(labelText: 'Period'),
                    items: <DropdownMenuItem<int>>[
                      for (final int item in TimetableService.periods)
                        DropdownMenuItem<int>(
                          value: item,
                          child: Text('Period $item'),
                        ),
                    ],
                    onChanged: (int? value) => setModalState(() {
                      if (value != null) period = value;
                    }),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: subject,
                    decoration: const InputDecoration(
                      labelText: 'Subject (optional)',
                      hintText: 'Shown only in admin/teacher view',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Student timetable में subject नहीं दिखेगा; वहां teacher name दिखेगा.',
                    style: NmbTypography.caption,
                  ),
                  if (teacher != null) ...<Widget>[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Selected: ${teacher.fullName}',
                          style: NmbTypography.caption),
                    ),
                  ],
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton.icon(
                icon: const Icon(Icons.save_rounded),
                label: const Text('Save entry'),
                onPressed: () async {
                  final AppUser? selectedTeacher = teachers
                      .where((AppUser item) => item.uid == teacherUid)
                      .firstOrNull;
                  if (selectedTeacher == null) return;
                  final Result<void> result =
                      await ref.read(timetableServiceProvider).save(
                            classSection: classSection,
                            day: day,
                            period: period,
                            subject: subject.text.trim(),
                            teacher: selectedTeacher.fullName,
                            teacherUid: selectedTeacher.uid,
                          );
                  if (!mounted) return;
                  result.when(
                    ok: (_) {
                      Navigator.of(dialogContext).pop();
                      _message('Timetable entry saved.');
                    },
                    err: (AppFailure failure) =>
                        _message(failure.message, error: true),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
    subject.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<AppUser> teachers =
        ref.watch(allTeachersProvider).valueOrNull ?? const <AppUser>[];
    final List<AppUser> students =
        ref.watch(allStudentsProvider).valueOrNull ?? const <AppUser>[];
    final List<String> classes = students
        .map((AppUser student) => student.classSection ?? '')
        .where((String value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    _selectedClass ??= classes.firstOrNull;

    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (BuildContext context) => IconButton(
            tooltip: 'Open admin menu',
            icon: const Icon(Icons.menu_rounded),
            onPressed: () =>
                context.findAncestorStateOfType<ScaffoldState>()?.openDrawer(),
          ),
        ),
        title: const Text('Timetable Management'),
        actions: <Widget>[
          IconButton(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
          )
        ],
      ),
      body: ResponsiveBody(
        child: ListView(
          children: <Widget>[
            const NmbGradientHeader(
              title: 'Timetable Management',
              subtitle: 'Create teacher and class-wise weekly schedules',
              icon: Icons.calendar_month_rounded,
            ),
            const SizedBox(height: 14),
            NmbCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text('Choose timetable section',
                      style: NmbTypography.sectionTitle),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: () => setState(() => _selectedSection = 0),
                    icon: const Icon(Icons.groups_rounded),
                    label: const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Teachers’ Timetable'),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: _selectedSection == 0
                          ? NmbColors.primary
                          : NmbColors.primarySoft,
                      foregroundColor: _selectedSection == 0
                          ? Colors.white
                          : NmbColors.primaryDark,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () => setState(() => _selectedSection = 1),
                    icon: const Icon(Icons.grid_view_rounded),
                    label: const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Class-wise Timetable'),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: _selectedSection == 1
                          ? NmbColors.primary
                          : NmbColors.primarySoft,
                      foregroundColor: _selectedSection == 1
                          ? Colors.white
                          : NmbColors.primaryDark,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            _selectedSection == 0
                ? _TeacherTimetableTab(
                    teachers: teachers,
                    classes: classes,
                    onAdd: () => _openEntryDialog(
                      teachers: teachers,
                      classes: classes,
                    ),
                  )
                : _ClassTimetableTab(
                    classes: classes,
                    selectedClass: _selectedClass,
                    onClassChanged: (String? value) => setState(() {
                      _selectedClass = value;
                    }),
                    onAdd: () => _openEntryDialog(
                      teachers: teachers,
                      classes: classes,
                      initialClass: _selectedClass,
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _TeacherTimetableTab extends ConsumerWidget {
  const _TeacherTimetableTab({
    required this.teachers,
    required this.classes,
    required this.onAdd,
  });

  final List<AppUser> teachers;
  final List<String> classes;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: ref.read(timetableServiceProvider).watchAll(),
      builder: (BuildContext context,
          AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
        final List<Map<String, dynamic>> rows = (snapshot.data ??
                const <Map<String, dynamic>>[])
            .where(
                (Map<String, dynamic> row) => row['entryType'] != 'lunchDuty')
            .toList();
        return Column(
          children: <Widget>[
            _SectionHeader(
              title: 'Teachers’ Timetable',
              subtitle: 'Teacher name, subject and Monday–Saturday assignment',
              icon: Icons.groups_rounded,
              actionLabel: 'Add Teacher Timetable',
              onPressed: onAdd,
            ),
            const SizedBox(height: 10),
            _TeacherTable(teachers: teachers, rows: rows),
          ],
        );
      },
    );
  }
}

class _TeacherTable extends StatelessWidget {
  const _TeacherTable({required this.teachers, required this.rows});

  final List<AppUser> teachers;
  final List<Map<String, dynamic>> rows;

  @override
  Widget build(BuildContext context) {
    final List<AppUser> visibleTeachers = teachers.isEmpty
        ? rows
            .map((Map<String, dynamic> row) => AppUser(
                  uid: '${row['teacherUid'] ?? row['teacher']}',
                  fullName: '${row['teacher'] ?? 'Teacher'}',
                  email: '',
                  role: UserRole.teacher,
                ))
            .toList()
        : teachers;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStatePropertyAll<Color>(NmbColors.primarySoft),
        columnSpacing: 18,
        columns: <DataColumn>[
          const DataColumn(label: Text('Teacher Name')),
          const DataColumn(label: Text('Subject')),
          for (final String day in TimetableService.weekdays)
            DataColumn(label: Text(day)),
        ],
        rows: <DataRow>[
          for (final AppUser teacher in visibleTeachers)
            DataRow(cells: <DataCell>[
              DataCell(SizedBox(
                width: 150,
                child: Text(teacher.fullName,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
              )),
              DataCell(SizedBox(
                width: 120,
                child: Text(_subjectsFor(teacher, rows)),
              )),
              for (final String day in TimetableService.weekdays)
                DataCell(SizedBox(
                  width: 122,
                  child: Text(_dayText(teacher, day, rows)),
                )),
            ]),
        ],
      ),
    );
  }

  String _subjectsFor(AppUser teacher, List<Map<String, dynamic>> rows) {
    final Set<String> subjects = rows
        .where((Map<String, dynamic> row) =>
            row['teacherUid'] == teacher.uid ||
            row['teacher'] == teacher.fullName)
        .map((Map<String, dynamic> row) => '${row['subject'] ?? ''}')
        .where((String value) => value.trim().isNotEmpty)
        .toSet();
    return subjects.isEmpty ? '—' : subjects.join(', ');
  }

  String _dayText(
      AppUser teacher, String day, List<Map<String, dynamic>> rows) {
    final List<Map<String, dynamic>> entries = rows
        .where((Map<String, dynamic> row) =>
            (row['teacherUid'] == teacher.uid ||
                row['teacher'] == teacher.fullName) &&
            row['day'] == day)
        .toList()
      ..sort((Map<String, dynamic> a, Map<String, dynamic> b) =>
          _period(a).compareTo(_period(b)));
    if (entries.isEmpty) return 'Free';
    return entries.map((Map<String, dynamic> row) {
      final String klass = '${row['classSection'] ?? ''}';
      final int period = _period(row);
      return 'P$period  $klass';
    }).join('\n');
  }

  int _period(Map<String, dynamic> row) =>
      (row['period'] is num) ? (row['period'] as num).toInt() : 0;
}

class _ClassTimetableTab extends ConsumerWidget {
  const _ClassTimetableTab({
    required this.classes,
    required this.selectedClass,
    required this.onClassChanged,
    required this.onAdd,
  });

  final List<String> classes;
  final String? selectedClass;
  final ValueChanged<String?> onClassChanged;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? klass = selectedClass;
    return Column(
      children: <Widget>[
        _SectionHeader(
          title: 'Class-wise Timetable',
          subtitle: 'Students see teacher names by day and period',
          icon: Icons.grid_view_rounded,
          actionLabel: 'Add Class-wise Timetable',
          onPressed: onAdd,
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          value: klass,
          decoration: const InputDecoration(
            labelText: 'Select class • section',
            prefixIcon: Icon(Icons.school_rounded),
          ),
          items: <DropdownMenuItem<String>>[
            for (final String item in classes)
              DropdownMenuItem<String>(value: item, child: Text(item)),
          ],
          onChanged: onClassChanged,
        ),
        const SizedBox(height: 12),
        if (klass == null)
          const NmbCard(child: Text('Select a class to view its timetable.'))
        else
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: ref.read(timetableServiceProvider).watchForClass(klass),
            builder: (BuildContext context,
                AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
              final Map<String, Map<String, dynamic>> cells =
                  <String, Map<String, dynamic>>{};
              for (final Map<String, dynamic> row
                  in snapshot.data ?? const <Map<String, dynamic>>[]) {
                cells['${row['day']}-${row['period']}'] = row;
              }
              return _ClassGrid(classSection: klass, cells: cells);
            },
          ),
      ],
    );
  }
}

class _ClassGrid extends StatelessWidget {
  const _ClassGrid({required this.classSection, required this.cells});

  final String classSection;
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
                  width: 90,
                  child: Text('Period $period',
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                )),
                for (final String day in TimetableService.weekdays)
                  DataCell(_ClassCell(row: cells['$day-$period'])),
              ]),
          ],
        ),
      ),
    );
  }
}

class _ClassCell extends StatelessWidget {
  const _ClassCell({required this.row});
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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.actionLabel,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return NmbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              CircleAvatar(
                backgroundColor: NmbColors.primarySoft,
                child: Icon(icon, color: NmbColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: NmbTypography.sectionTitle),
                    const SizedBox(height: 4),
                    Text(subtitle, style: NmbTypography.bodySecondary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onPressed,
            icon: const Icon(Icons.add_rounded),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
