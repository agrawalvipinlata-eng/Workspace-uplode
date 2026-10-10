import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/result.dart';
import '../../../core/widgets/nmb_card.dart';
import '../../../core/widgets/responsive_scaffold_body.dart';
import '../../../models/app_user.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';

class AdminNoticeBoardScreen extends ConsumerStatefulWidget {
  const AdminNoticeBoardScreen({super.key});

  @override
  ConsumerState<AdminNoticeBoardScreen> createState() =>
      _AdminNoticeBoardScreenState();
}

class _AdminNoticeBoardScreenState
    extends ConsumerState<AdminNoticeBoardScreen> {
  final TextEditingController _title = TextEditingController();
  final TextEditingController _body = TextEditingController();
  String _target = 'ALL';
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    final session = ref.read(currentSessionProvider);
    if (session == null ||
        _title.text.trim().isEmpty ||
        _body.text.trim().isEmpty) {
      _snack('Title और message भरें.', error: true);
      return;
    }
    setState(() => _saving = true);
    final Result<void> result =
        await ref.read(noticeBoardServiceProvider).publish(
              title: _title.text,
              body: _body.text,
              targetClass: _target,
              createdBy: session.uid,
            );
    if (!mounted) return;
    setState(() => _saving = false);
    result.when(
      ok: (_) {
        _title.clear();
        _body.clear();
        _snack('Notice published.', success: true);
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
                : null));
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
    final List<String> targets = <String>['ALL', ...classes];
    return Scaffold(
      appBar: AppBar(title: const Text('Notice Board')),
      body: ResponsiveBody(
          child: ListView(children: <Widget>[
        const Text('Publish notice',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
        const SizedBox(height: 14),
        NmbCard(
            child: Column(children: <Widget>[
          DropdownButtonFormField<String>(
              value: targets.contains(_target) ? _target : 'ALL',
              decoration: const InputDecoration(labelText: 'Audience'),
              items: <DropdownMenuItem<String>>[
                for (final String target in targets)
                  DropdownMenuItem<String>(
                      value: target,
                      child: Text(target == 'ALL' ? 'Everyone' : target))
              ],
              onChanged: (String? v) => setState(() => _target = v ?? 'ALL')),
          const SizedBox(height: 10),
          TextField(
              controller: _title,
              maxLength: 80,
              decoration: const InputDecoration(labelText: 'Title')),
          const SizedBox(height: 10),
          TextField(
              controller: _body,
              maxLength: 500,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Message')),
          const SizedBox(height: 14),
          FilledButton.icon(
              onPressed: _saving ? null : _publish,
              icon: const Icon(Icons.publish_rounded),
              label: Text(_saving ? 'Publishing…' : 'Publish notice')),
        ])),
      ])),
    );
  }
}
