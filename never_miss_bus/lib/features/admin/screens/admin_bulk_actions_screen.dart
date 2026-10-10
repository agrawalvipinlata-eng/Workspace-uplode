import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/nmb_constants.dart';
import '../../../core/theme/nmb_colors.dart';
import '../../../core/widgets/nmb_card.dart';
import '../../../core/widgets/responsive_scaffold_body.dart';
import '../../../models/app_user.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';

class AdminBulkActionsScreen extends ConsumerStatefulWidget {
  const AdminBulkActionsScreen({super.key});
  @override
  ConsumerState<AdminBulkActionsScreen> createState() =>
      _AdminBulkActionsScreenState();
}

class _AdminBulkActionsScreenState
    extends ConsumerState<AdminBulkActionsScreen> {
  final Set<String> _selected = <String>{};
  String? _class;
  String? _section;
  String _query = '';
  bool _working = false;
  void _snack(String text, {bool error = false, bool success = false}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(text),
          backgroundColor: error
              ? NmbColors.danger
              : success
                  ? NmbColors.success
                  : null));
  Future<void> _setStatus(List<AppUser> visible, bool active) async {
    if (_selected.isEmpty)
      return _snack('Select at least one student.', error: true);
    setState(() => _working = true);
    int success = 0;
    for (final AppUser s
        in visible.where((AppUser s) => _selected.contains(s.uid))) {
      final result = await ref
          .read(adminServiceProvider)
          .setAccountActive(uid: s.uid, active: active);
      result.when(ok: (_) => success++, err: (_) {});
    }
    if (!mounted) return;
    setState(() {
      _working = false;
      _selected.clear();
    });
    _snack(
        '$success account${success == 1 ? '' : 's'} ${active ? 'enabled' : 'disabled'}.',
        success: success > 0);
  }

  Future<void> _promote(List<AppUser> visible) async {
    if (_selected.isEmpty) return _snack('Select students first.', error: true);
    final int currentIndex =
        _class == null ? -1 : SchoolClasses.classes.indexOf(_class!);
    if (currentIndex < 0 || currentIndex >= SchoolClasses.classes.length - 1)
      return _snack('Choose a class before the final class to promote.',
          error: true);
    setState(() => _working = true);
    int success = 0;
    final String nextClass = SchoolClasses.classes[currentIndex + 1];
    for (final AppUser s
        in visible.where((AppUser s) => _selected.contains(s.uid))) {
      final parts = (s.classSection ?? '').split('-');
      final result = await ref.read(adminServiceProvider).promoteStudent(
          uid: s.uid,
          classSection: '$nextClass-${parts.length > 1 ? parts[1] : 'A'}',
          rollNumber: s.rollNumber ?? '1',
          removeDocuments: const <String>[]);
      result.when(ok: (_) => success++, err: (_) {});
    }
    if (!mounted) return;
    setState(() {
      _working = false;
      _selected.clear();
    });
    _snack('$success student${success == 1 ? '' : 's'} promoted.',
        success: success > 0);
  }

  @override
  Widget build(BuildContext context) {
    final List<AppUser> all =
        ref.watch(allStudentsProvider).valueOrNull ?? const <AppUser>[];
    final String? selectedClass = _class == null || _section == null
        ? null
        : SchoolClasses.label(_class!, _section!);
    final String q = _query.trim().toLowerCase();
    final List<AppUser> visible = all.where((AppUser s) {
      final bool classMatch =
          selectedClass == null || s.classSection == selectedClass;
      final bool queryMatch = q.isEmpty ||
          '${s.fullName} ${s.classSection} ${s.rollNumber} ${s.email}'
              .toLowerCase()
              .contains(q);
      return classMatch && queryMatch;
    }).toList();
    final bool allSelected = visible.isNotEmpty &&
        visible.every((AppUser s) => _selected.contains(s.uid));
    return Scaffold(
        appBar: AppBar(title: const Text('Bulk Actions')),
        body: ResponsiveBody(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
              const Text('Class-wise student actions',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              const Text(
                  'Select a class and section, then enable, disable or promote many students together.'),
              const SizedBox(height: 12),
              Row(children: <Widget>[
                Expanded(
                    child: DropdownButtonFormField<String>(
                        value: _class,
                        decoration: const InputDecoration(labelText: 'Class'),
                        items: <DropdownMenuItem<String>>[
                          for (final String c in SchoolClasses.classes)
                            DropdownMenuItem(value: c, child: Text(c))
                        ],
                        onChanged: (String? v) => setState(() {
                              _class = v;
                              _section = null;
                              _selected.clear();
                            }))),
                const SizedBox(width: 10),
                Expanded(
                    child: DropdownButtonFormField<String>(
                        value: _section,
                        decoration: const InputDecoration(labelText: 'Section'),
                        items: <DropdownMenuItem<String>>[
                          for (final String s in SchoolClasses.sections)
                            DropdownMenuItem(value: s, child: Text(s))
                        ],
                        onChanged: (String? v) => setState(() {
                              _section = v;
                              _selected.clear();
                            }))),
              ]),
              const SizedBox(height: 10),
              TextField(
                  decoration: const InputDecoration(
                      hintText: 'Search name or roll number',
                      prefixIcon: Icon(Icons.search_rounded)),
                  onChanged: (String v) => setState(() => _query = v)),
              Row(children: <Widget>[
                Text(
                    '${visible.length} students • ${_selected.length} selected'),
                const Spacer(),
                TextButton.icon(
                    onPressed: visible.isEmpty
                        ? null
                        : () => setState(() {
                              if (allSelected) {
                                _selected.removeAll(
                                    visible.map((AppUser s) => s.uid));
                              } else {
                                _selected
                                    .addAll(visible.map((AppUser s) => s.uid));
                              }
                            }),
                    icon: Icon(allSelected
                        ? Icons.deselect_rounded
                        : Icons.select_all_rounded),
                    label: Text(allSelected ? 'Clear all' : 'Select all'))
              ]),
              Expanded(
                  child: visible.isEmpty
                      ? const Center(
                          child:
                              Text('Select a class/section or adjust search.'))
                      : ListView.builder(
                          itemCount: visible.length,
                          itemBuilder: (_, int i) {
                            final AppUser s = visible[i];
                            return NmbCard(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                child: CheckboxListTile(
                                    value: _selected.contains(s.uid),
                                    onChanged: (bool? v) => setState(() {
                                          if (v == true) {
                                            _selected.add(s.uid);
                                          } else {
                                            _selected.remove(s.uid);
                                          }
                                        }),
                                    title: Text(s.fullName),
                                    subtitle: Text(
                                        '${s.classSection ?? '-'} • Roll ${s.rollNumber ?? '-'}'),
                                    secondary: CircleAvatar(
                                        child: Text(s.fullName.isEmpty
                                            ? '?'
                                            : s.fullName[0].toUpperCase())),
                                    controlAffinity:
                                        ListTileControlAffinity.leading));
                          })),
              Row(
                children: <Widget>[
                  Expanded(
                      child: OutlinedButton.icon(
                          onPressed:
                              _working ? null : () => _setStatus(visible, true),
                          icon: const Icon(Icons.check_circle_outline),
                          label: const Text('Enable'))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: OutlinedButton.icon(
                          onPressed: _working
                              ? null
                              : () => _setStatus(visible, false),
                          icon: const Icon(Icons.block_outlined),
                          label: const Text('Disable'))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: FilledButton.icon(
                          onPressed: _working ? null : () => _promote(visible),
                          icon: const Icon(Icons.trending_up_rounded),
                          label: const Text('Promote')))
                ],
              ),
            ])));
  }
}
