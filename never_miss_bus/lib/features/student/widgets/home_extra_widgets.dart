import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_language.dart';
import '../../../core/theme/nmb_colors.dart';
import '../../../core/theme/nmb_typography.dart';
import '../../../core/widgets/nmb_card.dart';
import '../../../models/app_user.dart';
import '../../../models/bus.dart';
import '../../../models/bus_stop.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';

/// 📍 "I'M ON THE BUS" CHECK-IN (WhatsApp-status style).
/// Student tap kare → settings.busCheckin me time save → parents/teacher
/// ko profile me status dikhta hai. 3 ghante baad khud expire.
class CheckinWidget extends ConsumerStatefulWidget {
  const CheckinWidget({super.key, required this.me});

  final AppUser me;

  @override
  ConsumerState<CheckinWidget> createState() => _CheckinWidgetState();
}

class _CheckinWidgetState extends ConsumerState<CheckinWidget> {
  bool _busy = false;

  bool get _checkedIn {
    final int? at =
        widget.me.activeDeviceSettings?['busCheckinAt'] as int?;
    if (at == null) return false;
    final DateTime t = DateTime.fromMillisecondsSinceEpoch(at);
    return DateTime.now().difference(t) < const Duration(hours: 3);
  }

  Future<void> _toggle() async {
    final fs = ref.read(firestoreServiceProvider);
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await fs.saveUserSettings(widget.me.uid, <String, dynamic>{
        'busCheckinAt': _checkedIn
            ? null
            : DateTime.now().millisecondsSinceEpoch,
      });
      messenger.showSnackBar(SnackBar(
        backgroundColor: const Color(0xFF1E8E3E),
        content: Text(
          _checkedIn
              ? tr('Checked out ✓', 'चेक-आउट ✓')
              : tr("Checked in — you're on the bus ✓",
                  'चेक-इन ✓ — आप बस में हैं',),
          style: const TextStyle(color: Colors.white),
        ),
      ),);
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Failed — try again'),
      ),);
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final bool on = _checkedIn;
    return NmbCard(
      color: on ? NmbColors.successSoft : NmbColors.surface,
      borderColor: on ? NmbColors.success : null,
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: on ? NmbColors.success : NmbColors.primarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              on
                  ? Icons.check_circle_rounded
                  : Icons.directions_bus_filled_rounded,
              color: on ? Colors.white : NmbColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  on
                      ? tr("You're on the bus ✓", 'आप बस में हैं ✓')
                      : tr("I'm on the Bus", 'मैं बस में हूँ'),
                  style: NmbTypography.cardTitle,
                ),
                Text(
                  on
                      ? tr('Parents can see your status',
                          'Parents status dekh sakte hain',)
                      : tr('Tap when you board the bus',
                          'Bus me baithte hi tap karo',),
                  style: NmbTypography.bodySecondary,
                ),
              ],
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(90, 40),
              backgroundColor:
                  on ? NmbColors.textTertiary : NmbColors.success,
            ),
            onPressed: _busy ? null : _toggle,
            child: Text(on
                ? tr('Check out', 'चेक-आउट')
                : tr('Check in', 'चेक-इन'),),
          ),
        ],
      ),
    );
  }
}

/// 👨‍✈️ MY DRIVER CARD — driver ka naam (galat bus se bachao).
class DriverCardWidget extends ConsumerWidget {
  const DriverCardWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Bus? bus = ref.watch(myBusProvider).valueOrNull;
    if (bus?.driverId == null) return const SizedBox.shrink();
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance
          .collection('users')
          .doc(bus!.driverId)
          .get(),
      builder: (BuildContext ctx, snapshot) {
        final String name = (snapshot.data?.data()?['fullName']
                as String?) ??
            tr('Your driver', 'आपके ड्राइवर');
        return NmbCard(
          child: Row(
            children: <Widget>[
              CircleAvatar(
                radius: 24,
                backgroundColor: NmbColors.accentSoft,
                child: Icon(Icons.badge_rounded,
                    color: NmbColors.accentDark,),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(tr('My Driver', 'मेरे ड्राइवर'),
                        style: NmbTypography.caption,),
                    Text(name, style: NmbTypography.cardTitle),
                    Text('${bus.busNumber} • ${bus.plateNumber}',
                        style: NmbTypography.bodySecondary,),
                  ],
                ),
              ),
              const Icon(Icons.verified_user_rounded,
                  color: NmbColors.success,),
            ],
          ),
        );
      },
    );
  }
}

/// 🕐 BUS TIMETABLE — pickup/drop time ek card me.
class TimetableWidget extends ConsumerWidget {
  const TimetableWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BusStop? myStop = ref.watch(myAssignedStopProvider);
    if (myStop?.scheduledTime == null) return const SizedBox.shrink();
    return NmbCard(
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFEFEAFF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.schedule_rounded,
                color: Color(0xFF7B61FF),),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(tr('Bus Timetable', 'बस समय-सारणी'),
                    style: NmbTypography.caption,),
                Text(
                  '${tr('Pickup', 'पिकअप')}: ${myStop!.scheduledTime}',
                  style: NmbTypography.cardTitle,
                ),
                Text(
                  '${tr('Stop', 'स्टॉप')}: ${myStop.name}',
                  style: NmbTypography.bodySecondary,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 📰 SCHOOL NOTICES — announcements ka clean feed (Classroom style).
class NoticesWidget extends ConsumerWidget {
  const NoticesWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inbox = ref.watch(inboxProvider).valueOrNull ?? const [];
    final notices = inbox
        .where((n) => n.type.name == 'announcement')
        .take(2)
        .toList();
    if (notices.isEmpty) return const SizedBox.shrink();
    return NmbCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.campaign_rounded,
                  color: NmbColors.primary, size: 20,),
              const SizedBox(width: 8),
              Text(tr('School Notices', 'स्कूल सूचनाएं'),
                  style: NmbTypography.sectionTitle,),
            ],
          ),
          const SizedBox(height: 8),
          for (final n in notices)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: NmbColors.primarySoft,
                  borderRadius: BorderRadius.circular(10),
                  border: Border(
                    left: BorderSide(color: NmbColors.primary, width: 3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(n.title, style: NmbTypography.cardTitle),
                    Text(
                      n.body,
                      style: NmbTypography.bodySecondary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
