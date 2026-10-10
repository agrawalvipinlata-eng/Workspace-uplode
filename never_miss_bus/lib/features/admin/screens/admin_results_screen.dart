import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/result.dart';
import '../../../core/widgets/nmb_card.dart';
import '../../../core/widgets/responsive_scaffold_body.dart';
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

  Future<void> _save() async {
    final List<AppUser> students =
        ref.read(allStudentsProvider).valueOrNull ?? const <AppUser>[];
    AppUser? student;
    for (final AppUser candidate in students) {
      if (candidate.uid == _studentUid) {
        student = candidate;
        break;
      }
    }
    final double? marks = double.tryParse(_marks.text.trim());
    final double? max = double.tryParse(_max.text.trim());
    if (student == null ||
        _exam.text.trim().isEmpty ||
        _subject.text.trim().isEmpty ||
        marks == null ||
        max == null ||
        max <= 0 ||
        marks < 0 ||
        marks > max) {
      _snack('Student, exam, subject और valid marks भरें.', error: true);
      return;
    }
    setState(() => _saving = true);
    final Result<void> result = await ref.read(examResultServiceProvider).save(
          studentUid: student.uid,
          studentClass: student.classSection ?? '',
          examName: _exam.text,
          subject: _subject.text,
          marks: marks,
          maxMarks: max,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    result.when(
      ok: (_) {
        _marks.clear();
        _snack('Result published.', success: true);
      },
      err: (AppFailure f) => _snack(f.message, error: true),
    );
  }

  void _snack(String text, {bool error = false, bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      backgroundColor: error
          ? Colors.red
          : success
              ? Colors.green
              : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final List<AppUser> students =
        ref.watch(allStudentsProvider).valueOrNull ?? const <AppUser>[];
    return Scaffold(
      appBar: AppBar(title: const Text('Exam & Results')),
      body: ResponsiveBody(
        child: ListView(
          children: <Widget>[
            const Text('Publish result',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            NmbCard(
              child: Column(
                children: <Widget>[
                  DropdownButtonFormField<String>(
                    value: _studentUid,
                    decoration: const InputDecoration(labelText: 'Student'),
                    items: <DropdownMenuItem<String>>[
                      for (final AppUser student in students)
                        DropdownMenuItem<String>(
                          value: student.uid,
                          child: Text(
                              '${student.fullName} • ${student.classSection ?? '-'}'),
                        ),
                    ],
                    onChanged: (String? value) =>
                        setState(() => _studentUid = value),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                      controller: _exam,
                      decoration: const InputDecoration(
                          labelText: 'Exam name',
                          hintText: 'Annual Exam 2026')),
                  const SizedBox(height: 10),
                  TextField(
                      controller: _subject,
                      decoration: const InputDecoration(labelText: 'Subject')),
                  const SizedBox(height: 10),
                  Row(
                    children: <Widget>[
                      Expanded(
                          child: TextField(
                              controller: _marks,
                              keyboardType: TextInputType.number,
                              decoration:
                                  const InputDecoration(labelText: 'Marks'))),
                      const SizedBox(width: 10),
                      Expanded(
                          child: TextField(
                              controller: _max,
                              keyboardType: TextInputType.number,
                              decoration:
                                  const InputDecoration(labelText: 'Maximum'))),
                    ],
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: const Icon(Icons.publish_rounded),
                    label: Text(_saving ? 'Saving…' : 'Publish result'),
                  ),
                ],
              ),
            ),
            if (_studentUid != null)
              const Padding(
                padding: EdgeInsets.only(top: 18),
                child: Text(
                    'Existing results are visible to the selected student in the app.'),
              ),
          ],
        ),
      ),
    );
  }
}
