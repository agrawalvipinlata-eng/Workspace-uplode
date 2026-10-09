import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/constants/enums.dart';
import '../../../core/theme/nmb_colors.dart';
import '../../../core/theme/nmb_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/nmb_card.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../models/bus.dart';
import '../../../models/bus_stop.dart';
import '../../../models/live_location.dart';
import '../../../models/trip.dart';
import '../../../providers/data_providers.dart';
import '../../shared/bus_marker_widget.dart';

/// Live fleet monitoring on OpenStreetMap: all active buses on one map +
/// trip status list. Admin-only (route fence + backend rules).
class AdminMonitoringScreen extends ConsumerStatefulWidget {
  const AdminMonitoringScreen({super.key});

  @override
  ConsumerState<AdminMonitoringScreen> createState() =>
      _AdminMonitoringScreenState();
}

class _AdminMonitoringScreenState
    extends ConsumerState<AdminMonitoringScreen> {
  final MapController _controller = MapController();
  bool _mapReady = false;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Trip>> tripsAsync = ref.watch(activeTripsProvider);
    final List<Bus> buses =
        ref.watch(allBusesProvider).valueOrNull ?? const <Bus>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Live Monitoring')),
      body: tripsAsync.when(
        loading: () => const LoadingView(),
        error: (Object e, _) => ErrorView(
          message: 'Couldn\'t load active trips.',
          onRetry: () => ref.invalidate(activeTripsProvider),
        ),
        data: (List<Trip> trips) {
          if (trips.isEmpty) {
            return const EmptyState(
              icon: Icons.radar_rounded,
              title: 'No active trips',
              message: 'When drivers start trips, their buses appear here '
                  'in real time.',
            );
          }

          final List<Marker> markers = <Marker>[];
          LatLng? firstPos;
          for (final Trip trip in trips) {
            final LiveLocation? live =
                ref.watch(busLiveLocationProvider(trip.busId)).valueOrNull;
            if (live == null) continue;
            final LatLng pos = LatLng(live.position.lat, live.position.lng);
            firstPos ??= pos;
            Bus? bus;
            for (final Bus b in buses) {
              if (b.id == trip.busId) bus = b;
            }
            markers.add(
              Marker(
                point: pos,
                width: 60,
                height: 74,
                child: Column(
                  children: <Widget>[
                    const BusMarkerWidget(size: 48),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1,),
                      decoration: BoxDecoration(
                        color: NmbColors.primaryDark,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        bus?.busNumber ?? trip.busId,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return Column(
            children: <Widget>[
              Expanded(
                flex: 3,
                child: FlutterMap(
                  mapController: _controller,
                  options: MapOptions(
                    // Default center: Meerut, India (jab tak koi bus live nahi)
                    initialCenter:
                        firstPos ?? const LatLng(28.9845, 77.7064),
                    initialZoom: 12,
                    onMapReady: () => _mapReady = true,
                  ),
                  children: <Widget>[
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.srbs.never_miss_bus',
                    ),
                    MarkerLayer(markers: markers),
                    const Align(
                      alignment: Alignment.bottomLeft,
                      child: Padding(
                        padding: EdgeInsets.all(4),
                        child: Text(
                          '© OpenStreetMap contributors',
                          style: TextStyle(
                            fontSize: 10,
                            color: NmbColors.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: <Widget>[
                    for (final Trip trip in trips) ...<Widget>[
                      _TripStatusTile(
                        trip: trip,
                        buses: buses,
                        onFocus: (LatLng pos) {
                          if (_mapReady) _controller.move(pos, 15);
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _TripStatusTile extends ConsumerWidget {
  const _TripStatusTile({
    required this.trip,
    required this.buses,
    required this.onFocus,
  });

  final Trip trip;
  final List<Bus> buses;
  final void Function(LatLng) onFocus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LiveLocation? live =
        ref.watch(busLiveLocationProvider(trip.busId)).valueOrNull;
    ref.watch(freshnessTickProvider);
    final LocationFreshness freshness =
        live?.freshness() ?? LocationFreshness.unavailable;

    Bus? bus;
    for (final Bus b in buses) {
      if (b.id == trip.busId) bus = b;
    }

    // 📍 BUS KAHAN HAI: sabse paas wala stop nikalo
    String? nearStop;
    if (live != null) {
      final List<BusStop> stops =
          ref.watch(stopsOfBusProvider(trip.busId)).valueOrNull ??
              const <BusStop>[];
      double best = double.infinity;
      for (final BusStop st in stops) {
        final double d = live.position.distanceTo(st.location);
        if (d < best) {
          best = d;
          nearStop = best < 400
              ? 'At ${st.name}'
              : 'Near ${st.name} (${(best / 1000).toStringAsFixed(1)} km)';
        }
      }
    }

    return NmbCard(
      onTap: live == null
          ? null
          : () => onFocus(LatLng(live.position.lat, live.position.lng)),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: <Widget>[
          Icon(Icons.directions_bus_rounded, color: NmbColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(bus?.busNumber ?? trip.busId,
                    style: NmbTypography.cardTitle,),
                Text(
                  live == null
                      ? '${trip.direction.label} • waiting for GPS…'
                      : '${trip.direction.label} • '
                          '${live.speedKmh.toStringAsFixed(0)} km/h • '
                          '${Formatters.relativeTime(live.updatedAt)}',
                  style: NmbTypography.bodySecondary,
                ),
                if (nearStop != null)
                  Text(
                    '📍 $nearStop',
                    style: NmbTypography.caption.copyWith(
                      color: NmbColors.success,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          StatusPill.freshness(freshness),
        ],
      ),
    );
  }
}
