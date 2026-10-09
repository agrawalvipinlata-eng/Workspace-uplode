import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/widgets/state_views.dart';
import '../../../models/app_user.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';
import '../../../services/schoolwork_service.dart';

class TeacherSchoolworkScreen extends ConsumerStatefulWidget {
  const TeacherSchoolworkScreen({super.key});

  @override
  ConsumerState<TeacherSchoolworkScreen> createState() =>
      _TeacherSchoolworkScreenState();
}

class _TeacherSchoolworkScreenState
    extends ConsumerState<TeacherSchoolworkScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  final TextEditingController _diary = TextEditingController();
  final TextEditingController _subject = TextEditingController();
  final TextEditingController _homework = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _tabs.dispose();
    _diary.dispose();
    _subject.dispose();
    _homework.dispose();
    super.dispose();
  }

  Future<void> _submitDiary(AppUser me) async {
    if (me.classSection == null || _diary.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final result = await ref.read(schoolworkServiceProvider).submitDiary(
          teacherUid: me.uid,
          classSection: me.classSection!,
          date: DateTime.now(),
          text: _diary.text,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    result.when(
      ok: (_) {
        _diary.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Daily diary submitted ✓')),
        );
      },
      err: (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message)),
      ),
    );
  }

  Future<void> _submitHomework(AppUser me) async {
    if (me.classSection == null ||
        _subject.text.trim().isEmpty ||
        _homework.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final result = await ref.read(schoolworkServiceProvider).createHomework(
          teacherUid: me.uid,
          classSection: me.classSection!,
          subject: _subject.text,
          date: DateTime.now(),
          deadline: null,
          description: _homework.text,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    result.when(
      ok: (_) {
        _subject.clear();
        _homework.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Homework posted ✓')),
        );
      },
      err: (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppUser? me = ref.watch(myProfileProvider).valueOrNull;
    if (me == null || me.classSection == null) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.school_outlined,
          title: 'No class assigned',
          message: 'Admin has not assigned a class to this teacher.',
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Class work — ${me.classSection}'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const <Widget>[
            Tab(text: 'Daily Diary'),
            Tab(text: 'Homework'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: <Widget>[
          _FormBody(
            controller: _diary,
            hint: 'Write today\'s diary for your class…',
            button: 'Submit diary',
            saving: _saving,
            onSubmit: () => _submitDiary(me),
          ),
          Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: TextField(
                  controller: _subject,
                  decoration: const InputDecoration(labelText: 'Subject'),
                ),
              ),
              Expanded(
                child: _FormBody(
                  controller: _homework,
                  hint: 'Describe homework and submission work…',
                  button: 'Post homework',
                  saving: _saving,
                  onSubmit: () => _submitHomework(me),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FormBody extends StatelessWidget {
  const _FormBody({
    required this.controller,
    required this.hint,
    required this.button,
    required this.saving,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final String hint;
  final String button;
  final bool saving;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            TextField(
              controller: controller,
              minLines: 6,
              maxLines: 12,
              decoration: InputDecoration(hintText: hint),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: saving ? null : onSubmit,
              icon: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(saving ? 'Saving…' : button),
            ),
          ],
        ),
      );
}
