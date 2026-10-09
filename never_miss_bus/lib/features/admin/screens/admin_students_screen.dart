import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/nmb_colors.dart';
import '../../../core/theme/nmb_typography.dart';
import '../../../core/constants/nmb_constants.dart';
import '../../../core/widgets/nmb_card.dart';
import '../../../core/widgets/nmb_dialogs.dart';
import '../../../core/widgets/responsive_scaffold_body.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../models/app_user.dart';
import '../../../models/bus.dart';
import '../../../providers/data_providers.dart';
import '../../shared/student_avatar.dart';
import '../widgets/student_details_sheet.dart';
import '../widgets/user_editor_sheet.dart';

/// Manage students: list, search, add, and per-student detail sheet
/// (assign bus/stop, enable/disable). All mutations go via Cloud Functions.
class AdminStudentsScreen extends ConsumerStatefulWidget {
  const AdminStudentsScreen({super.key});

  @override
  ConsumerState<AdminStudentsScreen> createState() =>
      _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends ConsumerState<AdminStudentsScreen> {
  String _query = '';
  String? _classFilter; // null = All classes
  String? _lookupClass;
  String? _lookupSection;
  final TextEditingController _lookupRoll = TextEditingController();

  @override
  void dispose() {
    _lookupRoll.dispose();
    super.dispose();
  }

  void _lookup(List<AppUser> students) {
    final String? klass = _lookupClass;
    final String? section = _lookupSection;
    final String roll = _lookupRoll.text.trim();
    if (klass == null || section == null || roll.isEmpty) {
      showNmbSnack(
        context,
        'Select class, section and enter roll number.',
        isError: true,
      );
      return;
    }
    final String classSection = SchoolClasses.label(klass, section);
    final List<AppUser> matches = students
        .where((AppUser s) =>
            s.classSection == classSection && s.rollNumber == roll)
        .toList();
    final AppUser? match = matches.isEmpty ? null : matches.first;
    if (match == null) {
      showNmbSnack(
        context,
        'No student found for $classSection / Roll $roll',
        isError: true,
      );
      return;
    }
    StudentDetailsSheet.show(context, match);
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<AppUser>> studentsAsync =
        ref.watch(allStudentsProvider);
    // CLASS-WISE TEACHER: teacher sirf APNI class ke students dekhta hai.
    final AppUser? myProfile = ref.watch(myProfileProvider).valueOrNull;
    final bool iAmTeacher = myProfile?.role.name == 'teacher';
    final String? myClass = myProfile?.classSection;
    final List<Bus> buses =
        ref.watch(allBusesProvider).valueOrNull ?? const <Bus>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Students')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => UserEditorSheet.show(context, role: 'student'),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add student'),
      ),
      body: studentsAsync.when(
        loading: () => const ListSkeleton(),
        error: (Object e, _) => ErrorView(
          message: 'Couldn\'t load students.',
          onRetry: () => ref.invalidate(allStudentsProvider),
        ),
        data: (List<AppUser> studentsIn) {
          List<AppUser> students = studentsIn;
          // Jo classes actually use ho rahi hain, unke filter chips banao.
          final List<String> presentClasses = students
              .map((AppUser s) => s.classSection ?? '')
              .where((String c) => c.isNotEmpty)
              .toSet()
              .toList()
            ..sort();

          // Teacher: pehle apni class tak seemit karo
          if (iAmTeacher && myClass != null) {
            students = students
                .where((AppUser s) => s.classSection == myClass)
                .toList();
          }
          final List<AppUser> filtered = students.where((AppUser s) {
            final bool matchesClass =
                _classFilter == null || s.classSection == _classFilter;
            final String q = _query.trim().toLowerCase();
            final bool matchesQuery = q.isEmpty ||
                <String>[
                  s.fullName,
                  s.classSection ?? '',
                  s.rollNumber ?? '',
                  s.phone ?? '',
                  s.email,
                  s.contactEmail ?? '',
                ].any((String value) => value.toLowerCase().contains(q));
            return matchesClass && matchesQuery;
          }).toList();

          return ResponsiveBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                NmbCard(
                  color: NmbColors.primarySoft,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Text(
                        'Find student by Class • Section • Roll',
                        style: NmbTypography.sectionTitle,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _lookupClass,
                              decoration:
                                  const InputDecoration(labelText: 'Class'),
                              items: <DropdownMenuItem<String>>[
                                for (final String c in SchoolClasses.classes)
                                  DropdownMenuItem<String>(
                                      value: c, child: Text(c)),
                              ],
                              onChanged: (String? v) =>
                                  setState(() => _lookupClass = v),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _lookupSection,
                              decoration:
                                  const InputDecoration(labelText: 'Section'),
                              items: <DropdownMenuItem<String>>[
                                for (final String s in SchoolClasses.sections)
                                  DropdownMenuItem<String>(
                                      value: s, child: Text(s)),
                              ],
                              onChanged: (String? v) =>
                                  setState(() => _lookupSection = v),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _lookupRoll,
                              keyboardType: TextInputType.number,
                              decoration:
                                  const InputDecoration(labelText: 'Roll no.'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        onPressed: () => _lookup(studentsIn),
                        icon: const Icon(Icons.person_search_rounded),
                        label: const Text('Show student details'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search name, class, roll, phone or email…',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onChanged: (String v) => setState(() => _query = v),
                ),
                const SizedBox(height: 12),

                // Class-wise filter chips: "All" + jo classes maujood hain.
                if (presentClasses.isNotEmpty)
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: <Widget>[
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text('All (${students.length})'),
                            selected: _classFilter == null,
                            onSelected: (_) =>
                                setState(() => _classFilter = null),
                          ),
                        ),
                        for (final String c in presentClasses)
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(
                                'Class $c '
                                '(${students.where((AppUser s) => s.classSection == c).length})',
                              ),
                              selected: _classFilter == c,
                              onSelected: (_) =>
                                  setState(() => _classFilter = c),
                            ),
                          ),
                      ],
                    ),
                  ),
                const SizedBox(height: 14),
                if (filtered.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 60),
                    child: EmptyState(
                      icon: Icons.school_outlined,
                      title: 'No students found',
                      message: 'Add students with the button below, or adjust '
                          'your search.',
                    ),
                  )
                else
                  for (final AppUser s in filtered) ...<Widget>[
                    _StudentTile(student: s, buses: buses),
                    const SizedBox(height: 10),
                  ],
                const SizedBox(height: 90),
              ],
            ),
          );
        },
      ),
    );
  }
}

bool _isLoggedIn(AppUser u) {
  final String? id = u.activeDevice?['id'] as String?;
  return id != null && id.isNotEmpty && id != 'REVOKED';
}

class _StudentTile extends StatelessWidget {
  const _StudentTile({required this.student, required this.buses});

  final AppUser student;
  final List<Bus> buses;

  @override
  Widget build(BuildContext context) {
    String busLabel = 'No bus';
    for (final Bus b in buses) {
      if (b.id == student.busId) busLabel = b.busNumber;
    }
    return NmbCard(
      onTap: () => UserManageSheet.show(context, student),
      // Long-press → personal details, documents & fees
      // (quick hint shown in subtitle)
      child: Row(
        children: <Widget>[
          StudentAvatar(user: student, radius: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(student.fullName, style: NmbTypography.cardTitle),
                Text(
                  <String>[
                    if (student.classSection != null)
                      'Class ${student.classSection}',
                    busLabel,
                  ].join(' • '),
                  style: NmbTypography.bodySecondary,
                ),
              ],
            ),
          ),
          if (!student.isActive)
            const StatusPill(
              label: 'DISABLED',
              color: NmbColors.danger,
              background: NmbColors.dangerSoft,
            )
          else if (_isLoggedIn(student))
            const StatusPill(
              label: 'LOGGED IN',
              color: NmbColors.success,
              background: NmbColors.successSoft,
            )
          else
            const StatusPill(
              label: 'NOT LOGGED IN',
              color: NmbColors.textTertiary,
              background: NmbColors.divider,
            ),
          IconButton(
            tooltip: 'Details, documents & fees',
            visualDensity: VisualDensity.compact,
            icon: Icon(
              Icons.assignment_ind_outlined,
              color: NmbColors.primary,
            ),
            onPressed: () => StudentDetailsSheet.show(context, student),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: NmbColors.textTertiary,
          ),
        ],
      ),
    );
  }
}
