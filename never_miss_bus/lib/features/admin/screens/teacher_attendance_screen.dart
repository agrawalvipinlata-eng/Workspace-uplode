import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/nmb_colors.dart';
import '../../../core/theme/nmb_typography.dart';
import '../../../core/utils/result.dart';
import '../../../core/widgets/nmb_card.dart';

import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/app_user.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';
import '../../../services/attendance_service.dart';
import '../../shared/student_avatar.dart';

/// TEACHER ATTENDANCE — apni class ke students ki aaj ki hazri.
/// Ek tap = present/absent toggle. "Mark all present" shortcut. Save.
class TeacherAttendanceScreen extends ConsumerStatefulWidget {
  const TeacherAttendanceScreen({super.key});

  @override
  ConsumerState<TeacherAttendanceScreen> createState() =>
      _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState
    extends ConsumerState<TeacherAttendanceScreen> {
  final Map<String, bool> _marks = <String, bool>{};
  bool _loaded = false;
  bool _saving = false;
  final DateTime _date = DateTime.now();

  Future<void> _loadExisting(String classSection) async {
    if (_loaded) return;
    _loaded = true;
    final AttendanceService svc = ref.read(attendanceServiceProvider);
    try {
      final Map<String, bool>? existing =
          await svc.getForDate(classSection, _date);
      if (existing != null && mounted) {
        setState(() => _marks.addAll(existing));
      }
    } catch (_) {/* fresh day */}
  }

  Future<void> _save(String classSection, List<AppUser> students) async {
    final AttendanceService svc = ref.read(attendanceServiceProvider);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final String? myUid = ref.read(currentSessionProvider)?.uid;
    if (myUid == null) return;

    // Jo mark nahi hue unhe present maan lo (default)
    final Map<String, bool> full = <String, bool>{
      for (final AppUser s in students) s.uid: _marks[s.uid] ?? true,
    };

    setState(() => _saving = true);
    final Result<void> result = await svc.save(
      classSection: classSection,
      date: _date,
      marks: full,
      takenBy: myUid,
    );
    if (mounted) setState(() => _saving = false);
    result.when(
      ok: (_) => messenger.showSnackBar(const SnackBar(
        backgroundColor: Color(0xFF1E8E3E),
        content: Text('Attendance saved ✓',
            style: TextStyle(color: Colors.white),),
      ),),
      err: (AppFailure f) => messenger.showSnackBar(SnackBar(
        backgroundColor: const Color(0xFFC5221F),
        content:
            Text(f.message, style: const TextStyle(color: Colors.white)),
      ),),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppUser? me = ref.watch(myProfileProvider).valueOrNull;
    final bool iAmTeacher = me?.role.name == 'teacher';
    final String? myClass = me?.classSection;
    final AsyncValue<List<AppUser>> studentsAsync =
        ref.watch(allStudentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Attendance${myClass != null ? ' — $myClass' : ''}',
        ),
      ),
      body: studentsAsync.when(
        loading: () => const ListSkeleton(),
        error: (Object e, _) => ErrorView(
          message: 'Couldn\'t load students.',
          onRetry: () => ref.invalidate(allStudentsProvider),
        ),
        data: (List<AppUser> all) {
          // Teacher: apni class. Admin: saare (class filter ke saath).
          final List<AppUser> students = (iAmTeacher && myClass != null)
              ? all.where((AppUser s) => s.classSection == myClass).toList()
              : all;
          if (students.isEmpty) {
            return const EmptyState(
              icon: Icons.fact_check_outlined,
              title: 'No students',
              message: 'Is class me abhi students nahi hain.',
            );
          }
          if (myClass != null) _loadExisting(myClass);

          final int presentCount = students
              .where((AppUser s) => _marks[s.uid] ?? true)
              .length;

          return Column(
            children: <Widget>[
              // Header: date + counts + mark-all
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: NmbCard(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.today_rounded,
                          color: NmbColors.primary,),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              AttendanceService.dateKey(_date),
                              style: NmbTypography.cardTitle,
                            ),
                            Text(
                              '$presentCount present • '
                              '${students.length - presentCount} absent',
                              style: NmbTypography.bodySecondary,
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() {
                          for (final AppUser s in students) {
                            _marks[s.uid] = true;
                          }
                        }),
                        child: const Text('All Present'),
                      ),
                    ],
                  ),
                ),
              ),
              // Student list — tap = toggle
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  itemCount: students.length,
                  itemBuilder: (BuildContext ctx, int i) {
                    final AppUser s = students[i];
                    final bool present = _marks[s.uid] ?? true;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Material(
                        color: present
                            ? NmbColors.successSoft
                            : NmbColors.dangerSoft,
                        borderRadius: BorderRadius.circular(14),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () =>
                              setState(() => _marks[s.uid] = !present),
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              children: <Widget>[
                                StudentAvatar(user: s, radius: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Text(s.fullName,
                                          style: NmbTypography.cardTitle
                                              .copyWith(fontSize: 14),),
                                      Text(
                                        'Roll ${s.rollNumber ?? '—'}',
                                        style: NmbTypography.caption,
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6,),
                                  decoration: BoxDecoration(
                                    color: present
                                        ? NmbColors.success
                                        : NmbColors.danger,
                                    borderRadius:
                                        BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    present ? 'PRESENT' : 'ABSENT',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saving || myClass == null && !iAmTeacher == false
            ? null
            : () {
                final List<AppUser> all =
                    ref.read(allStudentsProvider).valueOrNull ??
                        const <AppUser>[];
                final List<AppUser> students =
                    (iAmTeacher && myClass != null)
                        ? all
                            .where((AppUser s) =>
                                s.classSection == myClass,)
                            .toList()
                        : all;
                final String cls = myClass ??
                    (students.isNotEmpty
                        ? (students.first.classSection ?? 'ALL')
                        : 'ALL');
                _save(cls, students);
              },
        icon: _saving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white,),
              )
            : const Icon(Icons.save_rounded),
        label: Text(_saving ? 'Saving…' : 'Save Attendance'),
      ),
    );
  }
}
