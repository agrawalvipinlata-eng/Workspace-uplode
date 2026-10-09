import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/constants/enums.dart';
import '../../../core/theme/app_theme_manager.dart';
import '../../../core/theme/nmb_colors.dart';
import '../../../core/theme/nmb_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/nmb_card.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/app_notification.dart';
import '../../../models/app_user.dart';
import '../../../models/bus.dart';
import '../../../models/bus_stop.dart';
import '../../../models/live_location.dart';
import '../../../models/trip.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';
import '../../../services/eta_service.dart';
import '../../shared/student_avatar.dart';
import '../../../core/constants/app_language.dart';
import '../../../core/constants/home_widgets.dart';
import '../../../core/constants/nmb_constants.dart';
import '../widgets/home_extra_widgets.dart';
import '../widgets/student_drawer.dart';

/// v2.2 Student Home — DYNAMIC widget order (Customize Home ka order
/// sach me follow hota hai), full Hindi/English text, themed colors,
/// school branding header me.
class StudentHomeScreen extends ConsumerWidget {
  const StudentHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AppUser?> profileAsync = ref.watch(myProfileProvider);

    return Scaffold(
      drawer: const StudentDrawer(),
      body: profileAsync.when(
        loading: () => const HomeSkeleton(),
        error: (Object e, _) => ErrorView(
          message: tr(
            "Couldn't load your dashboard. Please check your internet.",
            'डैशबोर्ड लोड नहीं हुआ। कृपया इंटरनेट चेक करें।',
          ),
          onRetry: () => ref.invalidate(myProfileProvider),
        ),
        data: (AppUser? me) {
          if (me == null) {
            return ErrorView(
              title: tr('Account not ready', 'अकाउंट तैयार नहीं है'),
              message: tr(
                'Please contact the school office.',
                'कृपया स्कूल ऑफिस से संपर्क करें।',
              ),
            );
          }
          return _HomeContent(me: me);
        },
      ),
    );
  }
}

class _HomeContent extends ConsumerWidget {
  const _HomeContent({required this.me});

  final AppUser me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Bus? bus = ref.watch(myBusProvider).valueOrNull;
    final Trip? trip = ref.watch(myBusActiveTripProvider).valueOrNull;
    final LiveLocation? live = ref.watch(myBusLiveLocationProvider).valueOrNull;
    final LocationFreshness freshness = ref.watch(myBusFreshnessProvider);
    final BusStop? myStop = ref.watch(myAssignedStopProvider);
    final List<BusStop> stops =
        ref.watch(myStopsProvider).valueOrNull ?? const <BusStop>[];
    final List<AppNotification> inbox =
        ref.watch(inboxProvider).valueOrNull ?? const <AppNotification>[];
    final int unread = ref.watch(unreadCountProvider);
    final bool onTrip = trip != null && trip.isActive;

    // ETA
    String? etaText;
    if (myStop != null && freshness == LocationFreshness.live) {
      final EtaService etaService = ref.watch(etaServiceProvider);
      if (live != null) etaService.recordSpeed(live.speedKmh);
      final EtaResult eta = etaService.etaToStop(
        live: live,
        targetStop: myStop,
        orderedStops: stops,
      );
      if (eta is EtaAvailable) {
        etaText = Formatters.etaShort(eta.duration);
      }
    }

    // Bus progress along stops (kaunsa stop sabse paas hai).
    int progressIndex = -1;
    if (live != null &&
        freshness != LocationFreshness.unavailable &&
        stops.isNotEmpty) {
      double best = double.infinity;
      for (int i = 0; i < stops.length; i++) {
        final double d = live.position.distanceTo(stops[i].location);
        if (d < best) {
          best = d;
          progressIndex = i;
        }
      }
    }

    // ─────────────────────────────────────────────────────────────────
    // SECTION BUILDERS — har home widget ek id se banta hai. Order
    // HomeWidgetsConfig.config (Customize Home) se aata hai — DYNAMIC!
    // ─────────────────────────────────────────────────────────────────
    List<Widget> section(String id) {
      switch (id) {
        case 'busCard':
          if (me.busId == null) {
            return <Widget>[
              NmbCard(
                color: NmbColors.warningSoft,
                child: Row(
                  children: <Widget>[
                    const Icon(
                      Icons.no_transfer_rounded,
                      color: NmbColors.warning,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tr(
                          'No bus has been assigned yet. Please contact the school office.',
                          'अभी कोई बस असाइन नहीं हुई है। कृपया स्कूल ऑफिस से संपर्क करें।',
                        ),
                        style: NmbTypography.bodySecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ];
          }
          return <Widget>[
            NmbCard(
              child: Row(
                children: <Widget>[
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: NmbColors.accentSoft,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.directions_bus_rounded,
                      color: NmbColors.accentDark,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          tr('My Bus', 'मेरी बस'),
                          style: NmbTypography.caption
                              .copyWith(color: NmbColors.primary),
                        ),
                        Text(
                          bus?.busNumber ?? 'Loading…',
                          style: NmbTypography.screenTitle,
                        ),
                        if (bus != null)
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: NmbColors.background,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              bus.plateNumber,
                              style: NmbTypography.caption,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: onTrip
                              ? NmbColors.successSoft
                              : NmbColors.divider,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          onTrip
                              ? tr('ON TRIP', 'सफर में')
                              : tr('IDLE', 'रुकी है'),
                          style: NmbTypography.caption.copyWith(
                            color: onTrip
                                ? NmbColors.success
                                : NmbColors.textTertiary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: freshness == LocationFreshness.live
                                  ? NmbColors.success
                                  : NmbColors.textTertiary,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            freshness == LocationFreshness.live
                                ? tr('Live Tracking', 'लाइव ट्रैकिंग')
                                : freshness == LocationFreshness.stale
                                    ? tr('Signal weak', 'सिग्नल कमज़ोर')
                                    : tr('Not tracking', 'ट्रैकिंग बंद'),
                            style: NmbTypography.caption,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ];

        case 'trackBanner':
          if (me.busId == null) return const <Widget>[];
          return <Widget>[
            Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () => context.go('/student/map'),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: themeGradient(),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 52,
                        height: 52,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.location_on_rounded,
                          color: NmbColors.danger,
                          size: 30,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              tr('Track My Bus', 'मेरी बस ट्रैक करें'),
                              style: NmbTypography.sectionTitle
                                  .copyWith(color: Colors.white),
                            ),
                            Text(
                              tr(
                                'See your bus live on map',
                                'अपनी बस नक्शे पर लाइव देखें',
                              ),
                              style: NmbTypography.bodySecondary
                                  .copyWith(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ];

        case 'quickActions':
          return <Widget>[
            Text(
              tr('Quick Actions', 'क्विक एक्शन'),
              style: NmbTypography.sectionTitle,
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                _QuickAction(
                  icon: Icons.pin_drop_rounded,
                  color: const Color(0xFF7B61FF),
                  bg: const Color(0xFFEFEAFF),
                  label: tr('My Stop', 'मेरा स्टॉप'),
                  onTap: () => context.go('/student/home/stops'),
                ),
                _QuickAction(
                  icon: Icons.schedule_rounded,
                  color: NmbColors.primary,
                  bg: NmbColors.primarySoft,
                  label: tr('ETA & Schedule', 'समय-सारणी'),
                  onTap: () => context.go('/student/home/bus'),
                ),
                _QuickAction(
                  icon: Icons.edit_note_rounded,
                  color: NmbColors.accentDark,
                  bg: NmbColors.accentSoft,
                  label: tr('Leave / Apply', 'छुट्टी अर्ज़ी'),
                  onTap: () => context.go('/student/home/leave'),
                ),
                _QuickAction(
                  icon: Icons.call_rounded,
                  color: NmbColors.success,
                  bg: NmbColors.successSoft,
                  label: tr('Contact School', 'स्कूल से संपर्क'),
                  onTap: () => context.go('/student/profile'),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ];

        case 'checkin':
          if (me.busId == null) return const <Widget>[];
          return <Widget>[
            CheckinWidget(me: me),
            const SizedBox(height: 14),
          ];

        case 'timetable':
          return <Widget>[
            const TimetableWidget(),
            const SizedBox(height: 14),
          ];

        case 'driver':
          if (me.busId == null) return const <Widget>[];
          return <Widget>[
            const DriverCardWidget(),
            const SizedBox(height: 14),
          ];

        case 'fees':
          if (me.feeTotal <= 0) return const <Widget>[];
          return <Widget>[
            NmbCard(
              onTap: () => context.go('/student/profile'),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: me.feeDue > 0
                          ? NmbColors.warningSoft
                          : NmbColors.successSoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      color:
                          me.feeDue > 0 ? NmbColors.warning : NmbColors.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          tr('School Fees', 'स्कूल फीस'),
                          style: NmbTypography.caption,
                        ),
                        Text(
                          me.feeDue > 0
                              ? '${tr('Due', 'बकाया')}: Rs. ${me.feeDue.toStringAsFixed(0)}'
                              : tr('All paid ✓', 'पूरी जमा ✓'),
                          style: NmbTypography.cardTitle.copyWith(
                            color: me.feeDue > 0
                                ? NmbColors.danger
                                : NmbColors.success,
                          ),
                        ),
                        if (me.feeDueDate != null && me.feeDue > 0)
                          Text(
                            '${tr('Last date', 'अंतिम तिथि')}: ${me.feeDueDate}',
                            style: NmbTypography.caption,
                          ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: NmbColors.textTertiary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ];

        case 'nextStop':
          if (me.busId == null || myStop == null) return const <Widget>[];
          return <Widget>[
            NmbCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.star_rounded,
                        color: NmbColors.accent,
                        size: 20,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        tr('My Stop', 'मेरा स्टॉप'),
                        style: NmbTypography.caption.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(myStop.name, style: NmbTypography.sectionTitle),
                  Text(
                    etaText != null
                        ? tr('$etaText to reach', '$etaText में पहुँचेगी')
                        : onTrip
                            ? (myStop.scheduledTime != null
                                ? '${tr('Scheduled', 'निर्धारित समय')}: ${myStop.scheduledTime}'
                                : tr('Bus on the way', 'बस रास्ते में है'))
                            : tr('No trip in progress', 'अभी कोई ट्रिप नहीं'),
                    style: NmbTypography.bodySecondary.copyWith(
                      color: etaText != null
                          ? NmbColors.success
                          : NmbColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (stops.length >= 2) ...<Widget>[
                    const SizedBox(height: 14),
                    _RouteProgress(
                      stops: stops,
                      busAt: progressIndex,
                      myStopId: myStop.id,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text(
                          tr('Start', 'शुरुआत'),
                          style: NmbTypography.caption,
                        ),
                        Text(
                          tr('School', 'स्कूल'),
                          style: NmbTypography.caption,
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
          ];

        case 'notices':
          return <Widget>[
            const NoticesWidget(),
            const SizedBox(height: 14),
          ];

        case 'alerts':
          return <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  tr('Recent Alerts', 'हाल की सूचनाएँ'),
                  style: NmbTypography.sectionTitle,
                ),
                TextButton(
                  onPressed: () => context.go('/student/alerts'),
                  child: Text(tr('View All', 'सभी देखें')),
                ),
              ],
            ),
            if (inbox.isEmpty)
              NmbCard(
                child: Text(
                  tr(
                    'No alerts yet. Bus updates will appear here.',
                    'अभी कोई सूचना नहीं। बस अपडेट यहाँ दिखेंगे।',
                  ),
                  style: NmbTypography.bodySecondary,
                ),
              )
            else
              NmbCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                child: Column(
                  children: <Widget>[
                    for (final AppNotification n in inbox.take(3))
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _alertBg(n.type),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _alertIcon(n.type),
                            color: _alertColor(n.type),
                            size: 20,
                          ),
                        ),
                        title: Text(n.title, style: NmbTypography.cardTitle),
                        subtitle: Text(
                          n.body,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: NmbTypography.bodySecondary,
                        ),
                        trailing: Text(
                          Formatters.timeOfDay(n.receivedAt),
                          style: NmbTypography.caption,
                        ),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 14),
          ];

        default:
          return const <Widget>[];
      }
    }

    // LIVE-RELOAD: Customize Home me save karte hi yahan turant naya
    // order/visibility apply hota hai (ValueListenableBuilder).
    return ValueListenableBuilder<List<String>>(
      valueListenable: HomeWidgetsConfig.config,
      builder: (BuildContext context, List<String> order, Widget? _) {
        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: <Widget>[
            // ── Themed header (school branding ke saath) ──
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  gradient: themeGradient(),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Builder(
                            builder: (BuildContext ctx) => IconButton(
                              onPressed: () => Scaffold.of(ctx).openDrawer(),
                              icon: const Icon(
                                Icons.menu_rounded,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                          // 🏫 School logo + naam header me
                          ClipOval(
                            child: Image.asset(
                              'assets/images/school_logo.png',
                              width: 30,
                              height: 30,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const SizedBox.shrink(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              NmbConstants.schoolName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: NmbTypography.caption.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          // ✏️ Customize home widgets
                          IconButton(
                            tooltip: tr('Customize Home', 'होम कस्टमाइज़'),
                            onPressed: () =>
                                context.go('/student/home/customize'),
                            icon: const Icon(
                              Icons.tune_rounded,
                              color: Colors.white,
                            ),
                          ),
                          // School contacts configured by admin
                          IconButton(
                            tooltip: tr('School contacts', 'स्कूल संपर्क'),
                            onPressed: () => _showContacts(context, ref),
                            icon: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: NmbColors.accentDark,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.contacts_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                          Stack(
                            children: <Widget>[
                              IconButton(
                                onPressed: () => context.go('/student/alerts'),
                                icon: const Icon(
                                  Icons.notifications_outlined,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              if (unread > 0)
                                Positioned(
                                  right: 6,
                                  top: 6,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: NmbColors.danger,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '$unread',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  '${_greetPart()},',
                                  style: NmbTypography.body
                                      .copyWith(color: Colors.white70),
                                ),
                                Text(
                                  '${me.firstName} 👋',
                                  style: NmbTypography.displayTitle
                                      .copyWith(color: Colors.white),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  tr(
                                    'Have a great day at school!',
                                    'स्कूल में आपका दिन शुभ हो!',
                                  ),
                                  style: NmbTypography.bodySecondary
                                      .copyWith(color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                          // Avatar (photo-supported) with online dot
                          StudentAvatar(
                            user: me,
                            radius: 34,
                            showOnlineDot: true,
                            online: onTrip,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              sliver: SliverList(
                delegate: SliverChildListDelegate(<Widget>[
                  // ✨ DYNAMIC ORDER — Customize Home ka order follow hota hai
                  for (final String id in order) ...section(id),
                  const SizedBox(height: 20),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }

  /// Admin-configured school contacts: call or email from one place.
  Future<void> _showContacts(BuildContext context, WidgetRef ref) async {
    final Map<String, dynamic>? school =
        ref.read(schoolConfigProvider).valueOrNull;
    final String? phone = school?['phone'] as String?;
    final String? email = school?['email'] as String?;
    if (!context.mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext sheet) => SafeArea(
        child: Wrap(
          children: <Widget>[
            const ListTile(
              leading: Icon(Icons.contacts_rounded),
              title: Text('School Contacts'),
              subtitle: Text('Contacts added by the administrator'),
            ),
            if (phone != null && phone.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.call_rounded),
                title: Text(phone),
                subtitle: const Text('Call school office'),
                onTap: () => launchUrl(Uri.parse('tel:$phone')),
              ),
            if (email != null && email.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.email_rounded),
                title: Text(email),
                subtitle: const Text('Email school office'),
                onTap: () => launchUrl(Uri.parse('mailto:$email')),
              ),
            if ((phone == null || phone.isEmpty) &&
                (email == null || email.isEmpty))
              const ListTile(title: Text('Admin has not added contacts yet.')),
          ],
        ),
      ),
    );
  }

  String _greetPart() {
    final int h = DateTime.now().hour;
    if (h < 12) return tr('Good Morning', 'सुप्रभात');
    if (h < 17) return tr('Good Afternoon', 'नमस्ते');
    return tr('Good Evening', 'शुभ संध्या');
  }

  IconData _alertIcon(NotificationType t) => switch (t) {
        NotificationType.tripStarted => Icons.play_circle_rounded,
        NotificationType.busApproaching => Icons.near_me_rounded,
        NotificationType.busReachedStop => Icons.pin_drop_rounded,
        NotificationType.busReachedSchool => Icons.school_rounded,
        NotificationType.busDelayed => Icons.schedule_rounded,
        NotificationType.trackingUnavailable => Icons.location_off_rounded,
        NotificationType.announcement => Icons.campaign_rounded,
      };

  Color _alertColor(NotificationType t) => switch (t) {
        NotificationType.tripStarted => NmbColors.success,
        NotificationType.busApproaching => NmbColors.accentDark,
        NotificationType.busDelayed => NmbColors.warning,
        _ => NmbColors.primary,
      };

  Color _alertBg(NotificationType t) => switch (t) {
        NotificationType.tripStarted => NmbColors.successSoft,
        NotificationType.busApproaching => NmbColors.accentSoft,
        NotificationType.busDelayed => NmbColors.warningSoft,
        _ => NmbColors.primarySoft,
      };
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.color,
    required this.bg,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final Color bg;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: <Widget>[
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                textAlign: TextAlign.center,
                style: NmbTypography.caption
                    .copyWith(color: NmbColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bus-on-route progress line: dots for stops, bus emoji at current pos,
/// star dot = my stop, green = covered.
class _RouteProgress extends StatelessWidget {
  const _RouteProgress({
    required this.stops,
    required this.busAt,
    required this.myStopId,
  });

  final List<BusStop> stops;
  final int busAt; // -1 = unknown
  final String myStopId;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: Row(
        children: <Widget>[
          for (int i = 0; i < stops.length; i++) ...<Widget>[
            if (i > 0)
              Expanded(
                child: Container(
                  height: 3,
                  color: busAt >= 0 && i <= busAt
                      ? NmbColors.success
                      : NmbColors.divider,
                ),
              ),
            if (i == busAt)
              const Text('🚌', style: TextStyle(fontSize: 22))
            else
              Container(
                width: stops[i].id == myStopId ? 14 : 10,
                height: stops[i].id == myStopId ? 14 : 10,
                decoration: BoxDecoration(
                  color: stops[i].id == myStopId
                      ? NmbColors.accent
                      : busAt >= 0 && i <= busAt
                          ? NmbColors.success
                          : Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: busAt >= 0 && i <= busAt
                        ? NmbColors.success
                        : NmbColors.divider,
                    width: 2,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
