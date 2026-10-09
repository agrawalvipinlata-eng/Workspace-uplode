import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_language.dart';
import '../../../core/theme/nmb_colors.dart';
import '../../../core/theme/nmb_typography.dart';
import '../../../core/widgets/nmb_card.dart';
import '../../../core/widgets/responsive_scaffold_body.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/app_user.dart';
import '../../../providers/data_providers.dart';
import '../../../providers/app_providers.dart';
import '../../../core/utils/result.dart';
import '../../../services/remark_service.dart';
import '../../admin/widgets/student_details_sheet.dart';
import '../../admin/widgets/user_editor_sheet.dart';
import '../../shared/student_avatar.dart';

/// TEACHER — MY CLASS: apni class ke students, add + details + manage.
class TeacherClassScreen extends ConsumerWidget {
  const TeacherClassScreen({super.key});

  Future<void> _addRemark(BuildContext context, WidgetRef ref, AppUser student,
      AppUser teacher) async {
    final TextEditingController text = TextEditingController();
    String category = 'Homework';
    final String? selected = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext _, StateSetter setDialogState) => AlertDialog(
          title: Text('Remark for ${student.fullName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              DropdownButtonFormField<String>(
                value: category,
                items: [
                  for (final String c in RemarkService.categories)
                    DropdownMenuItem<String>(value: c, child: Text(c)),
                ],
                onChanged: (String? v) =>
                    setDialogState(() => category = v ?? category),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: text,
                maxLines: 4,
                maxLength: 300,
                decoration: const InputDecoration(hintText: 'Write remark'),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, category),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    if (selected == null || text.text.trim().isEmpty || !context.mounted) {
      text.dispose();
      return;
    }
    final Result<void> result = await ref.read(remarkServiceProvider).add(
          studentUid: student.uid,
          classSection: student.classSection!,
          teacherUid: teacher.uid,
          category: selected,
          text: text.text,
        );
    text.dispose();
    if (!context.mounted) return;
    result.when(
      ok: (_) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Remark saved.')),
      ),
      err: (AppFailure f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message)),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppUser? me = ref.watch(myProfileProvider).valueOrNull;
    final String? myClass = me?.classSection;
    final AsyncValue<List<AppUser>> studentsAsync =
        ref.watch(allStudentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          myClass != null
              ? '${tr('Class', 'क्लास')} $myClass'
              : tr('My Class', 'मेरी क्लास'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => UserEditorSheet.show(context, role: 'student'),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: Text(tr('Add student', 'छात्र जोड़ें')),
      ),
      body: studentsAsync.when(
        loading: () => const ListSkeleton(),
        error: (Object e, _) => ErrorView(
          message: tr(
            "Couldn't load students.",
            'छात्र सूची लोड नहीं हुई।',
          ),
          onRetry: () => ref.invalidate(allStudentsProvider),
        ),
        data: (List<AppUser> all) {
          final List<AppUser> students = myClass == null
              ? const <AppUser>[]
              : all.where((AppUser s) => s.classSection == myClass).toList();
          if (myClass == null) {
            return EmptyState(
              icon: Icons.co_present_outlined,
              title: tr('No class assigned', 'क्लास असाइन नहीं'),
              message: tr(
                'Admin has not assigned you a class yet.',
                'Admin ne abhi aapko class assign nahi ki hai.',
              ),
            );
          }
          if (students.isEmpty) {
            return EmptyState(
              icon: Icons.groups_outlined,
              title: tr('No students yet', 'अभी छात्र नहीं'),
              message: tr(
                'Add your first student with the button below.',
                'Neeche button se pehla student jodo.',
              ),
            );
          }
          return ResponsiveBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Class summary card
                NmbCard(
                  color: NmbColors.primarySoft,
                  child: Row(
                    children: <Widget>[
                      Icon(
                        Icons.school_rounded,
                        color: NmbColors.primary,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              '${tr('Class', 'क्लास')} $myClass',
                              style: NmbTypography.sectionTitle,
                            ),
                            Text(
                              '${students.length} '
                              '${tr('students', 'छात्र')}',
                              style: NmbTypography.bodySecondary,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                for (final AppUser s in students) ...<Widget>[
                  NmbCard(
                    onTap: () => UserManageSheet.show(context, s),
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: <Widget>[
                        StudentAvatar(user: s, radius: 22),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                s.fullName,
                                style: NmbTypography.cardTitle,
                              ),
                              Text(
                                'Roll ${s.rollNumber ?? '—'}',
                                style: NmbTypography.bodySecondary,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: tr('Details & fees', 'विवरण और फीस'),
                          icon: Icon(
                            Icons.assignment_ind_outlined,
                            color: NmbColors.primary,
                          ),
                          onPressed: () => StudentDetailsSheet.show(context, s),
                        ),
                        IconButton(
                          tooltip: 'Add remark',
                          icon: Icon(
                            Icons.rate_review_outlined,
                            color: NmbColors.accentDark,
                          ),
                          onPressed: me == null
                              ? null
                              : () => _addRemark(context, ref, s, me),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
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
