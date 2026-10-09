import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/nmb_colors.dart';
import '../../../core/theme/nmb_typography.dart';
import '../../../core/widgets/nmb_card.dart';
import '../../../core/widgets/responsive_scaffold_body.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../models/app_user.dart';

import '../../../providers/data_providers.dart';
import '../widgets/user_editor_sheet.dart';

/// Class Teachers — admin creates teacher accounts; teachers can then
/// add/manage students of their class from their own phones (reduces
/// admin workload).
class AdminTeachersScreen extends ConsumerWidget {
  const AdminTeachersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<AppUser>> teachersAsync =
        ref.watch(allTeachersProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Class Teachers')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => UserEditorSheet.show(context, role: 'teacher'),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Add teacher'),
      ),
      body: teachersAsync.when(
        loading: () => const ListSkeleton(),
        error: (Object e, _) => ErrorView(
          message: 'Couldn\'t load teachers.',
          onRetry: () => ref.invalidate(allTeachersProvider),
        ),
        data: (List<AppUser> teachers) {
          if (teachers.isEmpty) {
            return const EmptyState(
              icon: Icons.co_present_outlined,
              title: 'No teachers yet',
              message: 'Add class teachers — they can then add and manage '
                  'students of their class from their own phones.',
            );
          }
          return ResponsiveBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (final AppUser t in teachers) ...<Widget>[
                  NmbCard(
                    onTap: () => UserManageSheet.show(context, t),
                    child: Row(
                      children: <Widget>[
                        CircleAvatar(
                          backgroundColor: NmbColors.primarySoft,
                          child: Icon(Icons.co_present_rounded,
                              color: NmbColors.primary,),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(t.fullName,
                                  style: NmbTypography.cardTitle,),
                              Text(t.email,
                                  style: NmbTypography.bodySecondary,),
                              Text(
                                <String>[
                                  if (t.classSection != null)
                                    'Class ${t.classSection}',
                                  if (t.phone != null && t.phone!.isNotEmpty)
                                    t.phone!,
                                ].join(' • '),
                                style: NmbTypography.caption,
                              ),
                            ],
                          ),
                        ),
                        if (!t.isActive)
                          const StatusPill(
                            label: 'DISABLED',
                            color: NmbColors.danger,
                            background: NmbColors.dangerSoft,
                          ),
                        const Icon(Icons.chevron_right_rounded,
                            color: NmbColors.textTertiary,),
                      ],
                    ),
                  ),
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
