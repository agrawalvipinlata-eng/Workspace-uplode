import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_language.dart';
import '../../../core/theme/nmb_colors.dart';
import '../../../core/theme/nmb_typography.dart';
import '../../../core/widgets/nmb_card.dart';
import '../../../core/widgets/nmb_visuals.dart';
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
      appBar: AppBar(
        title: Text(tr('Exam Results', 'परीक्षा परिणाम')),
        actions: <Widget>[
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Results are up to date.')),
            ),
            icon: const Icon(Icons.notifications_none_rounded),
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: ref.read(examResultServiceProvider).watchForStudent(me.uid),
        builder: (BuildContext context,
            AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
          if (snapshot.hasError)
            return const ErrorView(message: 'Could not load results.');
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
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
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            children: <Widget>[
              NmbGradientHeader(
                title: 'Your performance',
                subtitle:
                    '${me.fullName}  •  ${me.classSection ?? 'Class not set'}',
                icon: Icons.auto_graph_rounded,
              ),
              const SizedBox(height: 16),
              Row(children: <Widget>[
                NmbMetricTile(
                    value: '$percent%',
                    label: 'Overall',
                    icon: Icons.emoji_events_rounded,
                    color: NmbColors.accentDark),
                const SizedBox(width: 10),
                NmbMetricTile(
                    value: '${results.length}',
                    label: 'Subjects',
                    icon: Icons.menu_book_rounded,
                    color: NmbColors.info),
                const SizedBox(width: 10),
                NmbMetricTile(
                    value: _grade(percent),
                    label: 'Grade',
                    icon: Icons.workspace_premium_rounded,
                    color: NmbColors.success),
              ]),
              const SizedBox(height: 22),
              Row(children: <Widget>[
                Expanded(
                    child: Text(tr('All Results', 'सभी परिणाम'),
                        style: NmbTypography.sectionTitle)),
                const NmbStatusPill(
                    label: 'Published', color: NmbColors.success),
              ]),
              const SizedBox(height: 10),
              for (int index = 0; index < results.length; index++)
                _ResultCard(result: results[index], accent: _accent(index)),
            ],
          );
        },
      ),
    );
  }

  static Color _accent(int index) {
    const List<Color> colors = <Color>[
      Color(0xFF5B5FEF),
      Color(0xFF00A7A0),
      Color(0xFFFF9F43),
      Color(0xFFE94875),
    ];
    return colors[index % colors.length];
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

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result, required this.accent});
  final Map<String, dynamic> result;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final double marks = StudentResultsScreen._number(result['marks']);
    final double max = StudentResultsScreen._number(result['maxMarks']);
    final double ratio = max <= 0 ? 0 : (marks / max).clamp(0, 1);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: NmbCard(
        borderColor: accent.withOpacity(0.18),
        padding: const EdgeInsets.all(14),
        child: Row(children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: accent.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(Icons.menu_book_rounded, color: accent, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                Text('${result['subject'] ?? 'Subject'}',
                    style: NmbTypography.cardTitle),
                const SizedBox(height: 3),
                Text(
                    '${result['examName'] ?? 'Exam'}  •  ${result['examDate'] ?? 'Published'}',
                    style: NmbTypography.caption),
                const SizedBox(height: 9),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 6,
                      backgroundColor: accent.withOpacity(0.10),
                      color: accent),
                ),
              ])),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: <Widget>[
            Text('${marks.toStringAsFixed(0)}/${max.toStringAsFixed(0)}',
                style: NmbTypography.cardTitle.copyWith(color: accent)),
            const SizedBox(height: 5),
            NmbStatusPill(
                label: '${result['grade'] ?? '-'} Grade', color: accent),
          ]),
        ]),
      ),
    );
  }
}
