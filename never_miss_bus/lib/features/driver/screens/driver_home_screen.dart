import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/constants/enums.dart';
import '../../../core/theme/nmb_colors.dart';
import '../../../core/theme/nmb_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/result.dart';
import '../../../core/widgets/nmb_card.dart';
import '../../../core/widgets/nmb_dialogs.dart';
import '../../../core/widgets/responsive_scaffold_body.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/app_user.dart';
import '../../../models/bus.dart';
import '../../../models/bus_route.dart';
import '../../../models/live_location.dart';
import '../../../models/trip.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';
import '../../../services/auth_service.dart';
import '../../../services/driver_trip_service.dart';

/// Driver home: giant Start/End trip control, GPS + connection status, and
/// assigned bus info. Everything is one-tap; nothing requires interaction
/// while driving.
class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  bool _busy = false;
  bool _gpsServiceOn = false;
  bool _resumedCheckDone = false;

  @override
  void initState() {
    super.initState();
    _refreshGpsStatus();
  }

  Future<void> _refreshGpsStatus() async {
    final bool on = await Geolocator.isLocationServiceEnabled();
    if (mounted) setState(() => _gpsServiceOn = on);
  }

  /// If the app restarted while a trip is still active on the server,
  /// offer to resume publishing GPS.
  Future<void> _maybeResume(Trip trip, AuthSession session) async {
    if (_resumedCheckDone) return;
    _resumedCheckDone = true;
    final DriverTripService svc = ref.read(driverTripServiceProvider);
    if (svc.hasLocalActiveTrip) return;
    if (trip.driverId != session.uid) return;
    await svc.resumePublishing(busId: trip.busId, tripId: trip.id);
  }

  Future<void> _startTrip({
    required AuthSession session,
    required Bus bus,
    required BusRoute? route,
  }) async {
    final TripDirection? direction = await showModalBottomSheet<TripDirection>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text('Start which trip?',
                  style: NmbTypography.sectionTitle,
                  textAlign: TextAlign.center,),
              const SizedBox(height: 18),
              FilledButton.icon(
                icon: const Icon(Icons.wb_sunny_rounded),
                label: const Text('Morning pickup — towards school'),
                onPressed: () =>
                    Navigator.of(ctx).pop(TripDirection.pickup),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                    backgroundColor: NmbColors.accentDark,),
                icon: const Icon(Icons.home_rounded),
                label: const Text('Afternoon drop — towards home'),
                onPressed: () => Navigator.of(ctx).pop(TripDirection.drop),
              ),
            ],
          ),
        ),
      ),
    );
    if (direction == null || !mounted) return;

    setState(() => _busy = true);
    final Result<String> result =
        await ref.read(driverTripServiceProvider).startTrip(
              driverId: session.uid,
              busId: bus.id,
              routeId: route?.id ?? '',
              direction: direction.name,
            );
    if (!mounted) return;
    setState(() => _busy = false);
    result.when(
      ok: (_) => showNmbSnack(
        context,
        'Trip started. Location is now shared with your students.',
        isSuccess: true,
      ),
      err: (AppFailure f) => showNmbSnack(context, f.message, isError: true),
    );
    _refreshGpsStatus();
  }

  Future<void> _endTrip() async {
    final bool confirmed = await showNmbConfirmDialog(
      context,
      title: 'End trip?',
      message: 'Live tracking will stop and students will no longer see '
          'the bus location.',
      confirmLabel: 'End trip',
      destructive: true,
      icon: Icons.stop_circle_outlined,
    );
    if (!confirmed || !mounted) return;

    setState(() => _busy = true);
    final Result<void> result =
        await ref.read(driverTripServiceProvider).endTrip();
    if (!mounted) return;
    setState(() => _busy = false);
    result.when(
      ok: (_) =>
          showNmbSnack(context, 'Trip ended. Thank you!', isSuccess: true),
      err: (AppFailure f) => showNmbSnack(context, f.message, isError: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AuthSession? session = ref.watch(currentSessionProvider);
    final AppUser? me = ref.watch(myProfileProvider).valueOrNull;
    final AsyncValue<Bus?> busAsync = ref.watch(myBusProvider);
    final BusRoute? route = ref.watch(myRouteProvider).valueOrNull;
    final Trip? trip = ref.watch(myBusActiveTripProvider).valueOrNull;
    final LiveLocation? live =
        ref.watch(myBusLiveLocationProvider).valueOrNull;
    final bool online = ref.watch(isOnlineProvider).valueOrNull ?? true;

    if (session == null) return const LoadingView();

    if (trip != null && trip.isActive) {
      _maybeResume(trip, session);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Driver Dashboard')),
      body: busAsync.when(
        loading: () => const LoadingView(),
        error: (Object e, _) => ErrorView(
          message: 'Couldn\'t load your bus. Check your connection.',
          onRetry: () => ref.invalidate(myBusProvider),
        ),
        data: (Bus? bus) {
          if (bus == null) {
            return const EmptyState(
              icon: Icons.no_transfer_rounded,
              title: 'No bus assigned',
              message: 'The school hasn\'t assigned a bus to your account '
                  'yet. Please contact the transport office.',
            );
          }

          final bool onTrip = trip != null && trip.isActive;

          return ResponsiveBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  Formatters.greetingForNow(
                      firstName: me?.firstName ?? 'Driver',),
                  style: NmbTypography.displayTitle,
                ),
                const SizedBox(height: 16),

                // Assigned bus
                NmbCard(
                  color: onTrip ? NmbColors.successSoft : NmbColors.surface,
                  borderColor: onTrip ? NmbColors.success : null,
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: NmbColors.accent,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.directions_bus_rounded,
                            color: Colors.white, size: 30,),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(bus.busNumber,
                                style: NmbTypography.sectionTitle,),
                            Text(bus.plateNumber,
                                style: NmbTypography.bodySecondary,),
                            if (route != null)
                              Text(route.name,
                                  style: NmbTypography.caption,),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: <Widget>[
                          Text(
                            onTrip ? 'TRIP ACTIVE' : 'IDLE',
                            style: NmbTypography.caption.copyWith(
                              color: onTrip
                                  ? NmbColors.success
                                  : NmbColors.textTertiary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (onTrip && trip.startedAt != null)
                            Text(
                              'since '
                              '${Formatters.timeOfDay(trip.startedAt!)}',
                              style: NmbTypography.caption,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // GPS + connection status
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _StatusTile(
                        icon: _gpsServiceOn
                            ? Icons.gps_fixed_rounded
                            : Icons.gps_off_rounded,
                        label: 'GPS',
                        value: _gpsServiceOn ? 'On' : 'Off',
                        ok: _gpsServiceOn,
                        onTap: () async {
                          await Geolocator.openLocationSettings();
                          _refreshGpsStatus();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatusTile(
                        icon: online
                            ? Icons.wifi_rounded
                            : Icons.wifi_off_rounded,
                        label: 'Internet',
                        value: online ? 'Connected' : 'Offline',
                        ok: online,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatusTile(
                        icon: onTrip && live != null
                            ? Icons.podcasts_rounded
                            : Icons.portable_wifi_off_rounded,
                        label: 'Sharing',
                        value: onTrip
                            ? (live != null ? 'Live' : 'Waiting…')
                            : 'Stopped',
                        ok: onTrip && live != null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Current location (while on trip)
                if (onTrip && live != null)
                  NmbCard(
                    child: Row(
                      children: <Widget>[
                        Icon(Icons.my_location_rounded,
                            color: NmbColors.primary,),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Sharing location — '
                                '${live.speedKmh.toStringAsFixed(0)} km/h',
                                style: NmbTypography.cardTitle,
                              ),
                              Text(
                                'Last sent '
                                '${Formatters.relativeTime(live.updatedAt)}',
                                style: NmbTypography.bodySecondary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),

                // THE control: one giant button.
                if (_busy)
                  const Center(
                      child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
                  ),)
                else if (!onTrip)
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(72),
                      backgroundColor: NmbColors.success,
                      textStyle: NmbTypography.button.copyWith(fontSize: 19),
                    ),
                    onPressed: () => _startTrip(
                      session: session,
                      bus: bus,
                      route: route,
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 30),
                    label: const Text('START TRIP'),
                  )
                else
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(72),
                      backgroundColor: NmbColors.danger,
                      textStyle: NmbTypography.button.copyWith(fontSize: 19),
                    ),
                    onPressed: _endTrip,
                    icon: const Icon(Icons.stop_rounded, size: 30),
                    label: const Text('END TRIP'),
                  ),
                const SizedBox(height: 12),
                Text(
                  onTrip
                      ? 'Keep the phone connected to power. Location is '
                          'shared automatically — no further action needed.'
                      : 'Start the trip when you begin the route. Students '
                          'will see the bus live on their map.',
                  style: NmbTypography.caption,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.ok,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool ok;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return NmbCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
      color: ok ? NmbColors.surface : NmbColors.dangerSoft,
      child: Column(
        children: <Widget>[
          Icon(icon,
              color: ok ? NmbColors.success : NmbColors.danger, size: 26,),
          const SizedBox(height: 6),
          Text(label, style: NmbTypography.caption),
          Text(
            value,
            style: NmbTypography.caption.copyWith(
              fontWeight: FontWeight.w800,
              color: ok ? NmbColors.textPrimary : NmbColors.danger,
            ),
          ),
        ],
      ),
    );
  }
}
