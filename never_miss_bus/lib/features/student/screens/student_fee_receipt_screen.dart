import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_language.dart';
import '../../../core/theme/nmb_colors.dart';
import '../../../core/theme/nmb_typography.dart';
import '../../../core/widgets/nmb_card.dart';
import '../../../models/app_user.dart';
import '../../../providers/data_providers.dart';

class StudentFeeReceiptScreen extends ConsumerWidget {
  const StudentFeeReceiptScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppUser? me = ref.watch(myProfileProvider).valueOrNull;
    if (me == null) return const Center(child: CircularProgressIndicator());
    final List<dynamic> history =
        (me.fees?['history'] as List?) ?? const <dynamic>[];
    return Scaffold(
      appBar: AppBar(
          title: Text(tr('Fee Receipt & History', 'फीस रसीद और हिस्ट्री'))),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          NmbCard(
            color: NmbColors.primarySoft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(tr('Fee summary', 'फीस सारांश'),
                    style: NmbTypography.sectionTitle),
                const SizedBox(height: 14),
                Row(children: <Widget>[
                  _Value(
                      label: tr('Total', 'कुल'),
                      value: '₹${me.feeTotal.toStringAsFixed(0)}',
                      color: NmbColors.primary),
                  _Value(
                      label: tr('Paid', 'जमा'),
                      value: '₹${me.feePaid.toStringAsFixed(0)}',
                      color: NmbColors.success),
                  _Value(
                      label: tr('Due', 'बाकी'),
                      value: '₹${me.feeDue.toStringAsFixed(0)}',
                      color: me.feeDue > 0
                          ? NmbColors.warning
                          : NmbColors.success),
                ]),
                if (me.feeDueDate != null && me.feeDue > 0) ...<Widget>[
                  const SizedBox(height: 12),
                  Text('${tr('Due date', 'अंतिम तारीख')}: ${me.feeDueDate}',
                      style: NmbTypography.bodySecondary),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(tr('Payment receipts', 'पेमेंट रसीदें'),
              style: NmbTypography.sectionTitle),
          const SizedBox(height: 8),
          if (history.isEmpty)
            const NmbCard(child: Text('No payment history yet.'))
          else
            for (int index = history.length - 1; index >= 0; index--)
              _ReceiptCard(entry: history[index]),
          const SizedBox(height: 16),
          Text(
            tr('Online payment is handled through the school UPI details. After payment, the school office verifies and updates this receipt history.',
                'Online payment school UPI details से होगा। Payment के बाद school office इस receipt history को update करेगा.'),
            style: NmbTypography.caption,
          ),
          const SizedBox(height: 90),
        ],
      ),
    );
  }
}

class _Value extends StatelessWidget {
  const _Value({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;
  @override
  Widget build(BuildContext context) => Expanded(
          child: Column(children: <Widget>[
        Text(value,
            style: TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800, color: color)),
        const SizedBox(height: 3),
        Text(label, style: NmbTypography.caption)
      ]));
}

class _ReceiptCard extends StatelessWidget {
  const _ReceiptCard({required this.entry});
  final dynamic entry;
  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> data = entry is Map
        ? Map<String, dynamic>.from(entry as Map)
        : <String, dynamic>{};
    final String amount = '${data['amount'] ?? data['paid'] ?? 0}';
    final String date = '${data['date'] ?? data['at'] ?? ''}';
    return NmbCard(
      padding: const EdgeInsets.all(12),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const CircleAvatar(child: Icon(Icons.receipt_long_rounded)),
        title: Text('₹$amount', style: NmbTypography.cardTitle),
        subtitle: Text(
            '${data['note'] ?? 'School fee payment'}${date.isEmpty ? '' : ' • $date'}'),
        trailing: const Icon(Icons.verified_rounded, color: NmbColors.success),
      ),
    );
  }
}
