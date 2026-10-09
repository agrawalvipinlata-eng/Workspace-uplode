import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/nmb_typography.dart';
import '../../../core/utils/result.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/nmb_card.dart';
import '../../../core/widgets/nmb_dialogs.dart';
import '../../../core/widgets/responsive_scaffold_body.dart';
import '../../../models/bus.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';

/// Compose an announcement to everyone or to one bus's students.
/// Delivery is server-side (Cloud Function): audiences are resolved from
/// the database, so a client can never widen the recipient list.
class AdminNotificationsScreen extends ConsumerStatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  ConsumerState<AdminNotificationsScreen> createState() =>
      _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState
    extends ConsumerState<AdminNotificationsScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _title = TextEditingController();
  final TextEditingController _body = TextEditingController();
  String _scope = 'all';
  String? _busId;
  bool _sending = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_scope == 'bus' && _busId == null) {
      showNmbSnack(context, 'Choose a bus for a bus-specific announcement.',
          isError: true,);
      return;
    }
    final bool confirmed = await showNmbConfirmDialog(
      context,
      title: 'Send announcement?',
      message: _scope == 'all'
          ? 'This will notify every active user.'
          : 'This will notify all students and the driver of the selected '
              'bus.',
      confirmLabel: 'Send',
      icon: Icons.campaign_rounded,
    );
    if (!confirmed || !mounted) return;

    setState(() => _sending = true);
    final Result<void> result =
        await ref.read(adminServiceProvider).sendAnnouncement(
              title: _title.text.trim(),
              body: _body.text.trim(),
              scope: _scope,
              busId: _scope == 'bus' ? _busId : null,
            );
    if (!mounted) return;
    setState(() => _sending = false);
    result.when(
      ok: (_) {
        _title.clear();
        _body.clear();
        showNmbSnack(context, 'Announcement sent.', isSuccess: true);
      },
      err: (AppFailure f) => showNmbSnack(context, f.message, isError: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Bus> buses =
        ref.watch(allBusesProvider).valueOrNull ?? const <Bus>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: ResponsiveBody(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text('Send an announcement',
                  style: NmbTypography.sectionTitle,),
              const SizedBox(height: 12),
              NmbCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    TextFormField(
                      controller: _title,
                      decoration:
                          const InputDecoration(hintText: 'Title'),
                      maxLength: 80,
                      validator: (String? v) =>
                          Validators.requiredField(v, label: 'Title'),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _body,
                      decoration:
                          const InputDecoration(hintText: 'Message'),
                      maxLines: 4,
                      maxLength: 400,
                      validator: (String? v) =>
                          Validators.requiredField(v, label: 'Message'),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<String>(
                      segments: const <ButtonSegment<String>>[
                        ButtonSegment<String>(
                          value: 'all',
                          label: Text('Everyone'),
                          icon: Icon(Icons.groups_rounded),
                        ),
                        ButtonSegment<String>(
                          value: 'bus',
                          label: Text('One bus'),
                          icon: Icon(Icons.directions_bus_rounded),
                        ),
                      ],
                      selected: <String>{_scope},
                      onSelectionChanged: (Set<String> s) =>
                          setState(() => _scope = s.first),
                    ),
                    if (_scope == 'bus') ...<Widget>[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _busId,
                        decoration:
                            const InputDecoration(hintText: 'Select bus'),
                        items: <DropdownMenuItem<String>>[
                          for (final Bus b in buses)
                            DropdownMenuItem<String>(
                              value: b.id,
                              child: Text(b.busNumber),
                            ),
                        ],
                        onChanged: (String? v) =>
                            setState(() => _busId = v),
                      ),
                    ],
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _sending ? null : _send,
                      icon: const Icon(Icons.send_rounded),
                      label: Text(
                          _sending ? 'Sending…' : 'Send announcement',),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const NmbCard(
                child: Text(
                  'Automatic notifications (trip started, bus approaching, '
                  'bus reached stop/school, tracking unavailable) are sent '
                  'by the system and don\'t need manual action.',
                  style: NmbTypography.bodySecondary,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
