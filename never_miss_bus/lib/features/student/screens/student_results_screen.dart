import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_language.dart';
import '../../../core/theme/nmb_colors.dart';
import '../../../core/theme/nmb_typography.dart';
import '../../../core/widgets/nmb_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/app_user.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';

class StudentResultsScreen extends ConsumerWidget {
  const StudentResultsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppUser? me = ref.watch(myProfileProvider).valueOrNull;
    if (me == null) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      appBar: AppBar(title: Text(tr('Exam & Result', 'परीक्षा और रिजल्ट'))),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: ref.read(examResultServiceProvider).watchForStudent(me.uid),
        builder: (BuildContext context,
            AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.hasError) {
            return const ErrorView(message: 'Could not load results.');
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final List<Map<String, dynamic>> results = snapshot.data!;
          if (results.isEmpty) {
            return const EmptyState(
              icon: Icons.assessment_outlined,
              title: 'No result yet',
              message:
                  'Your exam result will appear here after the school publishes it.',
            );
          }
          final double total = results.fold<double>(
              0,
              (double sum, Map<String, dynamic> r) =>
                  sum + _number(r['marks']));
          final double max = results.fold<double>(
              0,
              (double sum, Map<String, dynamic> r) =>
                  sum + _number(r['maxMarks']));
          final int percent = max == 0 ? 0 : (total / max * 100).round();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              NmbCard(
                color: NmbColors.primarySoft,
                child: Row(
                  children: <Widget>[
                    Icon(Icons.emoji_events_rounded,
                        color: NmbColors.accentDark, size: 34),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(tr('Overall performance', 'कुल प्रदर्शन'),
                            style: NmbTypography.sectionTitle),
                        Text('$percent%  •  ${_grade(percent)}',
                            style: NmbTypography.cardTitle),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              for (final Map<String, dynamic> result in results)
                NmbCard(
                  padding: const EdgeInsets.all(12),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: NmbColors.primarySoft,
                      child: Text('${result['grade'] ?? '-'}'),
                    ),
                    title: Text('${result['subject'] ?? 'Subject'}'),
                    subtitle: Text(
                        '${result['examName'] ?? 'Exam'}  •  ${result['examDate'] ?? ''}'),
                    trailing: Text(
                      '${_number(result['marks']).toStringAsFixed(0)}/${_number(result['maxMarks']).toStringAsFixed(0)}',
                      style: NmbTypography.cardTitle,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  static double _number(Object? value) =>
      value is num ? value.toDouble() : double.tryParse('$value') ?? 0;

  static String _grade(int percentage) {
    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B+';
    if (percentage >= 60) return 'B';
    if (percentage >= 50) return 'C';
    if (percentage >= 33) return 'D';
    return 'E';
  }
}
