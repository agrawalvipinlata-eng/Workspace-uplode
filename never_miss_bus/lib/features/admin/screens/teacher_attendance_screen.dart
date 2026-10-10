import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/nmb_colors.dart';
import '../../../core/theme/nmb_typography.dart';
import '../../../core/utils/result.dart';
import '../../../core/widgets/nmb_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/app_user.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';
import '../../../services/attendance_service.dart';
import '../../shared/student_avatar.dart';

class TeacherAttendanceScreen extends ConsumerStatefulWidget {
  const TeacherAttendanceScreen({super.key});
  @override
  ConsumerState<TeacherAttendanceScreen> createState() =>
      _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState
    extends ConsumerState<TeacherAttendanceScreen> {
  final Map<String, bool> _marks = <String, bool>{};
  final DateTime _date = DateTime.now();
  String? _classSection;
  String _query = '';
  bool _locked = false;
  bool _loadingRecord = false;
  bool _saving = false;
  String? _loadedFor;

  Future<void> _load(String classSection) async {
    if (_loadedFor == classSection) return;
    _loadedFor = classSection;
    _marks.clear();
    _locked = false;
    _loadingRecord = true;
    setState(() {});
    try {
      final AttendanceRecord? record = await ref
          .read(attendanceServiceProvider)
          .getForDate(classSection, _date);
      if (mounted && record != null)
        setState(() {
          _marks.addAll(record.marks);
          _locked = record.locked;
        });
    } catch (_) {}
    if (mounted) setState(() => _loadingRecord = false);
  }

  Future<void> _save(String classSection, List<AppUser> students) async {
    if (_locked || _saving) return;
    final String? uid = ref.read(currentSessionProvider)?.uid;
    if (uid == null) return;
    setState(() => _saving = true);
    final Result<void> result = await ref.read(attendanceServiceProvider).save(
        classSection: classSection,
        date: _date,
        marks: <String, bool>{
          for (final AppUser s in students) s.uid: _marks[s.uid] ?? true
        },
        takenBy: uid);
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (result is Ok<void>) _locked = true;
    });
    result.when(
        ok: (_) => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Attendance submitted and locked ✓'))),
        err: (AppFailure f) => ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(f.message), backgroundColor: NmbColors.danger)));
  }

  @override
  Widget build(BuildContext context) {
    final AppUser? me = ref.watch(myProfileProvider).valueOrNull;
    final bool teacher = me?.role.name == 'teacher';
    final List<AppUser> all =
        ref.watch(allStudentsProvider).valueOrNull ?? const <AppUser>[];
    final Set<String> used = all
        .map((AppUser s) => s.classSection)
        .whereType<String>()
        .where((String s) => s.isNotEmpty)
        .toSet();
    final List<String> classes = used.toList()..sort();
    if (teacher && me?.classSection != null) _classSection ??= me!.classSection;
    final String? chosen = teacher ? me?.classSection : _classSection;
    if (chosen != null) _load(chosen);
    final List<AppUser> students = chosen == null
        ? <AppUser>[]
        : all
            .where((AppUser s) => s.classSection == chosen)
            .where((AppUser s) =>
                _query.trim().isEmpty ||
                '${s.fullName} ${s.rollNumber}'
                    .toLowerCase()
                    .contains(_query.trim().toLowerCase()))
            .toList();
    final int present =
        students.where((AppUser s) => _marks[s.uid] ?? true).length;
    return Scaffold(
      appBar: AppBar(
          title: Text('Attendance${chosen == null ? '' : ' — $chosen'}')),
      body: Column(children: <Widget>[
        if (!teacher)
          Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Row(children: <Widget>[
                Expanded(
                    child: DropdownButtonFormField<String>(
                        value: chosen,
                        decoration:
                            const InputDecoration(labelText: 'Class • Section'),
                        items: <DropdownMenuItem<String>>[
                          for (final String c in classes)
                            DropdownMenuItem(value: c, child: Text(c))
                        ],
                        onChanged: (String? v) => setState(() {
                              _classSection = v;
                              _loadedFor = null;
                            }))),
              ])),
        if (chosen != null)
          Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: TextField(
                  decoration: const InputDecoration(
                      hintText: 'Search student in this class',
                      prefixIcon: Icon(Icons.search_rounded)),
                  onChanged: (String v) => setState(() => _query = v))),
        if (chosen == null)
          const Expanded(
              child: EmptyState(
                  icon: Icons.fact_check_outlined,
                  title: 'Choose a class and section',
                  message:
                      'Each class has its own attendance grid and submission status.'))
        else if (_loadingRecord)
          const Expanded(child: Center(child: CircularProgressIndicator()))
        else
          Expanded(
              child: Column(children: <Widget>[
            Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: NmbCard(
                    child: Row(children: <Widget>[
                  Icon(Icons.today_rounded, color: NmbColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(
                          '${AttendanceService.dateKey(_date)}\n$present present • ${students.length - present} absent',
                          style: NmbTypography.cardTitle)),
                  Text(_locked ? 'SUBMITTED' : 'NOT SUBMITTED',
                      style: TextStyle(
                          color:
                              _locked ? NmbColors.success : NmbColors.warning,
                          fontWeight: FontWeight.w800))
                ]))),
            if (_locked)
              const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                          'Attendance submitted and locked. Admin correction only.'))),
            Expanded(
                child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
                    itemCount: students.length,
                    itemBuilder: (_, int i) {
                      final AppUser s = students[i];
                      final bool p = _marks[s.uid] ?? true;
                      return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Material(
                              color: p
                                  ? NmbColors.successSoft
                                  : NmbColors.dangerSoft,
                              borderRadius: BorderRadius.circular(14),
                              child: InkWell(
                                  onTap: _locked
                                      ? null
                                      : () =>
                                          setState(() => _marks[s.uid] = !p),
                                  child: Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: Row(children: <Widget>[
                                        StudentAvatar(user: s, radius: 20),
                                        const SizedBox(width: 10),
                                        Expanded(
                                            child: Text(
                                                '${s.fullName}\nRoll ${s.rollNumber ?? '—'}',
                                                style: NmbTypography.cardTitle
                                                    .copyWith(fontSize: 14))),
                                        Text(p ? 'PRESENT' : 'ABSENT',
                                            style: TextStyle(
                                                color: p
                                                    ? NmbColors.success
                                                    : NmbColors.danger,
                                                fontWeight: FontWeight.w800))
                                      ])))));
                    })),
          ])),
      ]),
      floatingActionButton: chosen == null || _locked || _saving
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _save(chosen, students),
              icon: const Icon(Icons.save_rounded),
              label: Text(_saving ? 'Saving…' : 'Submit attendance')),
    );
  }
}
