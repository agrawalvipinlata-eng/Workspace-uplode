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

  void _snack(String s, {bool error = false, bool success = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(s),
          backgroundColor: error
              ? Colors.red
              : success
                  ? Colors.green
                  : null));
  Future<void> _save() async {
    if (_class == null ||
        _subject.text.trim().isEmpty ||
        _teacher.text.trim().isEmpty) {
      _snack('Class, subject और teacher भरें.', error: true);
      return;
    }
    setState(() => _saving = true);
    final Result<void> r = await ref.read(timetableServiceProvider).save(
        classSection: _class!,
        day: _day,
        period: _period,
        subject: _subject.text,
        teacher: _teacher.text,
        room: _room.text);
    if (!mounted) return;
    setState(() => _saving = false);
    r.when(
        ok: (_) {
          _subject.clear();
          _teacher.clear();
          _room.clear();
          _snack('Timetable period saved.', success: true);
        },
        err: (AppFailure f) => _snack(f.message, error: true));
  }

  Widget _grid(List<Map<String, dynamic>> rows) {
    final Map<String, Map<String, dynamic>> cells =
        <String, Map<String, dynamic>>{};
    for (final Map<String, dynamic> row in rows) {
      cells['${row['day']}-${row['period']}'] = row;
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: <DataColumn>[
          const DataColumn(label: Text('Day')),
          for (final int p in TimetableService.periods)
            DataColumn(label: Text('Period $p'))
        ],
        rows: <DataRow>[
          for (final String day in TimetableService.weekdays)
            DataRow(cells: <DataCell>[
              DataCell(Text(day.substring(0, 3))),
              for (final int period in TimetableService.periods)
                DataCell(Text(
                    '${cells['$day-$period']?['subject'] ?? '—'}\n${cells['$day-$period']?['teacher'] ?? ''}')),
            ]),
        ],
      ),
    );
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
          child: ListView(children: <Widget>[
        const Text('Add timetable period',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        NmbCard(
            child: Column(children: <Widget>[
          DropdownButtonFormField<String>(
              value: _class,
              decoration: const InputDecoration(labelText: 'Class • Section'),
              items: <DropdownMenuItem<String>>[
                for (final String c in classes)
                  DropdownMenuItem(value: c, child: Text(c))
              ],
              onChanged: (String? v) => setState(() => _class = v)),
          const SizedBox(height: 10),
          Row(children: <Widget>[
            Expanded(
                child: DropdownButtonFormField<String>(
                    value: _day,
                    decoration: const InputDecoration(labelText: 'Day'),
                    items: <DropdownMenuItem<String>>[
                      for (final String d in TimetableService.weekdays)
                        DropdownMenuItem(value: d, child: Text(d))
                    ],
                    onChanged: (String? v) =>
                        setState(() => _day = v ?? _day))),
            const SizedBox(width: 10),
            Expanded(
                child: DropdownButtonFormField<int>(
                    value: _period,
                    decoration: const InputDecoration(labelText: 'Period'),
                    items: <DropdownMenuItem<int>>[
                      for (final int p in TimetableService.periods)
                        DropdownMenuItem(value: p, child: Text('Period $p'))
                    ],
                    onChanged: (int? v) =>
                        setState(() => _period = v ?? _period))),
          ]),
          const SizedBox(height: 10),
          TextField(
              controller: _subject,
              decoration: const InputDecoration(labelText: 'Subject')),
          const SizedBox(height: 10),
          TextField(
              controller: _teacher,
              decoration:
                  const InputDecoration(labelText: 'Teacher / duty teacher')),
          const SizedBox(height: 10),
          TextField(
              controller: _room,
              decoration: const InputDecoration(labelText: 'Room (optional)')),
          const SizedBox(height: 12),
          FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: const Icon(Icons.add_rounded),
              label: Text(_saving ? 'Saving…' : 'Add to timetable')),
        ])),
        const SizedBox(height: 18),
        if (_class == null)
          const Text('Select a class to view its Monday–Saturday grid.')
        else
          StreamBuilder<List<Map<String, dynamic>>>(
              stream: ref.read(timetableServiceProvider).watchForClass(_class!),
              builder: (_, AsyncSnapshot<List<Map<String, dynamic>>> snap) {
                if (!snap.hasData)
                  return const Center(child: CircularProgressIndicator());
                return _grid(snap.data!);
              }),
      ])),
    );
  }
}
