import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/nmb_colors.dart';
import '../../../core/theme/nmb_typography.dart';
import '../../../core/utils/result.dart';
import '../../../core/widgets/nmb_card.dart';
import '../../../core/widgets/nmb_dialogs.dart';
import '../../../core/widgets/nmb_visuals.dart';
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
  String? _classSection;
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

  Future<void> _runAction(List<AppUser> selected, _BulkAction action) async {
    if (selected.isEmpty)
      return _snack('Select at least one student.', error: true);
    final bool destructive = action == _BulkAction.delete;
    final bool confirmed = await showNmbConfirmDialog(
      context,
      title: action.title(selected.length),
      message: action.message(selected.length),
      confirmLabel: action.confirmLabel,
      destructive: destructive || action == _BulkAction.dismiss,
      icon: action.icon,
    );
    if (!confirmed) return;
    setState(() => _working = true);
    int success = 0;
    for (final AppUser student in selected) {
      Result<void> result;
      if (action == _BulkAction.delete) {
        result =
            await ref.read(adminServiceProvider).deleteUserPermanently(student);
      } else {
        result = await ref.read(adminServiceProvider).setAccountActive(
            uid: student.uid, active: action == _BulkAction.renew);
      }
      result.when(ok: (_) => success++, err: (_) {});
    }
    if (!mounted) return;
    setState(() {
      _working = false;
      _selected.clear();
    });
    _snack('$success of ${selected.length} accounts processed.',
        success: success > 0);
  }

  @override
  Widget build(BuildContext context) {
    final List<AppUser> all =
        ref.watch(allStudentsProvider).valueOrNull ?? const <AppUser>[];
    final Map<String, List<AppUser>> groups = <String, List<AppUser>>{};
    for (final AppUser student in all) {
      final String key = student.classSection?.trim().isNotEmpty == true
          ? student.classSection!
          : 'Unassigned';
      (groups[key] ??= <AppUser>[]).add(student);
    }
    final List<AppUser> classStudents =
        groups[_classSection] ?? const <AppUser>[];
    final String q = _query.trim().toLowerCase();
    final List<AppUser> visible = classStudents
        .where((AppUser s) =>
            q.isEmpty ||
            '${s.fullName} ${s.rollNumber} ${s.email}'
                .toLowerCase()
                .contains(q))
        .toList();
    final bool allSelected = visible.isNotEmpty &&
        visible.every((AppUser s) => _selected.contains(s.uid));
    return Scaffold(
      appBar: AppBar(
        leading: _classSection == null
            ? null
            : IconButton(
                onPressed: () => setState(() {
                      _classSection = null;
                      _selected.clear();
                      _query = '';
                    }),
                icon: const Icon(Icons.arrow_back_rounded)),
        title: Text(_classSection == null ? 'Bulk Actions' : _classSection!),
      ),
      body: ResponsiveBody(
          child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _classSection == null
                  ? _ClassPicker(
                      groups: groups,
                      onSelect: (String value) =>
                          setState(() => _classSection = value))
                  : _StudentPicker(
                      students: visible,
                      total: classStudents.length,
                      selected: _selected,
                      allSelected: allSelected,
                      query: _query,
                      working: _working,
                      onQuery: (String value) => setState(() => _query = value),
                      onSelectAll: () => setState(() {
                            if (allSelected) {
                              _selected
                                  .removeAll(visible.map((AppUser s) => s.uid));
                            } else {
                              _selected
                                  .addAll(visible.map((AppUser s) => s.uid));
                            }
                          }),
                      onToggle: (String uid, bool value) => setState(() {
                            if (value)
                              _selected.add(uid);
                            else
                              _selected.remove(uid);
                          }),
                      onAction: (_BulkAction action) => _runAction(
                          classStudents
                              .where((AppUser s) => _selected.contains(s.uid))
                              .toList(),
                          action)))),
    );
  }
}

class _ClassPicker extends StatelessWidget {
  const _ClassPicker({required this.groups, required this.onSelect});
  final Map<String, List<AppUser>> groups;
  final ValueChanged<String> onSelect;
  @override
  Widget build(BuildContext context) =>
      ListView(padding: const EdgeInsets.only(bottom: 24), children: <Widget>[
        const NmbGradientHeader(
            title: 'Bulk Action',
            subtitle: 'Select a class to manage all students',
            icon: Icons.checklist_rounded),
        const SizedBox(height: 16),
        Text('Classes & sections', style: NmbTypography.sectionTitle),
        const SizedBox(height: 10),
        for (final MapEntry<String, List<AppUser>> entry in groups.entries)
          Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: NmbCard(
                  onTap: () => onSelect(entry.key),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                  child: Row(children: <Widget>[
                    Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                            color: _classColor(entry.key).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(14)),
                        child: Icon(Icons.groups_rounded,
                            color: _classColor(entry.key))),
                    const SizedBox(width: 13),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                          Text(entry.key, style: NmbTypography.cardTitle),
                          const SizedBox(height: 3),
                          Text('${entry.value.length} students',
                              style: NmbTypography.caption)
                        ])),
                    Icon(Icons.chevron_right_rounded,
                        color: NmbColors.textTertiary),
                  ]))),
        if (groups.isEmpty)
          const Padding(
              padding: EdgeInsets.all(30),
              child: Center(child: Text('No students found.'))),
      ]);
  static Color _classColor(String key) =>
      Color.lerp(NmbColors.primary, NmbColors.accent,
          (key.hashCode.abs() % 100) / 100) ??
      NmbColors.primary;
}

class _StudentPicker extends StatelessWidget {
  const _StudentPicker(
      {required this.students,
      required this.total,
      required this.selected,
      required this.allSelected,
      required this.query,
      required this.working,
      required this.onQuery,
      required this.onSelectAll,
      required this.onToggle,
      required this.onAction});
  final List<AppUser> students;
  final int total;
  final Set<String> selected;
  final bool allSelected;
  final String query;
  final bool working;
  final ValueChanged<String> onQuery;
  final VoidCallback onSelectAll;
  final void Function(String uid, bool value) onToggle;
  final ValueChanged<_BulkAction> onAction;

  @override
  Widget build(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: <Widget>[
        Row(children: <Widget>[
          Expanded(
              child: Text('Total Students: $total',
                  style: NmbTypography.bodySecondary)),
          NmbStatusPill(
              label: '${selected.length} Selected',
              color:
                  selected.isEmpty ? NmbColors.textTertiary : NmbColors.primary)
        ]),
        const SizedBox(height: 12),
        Row(children: <Widget>[
          Expanded(
              child: TextField(
                  onChanged: onQuery,
                  decoration: const InputDecoration(
                      hintText: 'Search student',
                      prefixIcon: Icon(Icons.search_rounded)))),
          const SizedBox(width: 8),
          OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.tune_rounded),
              label: const Text('Filter'))
        ]),
        const SizedBox(height: 8),
        Row(children: <Widget>[
          Text('${selected.length} selected', style: NmbTypography.caption),
          const Spacer(),
          TextButton(
              onPressed: students.isEmpty ? null : onSelectAll,
              child: Text(allSelected ? 'Deselect All' : 'Select All'))
        ]),
        const Divider(),
        Expanded(
            child: students.isEmpty
                ? const Center(child: Text('No students match this search.'))
                : ListView.builder(
                    itemCount: students.length,
                    itemBuilder: (_, int index) {
                      final AppUser student = students[index];
                      final bool checked = selected.contains(student.uid);
                      return NmbCard(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          color: checked
                              ? NmbColors.primarySoft
                              : NmbColors.surface,
                          child: CheckboxListTile(
                              value: checked,
                              onChanged: working
                                  ? null
                                  : (bool? value) =>
                                      onToggle(student.uid, value == true),
                              controlAffinity: ListTileControlAffinity.leading,
                              secondary: CircleAvatar(
                                  backgroundColor: NmbColors.accentSoft,
                                  child: Text(student.fullName.isEmpty
                                      ? '?'
                                      : student.fullName[0].toUpperCase())),
                              title: Text(student.fullName,
                                  style: NmbTypography.cardTitle),
                              subtitle: Text(
                                  'Roll No. ${student.rollNumber ?? '-'}  •  ${student.isActive ? 'Active' : 'Dismissed'}')));
                    })),
        const SizedBox(height: 10),
        FilledButton.icon(
            onPressed: working || selected.isEmpty
                ? null
                : () => _showActions(context),
            icon: const Icon(Icons.bolt_rounded),
            label: Text(working
                ? 'Processing…'
                : 'Bulk Actions  •  ${selected.length} selected')),
      ]);

  void _showActions(BuildContext context) {
    showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (BuildContext sheet) => SafeArea(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Bulk Actions', style: NmbTypography.sectionTitle),
                      const SizedBox(height: 8),
                      _ActionTile(
                          icon: Icons.block_rounded,
                          color: NmbColors.warning,
                          title: 'Dismiss All Accounts',
                          subtitle: 'Deactivate selected student accounts',
                          onTap: () {
                            Navigator.pop(sheet);
                            onAction(_BulkAction.dismiss);
                          }),
                      _ActionTile(
                          icon: Icons.delete_forever_rounded,
                          color: NmbColors.danger,
                          title: 'Delete All Accounts Permanently',
                          subtitle: 'Permanently delete selected accounts',
                          onTap: () {
                            Navigator.pop(sheet);
                            onAction(_BulkAction.delete);
                          }),
                      _ActionTile(
                          icon: Icons.autorenew_rounded,
                          color: NmbColors.success,
                          title: 'Renew All Accounts',
                          subtitle: 'Reactivate selected student accounts',
                          onTap: () {
                            Navigator.pop(sheet);
                            onAction(_BulkAction.renew);
                          }),
                      OutlinedButton(
                          onPressed: () => Navigator.pop(sheet),
                          child: const Text('Cancel')),
                    ]))));
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile(
      {required this.icon,
      required this.color,
      required this.title,
      required this.subtitle,
      required this.onTap});
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
              color: color.withOpacity(0.12), shape: BoxShape.circle),
          child: Icon(icon, color: color)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(subtitle));
}

enum _BulkAction { dismiss, delete, renew }

extension on _BulkAction {
  String title(int count) => switch (this) {
        _BulkAction.dismiss =>
          'Dismiss $count account${count == 1 ? '' : 's'}?',
        _BulkAction.delete =>
          'Delete $count account${count == 1 ? '' : 's'} permanently?',
        _BulkAction.renew => 'Renew $count account${count == 1 ? '' : 's'}?'
      };
  String message(int count) => switch (this) {
        _BulkAction.dismiss =>
          'Selected students will not be able to log in until renewed.',
        _BulkAction.delete =>
          'This action is irreversible. Student profiles and related data may be removed.',
        _BulkAction.renew =>
          'Selected students will be able to log in and access the app again.'
      };
  String get confirmLabel => switch (this) {
        _BulkAction.dismiss => 'Yes, Dismiss All',
        _BulkAction.delete => 'Yes, Delete Permanently',
        _BulkAction.renew => 'Yes, Renew All'
      };
  IconData get icon => switch (this) {
        _BulkAction.dismiss => Icons.warning_amber_rounded,
        _BulkAction.delete => Icons.delete_forever_rounded,
        _BulkAction.renew => Icons.autorenew_rounded
      };
}
