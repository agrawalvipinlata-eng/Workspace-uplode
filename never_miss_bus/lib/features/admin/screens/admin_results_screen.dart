import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/result.dart';
import '../../../core/widgets/nmb_card.dart';
import '../../../core/widgets/responsive_scaffold_body.dart';
import '../../../core/widgets/nmb_visuals.dart';
import '../../../core/theme/nmb_colors.dart';
import '../../../core/theme/nmb_typography.dart';
import '../../../models/app_user.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';

class AdminResultsScreen extends ConsumerStatefulWidget {
  const AdminResultsScreen({super.key});
  @override
  ConsumerState<AdminResultsScreen> createState() => _AdminResultsScreenState();
}

class _AdminResultsScreenState extends ConsumerState<AdminResultsScreen> {
  final TextEditingController _exam = TextEditingController();
  final TextEditingController _subject = TextEditingController();
  final TextEditingController _marks = TextEditingController();
  final TextEditingController _max = TextEditingController(text: '100');
  String? _studentUid;
  bool _saving = false;
  @override
  void dispose() {
    _exam.dispose();
    _subject.dispose();
    _marks.dispose();
    _max.dispose();
    super.dispose();
  }

  void _snack(String s, {bool error = false, bool success = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(s),
          backgroundColor: error
              ? Colors.red
              : success
                  ? Colors.green
                  : null));
  Future<void> _save() async {
    final List<AppUser> ss =
        ref.read(allStudentsProvider).valueOrNull ?? const <AppUser>[];
    AppUser? st;
    for (final AppUser x in ss) {
      if (x.uid == _studentUid) st = x;
    }
    final double? m = double.tryParse(_marks.text.trim());
    final double? max = double.tryParse(_max.text.trim());
    if (st == null ||
        _exam.text.trim().isEmpty ||
        _subject.text.trim().isEmpty ||
        m == null ||
        max == null ||
        max <= 0 ||
        m < 0 ||
        m > max)
      return _snack('Student, exam, subject और valid marks भरें.', error: true);
    setState(() => _saving = true);
    final Result<void> r = await ref.read(examResultServiceProvider).save(
        studentUid: st.uid,
        studentClass: st.classSection ?? '',
        examName: _exam.text,
        subject: _subject.text,
        marks: m,
        maxMarks: max);
    if (!mounted) return;
    setState(() => _saving = false);
    r.when(
        ok: (_) {
          _marks.clear();
          _snack('Result published.', success: true);
        },
        err: (AppFailure f) => _snack(f.message, error: true));
  }

  @override
  Widget build(BuildContext context) {
    final List<AppUser> students =
        ref.watch(allStudentsProvider).valueOrNull ?? const <AppUser>[];
    return Scaffold(
        appBar: AppBar(title: const Text('Exam & Results')),
        body: ResponsiveBody(
            child: ListView(children: <Widget>[
          const NmbGradientHeader(
              title: 'Result Management',
              subtitle: 'Publish marks and keep every class on track',
              icon: Icons.assessment_rounded),
          const SizedBox(height: 16),
          Row(children: <Widget>[
            NmbMetricTile(
                value: '${students.length}',
                label: 'Students',
                icon: Icons.groups_rounded,
                color: NmbColors.info),
            const SizedBox(width: 10),
            const NmbMetricTile(
                value: 'Live',
                label: 'Publishing',
                icon: Icons.bolt_rounded,
                color: NmbColors.success),
          ]),
          const SizedBox(height: 18),
          Text('Publish result', style: NmbTypography.sectionTitle),
          const SizedBox(height: 10),
          NmbCard(
              child: Column(children: <Widget>[
            DropdownButtonFormField<String>(
                value: _studentUid,
                decoration: const InputDecoration(labelText: 'Student'),
                items: <DropdownMenuItem<String>>[
                  for (final AppUser s in students)
                    DropdownMenuItem(
                        value: s.uid,
                        child: Text('${s.fullName} • ${s.classSection ?? '-'}'))
                ],
                onChanged: (String? v) => setState(() => _studentUid = v)),
            const SizedBox(height: 10),
            TextField(
                controller: _exam,
                decoration: const InputDecoration(labelText: 'Exam name')),
            const SizedBox(height: 10),
            TextField(
                controller: _subject,
                decoration: const InputDecoration(labelText: 'Subject')),
            const SizedBox(height: 10),
            Row(children: <Widget>[
              Expanded(
                  child: TextField(
                      controller: _marks,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Marks'))),
              const SizedBox(width: 10),
              Expanded(
                  child: TextField(
                      controller: _max,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Maximum')))
            ]),
            const SizedBox(height: 14),
            FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: const Icon(Icons.publish_rounded),
                label: Text(_saving ? 'Saving…' : 'Publish result'))
          ])),
          const SizedBox(height: 20),
          const Text('Published results',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          StreamBuilder<List<Map<String, dynamic>>>(
              stream: ref.read(examResultServiceProvider).watchAll(),
              builder: (_, AsyncSnapshot<List<Map<String, dynamic>>> snap) {
                if (!snap.hasData)
                  return const Center(child: CircularProgressIndicator());
                if (snap.data!.isEmpty)
                  return const Text('No results published yet.');
                return Column(children: <Widget>[
                  for (final Map<String, dynamic> r in snap.data!)
                    Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: NmbCard(
                            child: ListTile(
                                title: Text(
                                    '${r['examName'] ?? 'Exam'} • ${r['subject'] ?? ''}'),
                                subtitle: Text(
                                    '${r['classSection'] ?? '-'} • ${r['marks'] ?? 0}/${r['maxMarks'] ?? 0} • Grade ${r['grade'] ?? '-'}'))))
                ]);
              })
        ])));
  }
}
