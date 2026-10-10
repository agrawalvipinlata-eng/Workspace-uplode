import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/result.dart';
import '../../../core/widgets/nmb_card.dart';
import '../../../core/widgets/responsive_scaffold_body.dart';
import '../../../models/app_user.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';
import '../../../services/timetable_service.dart';

class AdminTimetableScreen extends ConsumerStatefulWidget {
  const AdminTimetableScreen({super.key});

  @override
  ConsumerState<AdminTimetableScreen> createState() =>
      _AdminTimetableScreenState();
}

class _AdminTimetableScreenState extends ConsumerState<AdminTimetableScreen> {
  final TextEditingController _subject = TextEditingController();
  final TextEditingController _teacher = TextEditingController();
  final TextEditingController _room = TextEditingController();
  String? _class;
  String _day = TimetableService.weekdays.first;
  int _period = 1;
  bool _saving = false;

  @override
  void dispose() {
    _subject.dispose();
    _teacher.dispose();
    _room.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_class == null || _subject.text.trim().isEmpty) {
      _snack('Class और subject select/enter करें.', error: true);
      return;
    }
    setState(() => _saving = true);
    final Result<void> result = await ref.read(timetableServiceProvider).save(
          classSection: _class!,
          day: _day,
          period: _period,
          subject: _subject.text,
          teacher: _teacher.text,
          room: _room.text,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    result.when(
      ok: (_) {
        _subject.clear();
        _teacher.clear();
        _room.clear();
        _snack('Timetable saved.', success: true);
      },
      err: (AppFailure f) => _snack(f.message, error: true),
    );
  }

  void _snack(String message, {bool error = false, bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
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
    final List<String> classes = students
        .map((AppUser s) => s.classSection ?? '')
        .where((String s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return Scaffold(
      appBar: AppBar(title: const Text('Class Timetable')),
      body: ResponsiveBody(
        child: ListView(
          children: <Widget>[
            const Text('Add timetable period',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 14),
            NmbCard(
                child: Column(children: <Widget>[
              DropdownButtonFormField<String>(
                  value: _class,
                  decoration: const InputDecoration(labelText: 'Class'),
                  items: <DropdownMenuItem<String>>[
                    for (final String c in classes)
                      DropdownMenuItem<String>(value: c, child: Text(c))
                  ],
                  onChanged: (String? v) => setState(() => _class = v)),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                  value: _day,
                  decoration: const InputDecoration(labelText: 'Day'),
                  items: <DropdownMenuItem<String>>[
                    for (final String d in TimetableService.weekdays)
                      DropdownMenuItem<String>(value: d, child: Text(d))
                  ],
                  onChanged: (String? v) => setState(() => _day = v ?? _day)),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                  value: _period,
                  decoration: const InputDecoration(labelText: 'Period'),
                  items: <DropdownMenuItem<int>>[
                    for (int p = 1; p <= 10; p++)
                      DropdownMenuItem<int>(value: p, child: Text('Period $p'))
                  ],
                  onChanged: (int? v) =>
                      setState(() => _period = v ?? _period)),
              const SizedBox(height: 10),
              TextField(
                  controller: _subject,
                  decoration: const InputDecoration(labelText: 'Subject')),
              const SizedBox(height: 10),
              TextField(
                  controller: _teacher,
                  decoration: const InputDecoration(labelText: 'Teacher')),
              const SizedBox(height: 10),
              TextField(
                  controller: _room,
                  decoration:
                      const InputDecoration(labelText: 'Room (optional)')),
              const SizedBox(height: 14),
              FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: const Icon(Icons.save_rounded),
                  label: Text(_saving ? 'Saving…' : 'Save period')),
            ])),
            const SizedBox(height: 18),
            if (_class != null)
              StreamBuilder<List<Map<String, dynamic>>>(
                stream:
                    ref.read(timetableServiceProvider).watchForClass(_class!),
                builder: (BuildContext context,
                    AsyncSnapshot<List<Map<String, dynamic>>> snapshot) {
                  if (!snapshot.hasData) return const LinearProgressIndicator();
                  return Text(
                      '${snapshot.data!.length} periods saved for $_class');
                },
              ),
          ],
        ),
      ),
    );
  }
}
