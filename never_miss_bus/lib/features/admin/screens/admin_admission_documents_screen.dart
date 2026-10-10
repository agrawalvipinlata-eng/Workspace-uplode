import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/nmb_colors.dart';
import '../../../core/widgets/nmb_card.dart';
import '../../../core/widgets/responsive_scaffold_body.dart';
import '../../../models/app_user.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';

class AdminAdmissionDocumentsScreen extends ConsumerStatefulWidget {
  const AdminAdmissionDocumentsScreen({super.key});

  @override
  ConsumerState<AdminAdmissionDocumentsScreen> createState() =>
      _AdminAdmissionDocumentsScreenState();
}

class _AdminAdmissionDocumentsScreenState
    extends ConsumerState<AdminAdmissionDocumentsScreen> {
  static const List<String> _required = <String>[
    'Birth Certificate',
    'Transfer Certificate',
    'Address Proof',
    'ID Proof',
    'Medical Certificate',
    'Student Photo',
  ];

  String? _studentUid;
  Map<String, bool> _status = <String, bool>{};
  bool _saving = false;

  void _select(AppUser? student) {
    if (student == null) return;
    setState(() {
      _studentUid = student.uid;
      _status = <String, bool>{
        for (final String name in _required)
          name: student.documents[name] ?? false,
        ...student.documents,
      };
    });
  }

  Future<void> _save() async {
    if (_studentUid == null) return;
    setState(() => _saving = true);
    final result = await ref.read(adminServiceProvider).updateUserProfile(
      uid: _studentUid!,
      data: <String, dynamic>{'documents': _status},
    );
    if (!mounted) return;
    setState(() => _saving = false);
    result.when(
      ok: (_) => _snack('Document verification status saved.', success: true),
      err: (_) => _snack('Could not save document status.', error: true),
    );
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
    final List<AppUser> students =
        ref.watch(allStudentsProvider).valueOrNull ?? const <AppUser>[];
    AppUser? selected;
    for (final AppUser student in students) {
      if (student.uid == _studentUid) selected = student;
    }
    final int complete = _status.values.where((bool value) => value).length;
    return Scaffold(
      appBar: AppBar(title: const Text('Admission Documents')),
      body: ResponsiveBody(
        child: ListView(
          children: <Widget>[
            const Text('Document verification',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
            const SizedBox(height: 4),
            const Text(
                'Track admission documents without opening the GitHub repository.'),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              value: _studentUid,
              decoration: const InputDecoration(labelText: 'Select student'),
              items: <DropdownMenuItem<String>>[
                for (final AppUser student in students)
                  DropdownMenuItem<String>(
                      value: student.uid,
                      child: Text(
                          '${student.fullName} • ${student.classSection ?? '-'}')),
              ],
              onChanged: (String? value) {
                AppUser? picked;
                for (final AppUser student in students) {
                  if (student.uid == value) picked = student;
                }
                _select(picked);
              },
            ),
            if (selected != null) ...<Widget>[
              const SizedBox(height: 14),
              NmbCard(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text('$complete/${_required.length} documents verified',
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                          value: complete / _required.length,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(99)),
                      const SizedBox(height: 10),
                      for (final String name in _required)
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _status[name] ?? false,
                          onChanged: (bool? value) =>
                              setState(() => _status[name] = value ?? false),
                          title: Text(name),
                          secondary: Icon(
                              (_status[name] ?? false)
                                  ? Icons.verified_rounded
                                  : Icons.pending_outlined,
                              color: (_status[name] ?? false)
                                  ? NmbColors.success
                                  : NmbColors.warning),
                        ),
                      const SizedBox(height: 8),
                      FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: const Icon(Icons.save_rounded),
                          label: Text(_saving
                              ? 'Saving…'
                              : 'Save verification status')),
                    ]),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
