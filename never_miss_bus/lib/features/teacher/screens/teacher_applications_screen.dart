import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_language.dart';
import '../../../core/constants/enums.dart';
import '../../../core/theme/nmb_colors.dart';
import '../../../core/theme/nmb_typography.dart';
import '../../../core/utils/result.dart';
import '../../../core/widgets/nmb_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/app_user.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';
import '../../../services/leave_service.dart';

/// 📥 TEACHER/ADMIN — students ki leave applications dekho,
/// approve/reject karo. Teacher sirf apni class ki dekhta hai.
class TeacherApplicationsScreen extends ConsumerWidget {
  const TeacherApplicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppUser? me = ref.watch(myProfileProvider).valueOrNull;
    if (me == null) return const Scaffold(body: LoadingView());
    final LeaveService svc = ref.watch(leaveServiceProvider);
    // Teacher: apni class; Admin: sabki.
    final String? cls =
        me.role == UserRole.teacher ? me.classSection : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Leave Applications', 'छुट्टी की अर्ज़ियाँ')),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: svc.forClass(cls),
        builder: (BuildContext ctx,
            AsyncSnapshot<List<Map<String, dynamic>>> snap,) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          final List<Map<String, dynamic>> apps =
              snap.data ?? const <Map<String, dynamic>>[];
          if (apps.isEmpty) {
            return EmptyState(
              icon: Icons.inbox_rounded,
              title: tr('No applications', 'कोई अर्ज़ी नहीं'),
              message: tr(
                'Student leave applications will appear here.',
                'छात्रों की छुट्टी की अर्ज़ियाँ यहाँ दिखेंगी।',
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: apps.length,
            itemBuilder: (BuildContext c, int i) {
              final Map<String, dynamic> a = apps[i];
              final String status = (a['status'] as String?) ?? 'pending';
              final bool pending = status == 'pending';
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: NmbCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          CircleAvatar(
                            backgroundColor: NmbColors.primarySoft,
                            child: Text(
                              ((a['name'] as String?) ?? '?')
                                  .substring(0, 1)
                                  .toUpperCase(),
                              style: TextStyle(
                                color: NmbColors.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text((a['name'] as String?) ?? '-',
                                    style: NmbTypography.cardTitle,),
                                Text(
                                  '${tr('Class', 'क्लास')} ${a['classSection'] ?? '-'}'
                                  '${a['rollNumber'] != null ? ' • ${tr('Roll', 'रोल')} ${a['rollNumber']}' : ''}',
                                  style: NmbTypography.caption,
                                ),
                              ],
                            ),
                          ),
                          _statusPill(status),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: NmbColors.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              '📅 ${a['fromDate']} → ${a['toDate']}',
                              style: NmbTypography.body.copyWith(
                                  fontWeight: FontWeight.w700,),
                            ),
                            const SizedBox(height: 4),
                            Text((a['reason'] as String?) ?? '',
                                style: NmbTypography.bodySecondary,),
                          ],
                        ),
                      ),
                      if (pending) ...<Widget>[
                        const SizedBox(height: 10),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(
                                  backgroundColor: NmbColors.success,
                                  minimumSize: const Size.fromHeight(42),
                                ),
                                onPressed: () => _decide(
                                    context, ref, a['id'] as String, true,),
                                icon: const Icon(Icons.check_rounded,
                                    size: 18,),
                                label: Text(tr('Approve', 'स्वीकृत')),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: NmbColors.danger,
                                  side: const BorderSide(
                                      color: NmbColors.danger,),
                                  minimumSize: const Size.fromHeight(42),
                                ),
                                onPressed: () => _decide(
                                    context, ref, a['id'] as String, false,),
                                icon: const Icon(Icons.close_rounded,
                                    size: 18,),
                                label: Text(tr('Reject', 'अस्वीकृत')),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _statusPill(String status) {
    final Color fg = switch (status) {
      'approved' => NmbColors.success,
      'rejected' => NmbColors.danger,
      _ => NmbColors.warning,
    };
    final Color bg = switch (status) {
      'approved' => NmbColors.successSoft,
      'rejected' => NmbColors.dangerSoft,
      _ => NmbColors.warningSoft,
    };
    final String label = switch (status) {
      'approved' => tr('APPROVED', 'स्वीकृत'),
      'rejected' => tr('REJECTED', 'अस्वीकृत'),
      _ => tr('PENDING', 'विचाराधीन'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: NmbTypography.caption.copyWith(
          color: fg,
          fontWeight: FontWeight.w800,
          fontSize: 10,
        ),
      ),
    );
  }

  Future<void> _decide(
    BuildContext context,
    WidgetRef ref,
    String id,
    bool approve,
  ) async {
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final AppUser? me = ref.read(myProfileProvider).valueOrNull;
    if (me == null) return;
    final Result<void> r = await ref.read(leaveServiceProvider).decide(
          applicationId: id,
          approve: approve,
          decidedBy: me.uid,
        );
    r.when(
      ok: (_) => messenger.showSnackBar(SnackBar(
        backgroundColor: NmbColors.success,
        content: Text(
          approve
              ? tr('Approved ✓', 'स्वीकृत ✓')
              : tr('Rejected', 'अस्वीकृत'),
          style: const TextStyle(color: Colors.white),
        ),
      ),),
      err: (AppFailure f) => messenger.showSnackBar(SnackBar(
        backgroundColor: NmbColors.danger,
        content: Text(f.message,
            style: const TextStyle(color: Colors.white),),
      ),),
    );
  }
}
