import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/nmb_colors.dart';
import '../../../core/theme/nmb_typography.dart';
import '../../../core/widgets/nmb_card.dart';
import '../../../core/widgets/state_views.dart';

/// 🧠 SMART ERROR CENTER — users ke phone me jo bhi error aata hai,
/// uski AUTO report yahan dikhti hai: kya error, kis screen pe, kaun
/// user, kab, app version. Screenshot bhejne ki zaroorat hi nahi!
class AdminErrorReportsScreen extends ConsumerWidget {
  const AdminErrorReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Error Reports')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('errorReports')
            .orderBy('at', descending: true)
            .limit(50)
            .snapshots(),
        builder: (BuildContext ctx,
            AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snap,) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          if (snap.hasError) {
            return const EmptyState(
              icon: Icons.cloud_off_rounded,
              title: 'Could not load',
              message: 'Rules me errorReports block add karna hoga '
                  '(niche wale message me diya hai).',
            );
          }
          final List<QueryDocumentSnapshot<Map<String, dynamic>>> docs =
              snap.data?.docs ??
                  const <QueryDocumentSnapshot<Map<String, dynamic>>>[];
          if (docs.isEmpty) {
            return const EmptyState(
              icon: Icons.verified_rounded,
              title: 'No errors! 🎉',
              message: 'App sab phones pe smooth chal rahi hai. '
                  'Koi bhi error aayega to yahan auto-report hoga.',
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: docs.length,
            itemBuilder: (BuildContext c, int i) {
              final Map<String, dynamic> r = docs[i].data();
              final bool isNew = (r['status'] as String?) == 'new';
              final Timestamp? at = r['at'] as Timestamp?;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: NmbCard(
                  color: isNew ? NmbColors.dangerSoft : NmbColors.surface,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Icon(
                            isNew
                                ? Icons.bug_report_rounded
                                : Icons.check_circle_outline_rounded,
                            color: isNew
                                ? NmbColors.danger
                                : NmbColors.success,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              (r['where'] as String?) ?? 'unknown',
                              style: NmbTypography.cardTitle,
                            ),
                          ),
                          if (isNew)
                            TextButton(
                              onPressed: () =>
                                  docs[i].reference.update(<String, String>{
                                'status': 'seen',
                              }),
                              child: const Text('Mark fixed'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: NmbColors.background,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          (r['error'] as String?) ?? '',
                          maxLines: 6,
                          overflow: TextOverflow.ellipsis,
                          style: NmbTypography.caption.copyWith(
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '👤 ${r['email'] ?? r['uid'] ?? 'unknown user'}'
                        ' • v${r['appVersion'] ?? '?'}'
                        '${at != null ? ' • ${_fmt(at.toDate())}' : ''}',
                        style: NmbTypography.caption,
                      ),
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

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')} '
      '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}
