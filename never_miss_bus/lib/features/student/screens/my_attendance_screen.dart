import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_language.dart';
import '../../../core/theme/nmb_colors.dart';
import '../../../core/theme/nmb_typography.dart';
import '../../../core/widgets/nmb_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/app_user.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';
import '../../../services/attendance_service.dart';

/// 🗓️ MY ATTENDANCE — poora month ka CALENDAR view:
/// green = present, red = absent, grey = attendance nahi lagi/chhutti.
/// Upar counts (present/absent/%), neeche "Send Leave Application" button.
class MyAttendanceScreen extends ConsumerStatefulWidget {
  const MyAttendanceScreen({super.key});

  @override
  ConsumerState<MyAttendanceScreen> createState() =>
      _MyAttendanceScreenState();
}

class _MyAttendanceScreenState extends ConsumerState<MyAttendanceScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  void _shiftMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
    });
  }

  static const List<String> _monthsEn = <String>[
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const List<String> _monthsHi = <String>[
    'जनवरी', 'फ़रवरी', 'मार्च', 'अप्रैल', 'मई', 'जून',
    'जुलाई', 'अगस्त', 'सितंबर', 'अक्टूबर', 'नवंबर', 'दिसंबर',
  ];

  @override
  Widget build(BuildContext context) {
    final AppUser? me = ref.watch(myProfileProvider).valueOrNull;
    if (me == null || me.classSection == null) {
      return Scaffold(
        appBar: AppBar(title: Text(tr('My Attendance', 'मेरी उपस्थिति'))),
        body: const LoadingView(),
      );
    }
    final AttendanceService svc = ref.watch(attendanceServiceProvider);
    final String monthName = appLanguage.value == 'hi'
        ? _monthsHi[_month.month - 1]
        : _monthsEn[_month.month - 1];
    final bool isCurrentMonth = _month.year == DateTime.now().year &&
        _month.month == DateTime.now().month;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('My Attendance', 'मेरी उपस्थिति')),
      ),
      body: FutureBuilder<({int present, int absent, Map<String, bool> days})>(
        key: ValueKey<String>('att_${_month.year}_${_month.month}'),
        future: svc.myMonth(
          classSection: me.classSection!,
          uid: me.uid,
          month: _month,
        ),
        builder: (BuildContext ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingView();
          }
          final int present = snapshot.data?.present ?? 0;
          final int absent = snapshot.data?.absent ?? 0;
          final Map<String, bool> days =
              snapshot.data?.days ?? const <String, bool>{};
          final int total = present + absent;
          final double pct = total > 0 ? present / total : 1.0;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              // ── Month selector ──
              Row(
                children: <Widget>[
                  IconButton(
                    onPressed: () => _shiftMonth(-1),
                    icon: const Icon(Icons.chevron_left_rounded, size: 30),
                  ),
                  Expanded(
                    child: Text(
                      '$monthName ${_month.year}',
                      textAlign: TextAlign.center,
                      style: NmbTypography.sectionTitle,
                    ),
                  ),
                  IconButton(
                    onPressed: isCurrentMonth ? null : () => _shiftMonth(1),
                    icon: const Icon(Icons.chevron_right_rounded, size: 30),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ── Counts ──
              Row(
                children: <Widget>[
                  Expanded(
                    child: _CountBox(
                      label: tr('Present', 'उपस्थित'),
                      value: '$present',
                      fg: NmbColors.success,
                      bg: NmbColors.successSoft,
                      icon: Icons.check_circle_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _CountBox(
                      label: tr('Absent', 'अनुपस्थित'),
                      value: '$absent',
                      fg: NmbColors.danger,
                      bg: NmbColors.dangerSoft,
                      icon: Icons.cancel_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _CountBox(
                      label: tr('Percent', 'प्रतिशत'),
                      value: total > 0
                          ? '${(pct * 100).toStringAsFixed(0)}%'
                          : '—',
                      fg: pct >= 0.75
                          ? NmbColors.success
                          : NmbColors.warning,
                      bg: pct >= 0.75
                          ? NmbColors.successSoft
                          : NmbColors.warningSoft,
                      icon: Icons.percent_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── CALENDAR ──
              NmbCard(
                child: _AttendanceCalendar(month: _month, days: days),
              ),
              const SizedBox(height: 10),

              // Legend
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  _legend(NmbColors.success, tr('Present', 'उपस्थित')),
                  const SizedBox(width: 14),
                  _legend(NmbColors.danger, tr('Absent', 'अनुपस्थित')),
                  const SizedBox(width: 14),
                  _legend(NmbColors.divider,
                      tr('No record', 'रिकॉर्ड नहीं'),),
                ],
              ),
              const SizedBox(height: 20),

              // ── Leave application shortcut ──
              FilledButton.icon(
                onPressed: () => context.go('/student/home/leave'),
                icon: const Icon(Icons.edit_note_rounded),
                label: Text(tr('Send Leave Application (Online)',
                    'छुट्टी की अर्ज़ी भेजें (ऑनलाइन)',),),
              ),
              const SizedBox(height: 6),
              Text(
                tr(
                  'Absent rehna ho to school ko app se hi application '
                  'bhej do — office jaane ki zaroorat nahi.',
                  'अनुपस्थित रहना हो तो ऐप से ही अर्ज़ी भेज दो — '
                  'ऑफिस जाने की ज़रूरत नहीं।',
                ),
                textAlign: TextAlign.center,
                style: NmbTypography.caption,
              ),
              const SizedBox(height: 24),
            ],
          );
        },
      ),
    );
  }

  Widget _legend(Color c, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: c,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: NmbTypography.caption),
      ],
    );
  }
}

class _CountBox extends StatelessWidget {
  const _CountBox({
    required this.label,
    required this.value,
    required this.fg,
    required this.bg,
    required this.icon,
  });

  final String label;
  final String value;
  final Color fg;
  final Color bg;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, color: fg, size: 20),
          const SizedBox(height: 4),
          Text(value,
              style: NmbTypography.screenTitle.copyWith(color: fg),),
          Text(label, style: NmbTypography.caption),
        ],
      ),
    );
  }
}

/// Month grid: Mon-Sun columns, day cells colored by attendance.
class _AttendanceCalendar extends StatelessWidget {
  const _AttendanceCalendar({required this.month, required this.days});

  final DateTime month;

  /// 'yyyy-MM-dd' → present(true)/absent(false)
  final Map<String, bool> days;

  @override
  Widget build(BuildContext context) {
    final int daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    // Monday = 1 … Sunday = 7
    final int firstWeekday = DateTime(month.year, month.month, 1).weekday;
    final DateTime today = DateTime.now();

    final List<String> headers = appLanguage.value == 'hi'
        ? <String>['सो', 'मं', 'बु', 'गु', 'शु', 'श', 'र']
        : <String>['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    final List<Widget> cells = <Widget>[];
    // Blank cells before day 1
    for (int i = 1; i < firstWeekday; i++) {
      cells.add(const SizedBox());
    }
    for (int day = 1; day <= daysInMonth; day++) {
      final String key =
          '${month.year}-${month.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      final bool? mark = days[key];
      final bool isToday = today.year == month.year &&
          today.month == month.month &&
          today.day == day;
      final bool isFuture =
          DateTime(month.year, month.month, day).isAfter(today);

      Color bg;
      Color fg;
      if (mark == true) {
        bg = NmbColors.success;
        fg = Colors.white;
      } else if (mark == false) {
        bg = NmbColors.danger;
        fg = Colors.white;
      } else {
        bg = isFuture ? Colors.transparent : NmbColors.background;
        fg = isFuture ? NmbColors.textTertiary : NmbColors.textSecondary;
      }

      cells.add(
        Container(
          margin: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: isToday
                ? Border.all(color: NmbColors.primary, width: 2)
                : null,
          ),
          child: Center(
            child: Text(
              '$day',
              style: TextStyle(
                fontSize: 13,
                fontWeight: mark != null || isToday
                    ? FontWeight.w800
                    : FontWeight.w500,
                color: fg,
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            for (final String h in headers)
              Expanded(
                child: Center(
                  child: Text(
                    h,
                    style: NmbTypography.caption.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        GridView.count(
          crossAxisCount: 7,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: cells,
        ),
      ],
    );
  }
}
