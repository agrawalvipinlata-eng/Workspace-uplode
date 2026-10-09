import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_language.dart';
import '../../../core/theme/nmb_colors.dart';
import '../../../core/theme/nmb_typography.dart';
import '../../../core/utils/result.dart';
import '../../../core/widgets/nmb_card.dart';
import '../../../core/widgets/nmb_dialogs.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/app_user.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';
import '../../../services/leave_service.dart';

/// 📝 LEAVE / ABSENCE APPLICATION — student app se hi school ko
/// online application bhejta hai. Status track: pending → approved/rejected.
class LeaveApplicationScreen extends ConsumerStatefulWidget {
  const LeaveApplicationScreen({super.key});

  @override
  ConsumerState<LeaveApplicationScreen> createState() =>
      _LeaveApplicationScreenState();
}

class _LeaveApplicationScreenState
    extends ConsumerState<LeaveApplicationScreen> {
  DateTime _from = DateTime.now();
  DateTime _to = DateTime.now();
  final TextEditingController _reason = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool from}) async {
    final DateTime? d = await showDatePicker(
      context: context,
      initialDate: from ? _from : _to,
      firstDate: DateTime.now().subtract(const Duration(days: 7)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (d == null) return;
    setState(() {
      if (from) {
        _from = d;
        if (_to.isBefore(_from)) _to = _from;
      } else {
        _to = d.isBefore(_from) ? _from : d;
      }
    });
  }

  Future<void> _submit(AppUser me) async {
    if (_reason.text.trim().length < 5) {
      showNmbSnack(
        context,
        tr('Please write a proper reason (min 5 letters).',
            'कृपया सही कारण लिखें (कम से कम 5 अक्षर)।',),
        isError: true,
      );
      return;
    }
    setState(() => _sending = true);
    final LeaveService svc = ref.read(leaveServiceProvider);
    final Result<void> r = await svc.submit(
      uid: me.uid,
      name: me.fullName,
      classSection: me.classSection ?? '-',
      rollNumber: me.rollNumber,
      fromDate: _from,
      toDate: _to,
      reason: _reason.text.trim(),
    );
    if (!mounted) return;
    setState(() => _sending = false);
    r.when(
      ok: (_) {
        _reason.clear();
        showNmbSnack(
          context,
          tr('Application sent to school ✓', 'अर्ज़ी स्कूल भेज दी गई ✓'),
          isSuccess: true,
        );
      },
      err: (AppFailure f) => showNmbSnack(context, f.message, isError: true),
    );
  }

  String _fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';

  @override
  Widget build(BuildContext context) {
    final AppUser? me = ref.watch(myProfileProvider).valueOrNull;
    if (me == null) {
      return const Scaffold(body: LoadingView());
    }
    final LeaveService svc = ref.watch(leaveServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Leave Application', 'छुट्टी की अर्ज़ी')),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: <Widget>[
          // ── Form ──
          NmbCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  tr('New Application', 'नई अर्ज़ी'),
                  style: NmbTypography.sectionTitle,
                ),
                const SizedBox(height: 4),
                Text(
                  tr(
                    'Absent rahoge? School ko pehle se batao — '
                    'application seedha class teacher ke paas jayegi.',
                    'अनुपस्थित रहोगे? स्कूल को पहले बताओ — अर्ज़ी सीधे '
                    'क्लास टीचर के पास जाएगी।',
                  ),
                  style: NmbTypography.caption,
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _DateBox(
                        label: tr('From', 'से'),
                        value: _fmt(_from),
                        onTap: () => _pickDate(from: true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _DateBox(
                        label: tr('To', 'तक'),
                        value: _fmt(_to),
                        onTap: () => _pickDate(from: false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _reason,
                  maxLines: 3,
                  maxLength: 200,
                  decoration: InputDecoration(
                    hintText: tr('Reason (e.g. fever, family function…)',
                        'कारण (जैसे बुखार, पारिवारिक कार्यक्रम…)',),
                  ),
                ),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: _sending ? null : () => _submit(me),
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_rounded),
                  label: Text(_sending
                      ? tr('Sending…', 'भेज रहे…')
                      : tr('Send Application', 'अर्ज़ी भेजें'),),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ── Meri applications ──
          Text(
            tr('My Applications', 'मेरी अर्ज़ियाँ'),
            style: NmbTypography.sectionTitle,
          ),
          const SizedBox(height: 10),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: svc.myApplications(me.uid),
            builder: (BuildContext ctx,
                AsyncSnapshot<List<Map<String, dynamic>>> snap,) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(30),
                  child: LoadingView(),
                );
              }
              final List<Map<String, dynamic>> apps =
                  snap.data ?? const <Map<String, dynamic>>[];
              if (apps.isEmpty) {
                return NmbCard(
                  child: Text(
                    tr('No applications yet.', 'अभी कोई अर्ज़ी नहीं।'),
                    style: NmbTypography.bodySecondary,
                  ),
                );
              }
              return Column(
                children: <Widget>[
                  for (final Map<String, dynamic> a in apps.take(10))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _AppTile(app: a),
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  const _DateBox({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: NmbColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: NmbColors.divider),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(label, style: NmbTypography.caption),
            const SizedBox(height: 2),
            Row(
              children: <Widget>[
                Icon(Icons.event_rounded,
                    size: 16, color: NmbColors.primary,),
                const SizedBox(width: 6),
                Text(value,
                    style: NmbTypography.body
                        .copyWith(fontWeight: FontWeight.w700),),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AppTile extends StatelessWidget {
  const _AppTile({required this.app});

  final Map<String, dynamic> app;

  @override
  Widget build(BuildContext context) {
    final String status = (app['status'] as String?) ?? 'pending';
    final Color fg = switch (status) {
      'approved' => NmbColors.success,
      'rejected' => NmbColors.danger,
      _ => NmbColors.warning,
    };
    final Color bg = switch (status) {
      'approved' => NmbColors.successSoft,
      'rejected' => NmbColors.dangerSoft,
      _ => NmbColors.warningSoft,
    };
    final String statusLabel = switch (status) {
      'approved' => tr('APPROVED ✓', 'स्वीकृत ✓'),
      'rejected' => tr('REJECTED', 'अस्वीकृत'),
      _ => tr('PENDING…', 'विचाराधीन…'),
    };
    final Timestamp? created = app['createdAt'] as Timestamp?;
    return NmbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '${app['fromDate']} → ${app['toDate']}',
                  style: NmbTypography.cardTitle,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 4,),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: NmbTypography.caption.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text((app['reason'] as String?) ?? '',
              style: NmbTypography.bodySecondary,),
          if ((app['decisionNote'] as String?)?.isNotEmpty == true) ...<Widget>[
            const SizedBox(height: 6),
            Text(
              'School note: ${app['decisionNote']}',
              style: NmbTypography.caption.copyWith(
                color: NmbColors.danger,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (created != null) ...<Widget>[
            const SizedBox(height: 4),
            Text(
              '${tr('Sent', 'भेजी गई')}: '
              '${created.toDate().day.toString().padLeft(2, '0')}-'
              '${created.toDate().month.toString().padLeft(2, '0')}-'
              '${created.toDate().year}',
              style: NmbTypography.caption,
            ),
          ],
        ],
      ),
    );
  }
}
