import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/nmb_constants.dart';
import '../../../core/theme/nmb_colors.dart';
import '../../../core/theme/nmb_typography.dart';
import '../../../core/widgets/nmb_card.dart';
import '../../../core/widgets/nmb_visuals.dart';
import '../../../core/widgets/responsive_scaffold_body.dart';
import '../../../models/app_user.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';

class AdminAdmissionDocumentsScreen extends ConsumerStatefulWidget {
  const AdminAdmissionDocumentsScreen({super.key});
  @override
  ConsumerState<AdminAdmissionDocumentsScreen> createState() =>
      _AdminAdmissionDocumentsScreenState();
}

class _AdminAdmissionDocumentsScreenState
    extends ConsumerState<AdminAdmissionDocumentsScreen> {
  String? _classSection;
  String? _studentUid;
  Map<String, bool> _status = <String, bool>{};
  bool _saving = false;

  void _selectStudent(AppUser student) => setState(() {
        _studentUid = student.uid;
        _status = <String, bool>{
          for (final String name in SchoolDocuments.all)
            name: student.documents[name] ?? false
        };
      });
  void _back() => setState(() {
        if (_studentUid != null) {
          _studentUid = null;
          _status = <String, bool>{};
        } else {
          _classSection = null;
        }
      });
  Future<void> _save() async {
    if (_studentUid == null) return;
    setState(() => _saving = true);
    final result = await ref.read(adminServiceProvider).updateUserProfile(
        uid: _studentUid!, data: <String, dynamic>{'documents': _status});
    if (!mounted) return;
    setState(() => _saving = false);
    result.when(
        ok: (_) => _snack('Document verification status saved.', success: true),
        err: (_) => _snack('Could not save document status.', error: true));
  }

  void _snack(String message, {bool error = false, bool success = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(message),
          backgroundColor: error
              ? NmbColors.danger
              : success
                  ? NmbColors.success
                  : null));

  @override
  Widget build(BuildContext context) {
    final List<AppUser> all =
        ref.watch(allStudentsProvider).valueOrNull ?? const <AppUser>[];
    final Map<String, List<AppUser>> groups = <String, List<AppUser>>{};
    for (final AppUser student in all) {
      final String key = student.classSection?.trim().isNotEmpty == true
          ? student.classSection!
          : 'Unassigned';
      (groups[key] ??= <AppUser>[]).add(student);
    }
    final List<AppUser> classStudents =
        groups[_classSection] ?? const <AppUser>[];
    AppUser? selected;
    for (final AppUser student in classStudents) {
      if (student.uid == _studentUid) selected = student;
    }
    final int complete = _status.values.where((bool value) => value).length;
    return Scaffold(
      appBar: AppBar(
        leading: _classSection == null
            ? null
            : IconButton(
                onPressed: _back, icon: const Icon(Icons.arrow_back_rounded)),
        title: Text(_studentUid != null
            ? (selected?.fullName ?? 'Student Documents')
            : _classSection ?? 'Admission Documents'),
      ),
      body: ResponsiveBody(
          child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _studentUid != null && selected != null
                  ? _DocumentChecklist(
                      student: selected,
                      status: _status,
                      complete: complete,
                      saving: _saving,
                      onToggle: (String name, bool value) =>
                          setState(() => _status[name] = value),
                      onSave: _save)
                  : _classSection != null
                      ? _StudentList(
                          students: classStudents, onSelect: _selectStudent)
                      : _ClassList(
                          groups: groups,
                          onSelect: (String value) =>
                              setState(() => _classSection = value)))),
    );
  }
}

class _ClassList extends StatelessWidget {
  const _ClassList({required this.groups, required this.onSelect});
  final Map<String, List<AppUser>> groups;
  final ValueChanged<String> onSelect;
  @override
  Widget build(BuildContext context) =>
      ListView(padding: const EdgeInsets.only(bottom: 24), children: <Widget>[
        const NmbGradientHeader(
            title: 'Admission Documents',
            subtitle: 'Select a class to review student documents',
            icon: Icons.folder_copy_rounded),
        const SizedBox(height: 16),
        Row(children: <Widget>[
          Expanded(
              child: Text('${groups.length} class sections',
                  style: NmbTypography.sectionTitle)),
          NmbStatusPill(
              label:
                  '${groups.values.fold<int>(0, (int a, List<AppUser> b) => a + b.length)} students',
              color: NmbColors.info)
        ]),
        const SizedBox(height: 10),
        for (final MapEntry<String, List<AppUser>> entry in groups.entries)
          Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: NmbCard(
                  onTap: () => onSelect(entry.key),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(children: <Widget>[
                    Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                            color: NmbColors.primarySoft,
                            borderRadius: BorderRadius.circular(14)),
                        child: Icon(Icons.school_rounded,
                            color: NmbColors.primary)),
                    const SizedBox(width: 13),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                          Text(entry.key, style: NmbTypography.cardTitle),
                          const SizedBox(height: 3),
                          Text(
                              '${entry.value.length} students • tap to view documents',
                              style: NmbTypography.caption)
                        ])),
                    const Icon(Icons.chevron_right_rounded,
                        color: NmbColors.textTertiary),
                  ]))),
        if (groups.isEmpty)
          const Padding(
              padding: EdgeInsets.all(30),
              child: Center(child: Text('No students found.'))),
      ]);
}

class _StudentList extends StatelessWidget {
  const _StudentList({required this.students, required this.onSelect});
  final List<AppUser> students;
  final ValueChanged<AppUser> onSelect;
  @override
  Widget build(BuildContext context) =>
      ListView(padding: const EdgeInsets.only(bottom: 24), children: <Widget>[
        NmbGradientHeader(
            title: 'Students',
            subtitle: '${students.length} students in this class',
            icon: Icons.groups_rounded),
        const SizedBox(height: 16),
        for (final AppUser student in students)
          Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: NmbCard(
                  onTap: () => onSelect(student),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(children: <Widget>[
                    CircleAvatar(
                        backgroundColor: NmbColors.accentSoft,
                        child: Text(student.fullName.isEmpty
                            ? '?'
                            : student.fullName[0].toUpperCase())),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                          Text(student.fullName,
                              style: NmbTypography.cardTitle),
                          const SizedBox(height: 3),
                          Text('Roll No. ${student.rollNumber ?? '-'}',
                              style: NmbTypography.caption)
                        ])),
                    _MiniProgress(documents: student.documents),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right_rounded,
                        color: NmbColors.textTertiary),
                  ]))),
      ]);
}

class _MiniProgress extends StatelessWidget {
  const _MiniProgress({required this.documents});
  final Map<String, bool> documents;
  @override
  Widget build(BuildContext context) {
    final int done =
        SchoolDocuments.all.where((String d) => documents[d] == true).length;
    return NmbStatusPill(
        label: '$done/${SchoolDocuments.all.length}',
        color: done == SchoolDocuments.all.length
            ? NmbColors.success
            : NmbColors.warning);
  }
}

class _DocumentChecklist extends StatelessWidget {
  const _DocumentChecklist(
      {required this.student,
      required this.status,
      required this.complete,
      required this.saving,
      required this.onToggle,
      required this.onSave});
  final AppUser student;
  final Map<String, bool> status;
  final int complete;
  final bool saving;
  final void Function(String, bool) onToggle;
  final VoidCallback onSave;
  @override
  Widget build(BuildContext context) =>
      ListView(padding: const EdgeInsets.only(bottom: 24), children: <Widget>[
        NmbGradientHeader(
            title: student.fullName,
            subtitle:
                'Class ${student.classSection ?? '-'} • Roll No. ${student.rollNumber ?? '-'}',
            icon: Icons.person_rounded),
        const SizedBox(height: 16),
        NmbCard(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
              Row(children: <Widget>[
                Expanded(
                    child: Text(
                        '$complete/${SchoolDocuments.all.length} documents verified',
                        style: NmbTypography.sectionTitle)),
                NmbStatusPill(
                    label: complete == SchoolDocuments.all.length
                        ? 'Complete'
                        : 'Pending',
                    color: complete == SchoolDocuments.all.length
                        ? NmbColors.success
                        : NmbColors.warning)
              ]),
              const SizedBox(height: 12),
              ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                      value: complete / SchoolDocuments.all.length,
                      minHeight: 8,
                      color: complete == SchoolDocuments.all.length
                          ? NmbColors.success
                          : NmbColors.primary,
                      backgroundColor: NmbColors.primarySoft)),
            ])),
        const SizedBox(height: 14),
        for (final String name in SchoolDocuments.all)
          Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: NmbCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  color: status[name] == true
                      ? NmbColors.successSoft
                      : NmbColors.surface,
                  child: CheckboxListTile(
                      value: status[name] ?? false,
                      onChanged: (bool? value) => onToggle(name, value == true),
                      title: Text(name, style: NmbTypography.cardTitle),
                      subtitle: Text(
                          status[name] == true
                              ? 'Verified'
                              : 'Pending verification',
                          style: NmbTypography.caption),
                      secondary: Icon(
                          status[name] == true
                              ? Icons.verified_rounded
                              : Icons.pending_outlined,
                          color: status[name] == true
                              ? NmbColors.success
                              : NmbColors.warning)))),
        const SizedBox(height: 8),
        FilledButton.icon(
            onPressed: saving ? null : onSave,
            icon: const Icon(Icons.save_rounded),
            label: Text(saving ? 'Saving…' : 'Save verification status')),
      ]);
}
