import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
  String _classFilter = 'All classes';
  bool _working = false;

  Future<void> _setStatus(List<AppUser> students, bool active) async {
    if (_selected.isEmpty) {
      _snack('Select at least one student.', error: true);
      return;
    }
    setState(() => _working = true);
    int success = 0;
    for (final AppUser student in students) {
      if (!_selected.contains(student.uid)) continue;
      final result = await ref.read(adminServiceProvider).setAccountActive(
            uid: student.uid,
            active: active,
          );
      result.when(ok: (_) => success++, err: (_) {});
    }
    if (!mounted) return;
    setState(() {
      _working = false;
      _selected.clear();
    });
    _snack('$success student account${success == 1 ? '' : 's'} updated.',
        success: success > 0);
  }

  void _snack(String message, {bool error = false, bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: error
          ? NmbColors.danger
          : success
              ? NmbColors.success
              : null,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final List<AppUser> all =
        ref.watch(allStudentsProvider).valueOrNull ?? const <AppUser>[];
    final List<String> classes = all
        .map((AppUser s) => s.classSection ?? '')
        .where((String value) => value.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final List<String> filters = <String>['All classes', ...classes];
    final List<AppUser> visible = _classFilter == 'All classes'
        ? all
        : all.where((AppUser s) => s.classSection == _classFilter).toList();
    final bool allSelected = visible.isNotEmpty &&
        visible.every((AppUser student) => _selected.contains(student.uid));

    return Scaffold(
      appBar: AppBar(title: const Text('Bulk Actions')),
      body: ResponsiveBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const Text('Select students',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text('Apply account actions to multiple students together.'),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _classFilter,
              decoration: const InputDecoration(labelText: 'Class filter'),
              items: <DropdownMenuItem<String>>[
                for (final String filter in filters)
                  DropdownMenuItem<String>(value: filter, child: Text(filter)),
              ],
              onChanged: (String? value) => setState(() {
                _classFilter = value ?? 'All classes';
                _selected.clear();
              }),
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Text('${_selected.length} selected'),
                const Spacer(),
                TextButton.icon(
                  onPressed: visible.isEmpty
                      ? null
                      : () => setState(() {
                            if (allSelected) {
                              _selected
                                  .removeAll(visible.map((AppUser s) => s.uid));
                            } else {
                              _selected
                                  .addAll(visible.map((AppUser s) => s.uid));
                            }
                          }),
                  icon: Icon(allSelected
                      ? Icons.deselect_rounded
                      : Icons.select_all_rounded),
                  label: Text(allSelected ? 'Clear all' : 'Select all'),
                ),
              ],
            ),
            Expanded(
              child: ListView.builder(
                itemCount: visible.length,
                itemBuilder: (BuildContext context, int index) {
                  final AppUser student = visible[index];
                  final bool selected = _selected.contains(student.uid);
                  return NmbCard(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    child: CheckboxListTile(
                      value: selected,
                      onChanged: (bool? value) => setState(() {
                        if (value == true) {
                          _selected.add(student.uid);
                        } else {
                          _selected.remove(student.uid);
                        }
                      }),
                      secondary: CircleAvatar(
                          child: Text(student.fullName.isEmpty
                              ? '?'
                              : student.fullName[0].toUpperCase())),
                      title: Text(student.fullName),
                      subtitle: Text(
                          '${student.classSection ?? '-'} • Roll ${student.rollNumber ?? '-'}'),
                      controlAffinity: ListTileControlAffinity.leading,
                    ),
                  );
                },
              ),
            ),
            Row(
              children: <Widget>[
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed:
                            _working ? null : () => _setStatus(visible, true),
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Enable'))),
                const SizedBox(width: 10),
                Expanded(
                    child: FilledButton.icon(
                        onPressed:
                            _working ? null : () => _setStatus(visible, false),
                        icon: const Icon(Icons.block_outlined),
                        label: const Text('Disable'))),
              ],
            ),
            const SizedBox(height: 8),
            OutlinedButton.icon(
                onPressed: () => context.go('/admin/notices'),
                icon: const Icon(Icons.campaign_outlined),
                label: const Text('Send class notice')),
          ],
        ),
      ),
    );
  }
}
