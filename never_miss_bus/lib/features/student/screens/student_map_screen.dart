import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_language.dart';
import '../../../core/constants/enums.dart';
import '../../../core/theme/nmb_colors.dart';
import '../../../core/theme/nmb_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../models/bus_route.dart';
import '../../../models/bus_stop.dart';
import '../../../models/geo_point_data.dart';
import '../../../models/live_location.dart';
import '../../../models/trip.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';
import '../../../services/eta_service.dart';
import '../../shared/bus_marker_widget.dart';

/// 🗺️ LIVE MAP 2.0 — premium redesign:
/// • Dark / Light map styles (CartoDB tiles — free, no key)
/// • Bus marker ONLY during an active trip with a fresh fix
/// • Bottom glass card: speed, ETA to my stop, distance, last update
/// • Zoom +/− buttons, follow-bus toggle, themed headers
class StudentMapScreen extends ConsumerStatefulWidget {
  const StudentMapScreen({super.key});

  @override
  ConsumerState<StudentMapScreen> createState() => _StudentMapScreenState();
}

class _StudentMapScreenState extends ConsumerState<StudentMapScreen> {
  final MapController _controller = MapController();
  bool _followBus = true;
  bool _mapReady = false;
  bool _dark = false; // map style: light/dark

  @override
  void initState() {
    super.initState();
    // Saved map style yaad rakho
    SharedPreferences.getInstance().then((SharedPreferences p) {
      if (mounted) {
        setState(() => _dark = p.getBool('nmb_map_dark') ?? false);
      }
    });
  }

  Future<void> _setDark(bool v) async {
    setState(() => _dark = v);
    try {
      final SharedPreferences p = await SharedPreferences.getInstance();
      await p.setBool('nmb_map_dark', v);
    } catch (_) {}
  }

  void _centerOnBus(LiveLocation live) {
    if (!_mapReady) return;
    _controller.move(
      LatLng(live.position.lat, live.position.lng),
      _controller.camera.zoom,
    );
  }

  void _zoom(double delta) {
    if (!_mapReady) return;
    _controller.move(
      _controller.camera.center,
      (_controller.camera.zoom + delta).clamp(3, 19),
    );
  }

  @override
  Widget build(BuildContext context) {
    final LiveLocation? live =
        ref.watch(myBusLiveLocationProvider).valueOrNull;
    final LocationFreshness freshness = ref.watch(myBusFreshnessProvider);
    final Trip? trip = ref.watch(myBusActiveTripProvider).valueOrNull;
    final BusRoute? route = ref.watch(myRouteProvider).valueOrNull;
    final List<BusStop> stops =
        ref.watch(myStopsProvider).valueOrNull ?? const <BusStop>[];
    final BusStop? myStop = ref.watch(myAssignedStopProvider);

    final bool onTrip = trip != null && trip.isActive;
    // 🚌 BUS VISIBLE RULE: trip chal rahi ho AUR fix fresh/stale ho.
    // Trip band = bus map se GAYAB (purani location kabhi nahi dikhti).
    final bool busVisible =
        onTrip && live != null && freshness != LocationFreshness.unavailable;

    // ── ETA + distance to my stop ──
    String? etaText;
    double? distKm;
    if (busVisible && myStop != null) {
      distKm = live.position.distanceTo(myStop.location) / 1000.0;
      if (freshness == LocationFreshness.live) {
        final EtaService etaService = ref.watch(etaServiceProvider);
        etaService.recordSpeed(live.speedKmh);
        final EtaResult eta = etaService.etaToStop(
          live: live,
          targetStop: myStop,
          orderedStops: stops,
        );
        if (eta is EtaAvailable) {
          etaText = Formatters.etaShort(eta.duration);
        }
      }
    }

    // Auto-follow while fresh.
    ref.listen(myBusLiveLocationProvider,
        (Object? _, AsyncValue<LiveLocation?> next) {
      final LiveLocation? l = next.valueOrNull;
      if (l != null && _followBus && onTrip &&
          freshness != LocationFreshness.unavailable) {
        _centerOnBus(l);
      }
    });

    final bool routeMissing = route == null && stops.isEmpty;

    // ── Markers ──
    final List<Marker> markers = <Marker>[];

    if (route != null) {
      markers.add(
        Marker(
          point: LatLng(route.schoolLocation.lat, route.schoolLocation.lng),
          width: 46,
          height: 46,
          child: const _PinMarker(
            icon: Icons.school_rounded,
            color: NmbColors.info,
            tooltip: 'SRBS International School',
          ),
        ),
      );
    }

    for (final BusStop stop in stops) {
      final bool isMine = stop.id == myStop?.id;
      markers.add(
        Marker(
          point: LatLng(stop.location.lat, stop.location.lng),
          width: isMine ? 52 : 40,
          height: isMine ? 52 : 40,
          child: _PinMarker(
            icon: isMine ? Icons.star_rounded : Icons.pin_drop_rounded,
            color: isMine ? NmbColors.accent : const Color(0xFF7B61FF),
            tooltip: isMine
                ? '${stop.name} (${tr('My stop', 'मेरा स्टॉप')})'
                : stop.name,
            large: isMine,
          ),
        ),
      );
    }

    if (busVisible) {
      markers.add(
        Marker(
          point: LatLng(live.position.lat, live.position.lng),
          width: 62,
          height: 62,
          child: Opacity(
            opacity: freshness == LocationFreshness.live ? 1.0 : 0.55,
            child: const BusMarkerWidget(),
          ),
        ),
      );
    }

    // Route polyline
    final List<LatLng> routePoints =
        (route != null && route.recordedPath.length >= 2)
            ? <LatLng>[
                for (final GeoPointData p in route.recordedPath)
                  LatLng(p.lat, p.lng),
              ]
            : <LatLng>[
                for (final BusStop s in stops)
                  LatLng(s.location.lat, s.location.lng),
                if (route != null &&
                    (route.schoolLocation.lat != 0 ||
                        route.schoolLocation.lng != 0))
                  LatLng(route.schoolLocation.lat, route.schoolLocation.lng),
              ];

    const LatLng indiaFallback = LatLng(28.9845, 77.7064);
    final LatLng initialCenter = busVisible
        ? LatLng(live.position.lat, live.position.lng)
        : stops.isNotEmpty
            ? LatLng(stops.first.location.lat, stops.first.location.lng)
            : (route != null &&
                    (route.schoolLocation.lat != 0 ||
                        route.schoolLocation.lng != 0))
                ? LatLng(route.schoolLocation.lat, route.schoolLocation.lng)
                : indiaFallback;

    // 🎨 Map tiles: CartoDB Voyager (light) / Dark Matter (dark) —
    // dono free, no API key, OSM-based, bahut better design than raw OSM.
    // OSM standard tiles — 100% free, NO API key. Dark mode = invert
    // filter (roads/labels readable, night look).
    const String tileUrl =
        'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

    // 🚫 BUS OFF = NO MAP. Jab tak driver trip start nahi karta,
    // student ko sirf ek friendly waiting screen dikhti hai.
    if (!busVisible) {
      return Scaffold(
        appBar: AppBar(title: Text(tr('Live Map', 'लाइव नक्शा'))),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: NmbColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    onTrip
                        ? Icons.location_searching_rounded
                        : Icons.departure_board_rounded,
                    size: 54,
                    color: NmbColors.primary,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  onTrip
                      ? tr('Finding your bus…', 'बस ढूंढी जा रही है…')
                      : tr('Bus is not on a trip yet',
                          'बस अभी सफर पर नहीं है',),
                  textAlign: TextAlign.center,
                  style: NmbTypography.screenTitle,
                ),
                const SizedBox(height: 8),
                Text(
                  onTrip
                      ? tr(
                          'Waiting for the driver\'s live location signal. '
                          'The map will open automatically.',
                          'ड्राइवर के लाइव लोकेशन सिग्नल का इंतज़ार है। '
                          'नक्शा अपने आप खुल जाएगा।',
                        )
                      : tr(
                          'The map opens automatically when the driver '
                          'starts the trip. You will also get an alert.',
                          'ड्राइवर के ट्रिप शुरू करते ही नक्शा अपने आप '
                          'खुल जाएगा। आपको सूचना भी मिलेगी।',
                        ),
                  textAlign: TextAlign.center,
                  style: NmbTypography.bodySecondary,
                ),
                if (myStop != null) ...<Widget>[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10,),
                    decoration: BoxDecoration(
                      color: NmbColors.accentSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(Icons.star_rounded,
                            size: 18, color: NmbColors.accentDark,),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            '${tr('My stop', 'मेरा स्टॉप')}: ${myStop.name}'
                            '${myStop.scheduledTime != null ? ' • ${myStop.scheduledTime}' : ''}',
                            style: NmbTypography.caption.copyWith(
                              fontWeight: FontWeight.w800,
                              color: NmbColors.accentDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(tr('Live Map', 'लाइव नक्शा')),
        actions: <Widget>[
          // ☀️/🌙 MAP STYLE TOGGLE
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Container(
              decoration: BoxDecoration(
                color: _dark ? const Color(0xFF17233B) : Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: NmbColors.divider),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _StyleBtn(
                    icon: Icons.light_mode_rounded,
                    active: !_dark,
                    onTap: () => _setDark(false),
                  ),
                  _StyleBtn(
                    icon: Icons.dark_mode_rounded,
                    active: _dark,
                    darkStyle: true,
                    onTap: () => _setDark(true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 14,
              onMapReady: () => _mapReady = true,
              onPositionChanged: (MapCamera camera, bool hasGesture) {
                if (hasGesture && _followBus) {
                  setState(() => _followBus = false);
                }
              },
            ),
            children: <Widget>[
              if (_dark)
                ColorFiltered(
                  colorFilter: const ColorFilter.matrix(<double>[
                    -0.85, 0, 0, 0, 240,
                    0, -0.85, 0, 0, 240,
                    0, 0, -0.75, 0, 225,
                    0, 0, 0, 1, 0,
                  ]),
                  child: TileLayer(
                    urlTemplate: tileUrl,
                    userAgentPackageName: 'com.srbs.never_miss_bus',
                  ),
                )
              else
                TileLayer(
                  urlTemplate: tileUrl,
                  userAgentPackageName: 'com.srbs.never_miss_bus',
                ),
              if (routePoints.length >= 2)
                PolylineLayer(
                  polylines: <Polyline>[
                    // Outline (white/dark glow) + main line = premium look
                    Polyline(
                      points: routePoints,
                      strokeWidth: 7,
                      color: _dark ? Colors.black54 : Colors.white,
                    ),
                    Polyline(
                      points: routePoints,
                      strokeWidth: 4,
                      color: _dark
                          ? NmbColors.accent.withOpacity(0.9)
                          : NmbColors.primary.withOpacity(0.85),
                    ),
                  ],
                ),
              // 🔵 BUS → MY STOP: blue dashed-style line (bus aa rahi hai!)
              if (busVisible && myStop != null)
                PolylineLayer(
                  polylines: <Polyline>[
                    Polyline(
                      points: <LatLng>[
                        LatLng(live.position.lat, live.position.lng),
                        LatLng(myStop.location.lat, myStop.location.lng),
                      ],
                      strokeWidth: 3.5,
                      color: const Color(0xFF1E88E5),
                      pattern: const StrokePattern.dotted(),
                    ),
                  ],
                ),
              // ETA bubble line ke beech me
              if (busVisible && myStop != null && etaText != null)
                MarkerLayer(
                  markers: <Marker>[
                    Marker(
                      point: LatLng(
                        (live.position.lat + myStop.location.lat) / 2,
                        (live.position.lng + myStop.location.lng) / 2,
                      ),
                      width: 90,
                      height: 34,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4,),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E88E5),
                          borderRadius: BorderRadius.circular(999),
                          boxShadow: const <BoxShadow>[
                            BoxShadow(
                              color: Color(0x40000000),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            '🚌 $etaText',
                            maxLines: 1,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              MarkerLayer(markers: markers),
              Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(
                    '© OpenStreetMap contributors',
                    style: TextStyle(
                      fontSize: 9,
                      color: _dark ? Colors.white54 : NmbColors.textTertiary,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Zoom + follow controls (right side) ──
          Positioned(
            right: 14,
            bottom: busVisible ? 170 : 90,
            child: Column(
              children: <Widget>[
                _MapBtn(
                  icon: Icons.add_rounded,
                  dark: _dark,
                  onTap: () => _zoom(1),
                ),
                const SizedBox(height: 8),
                _MapBtn(
                  icon: Icons.remove_rounded,
                  dark: _dark,
                  onTap: () => _zoom(-1),
                ),
                if (busVisible) ...<Widget>[
                  const SizedBox(height: 8),
                  _MapBtn(
                    icon: _followBus
                        ? Icons.gps_fixed_rounded
                        : Icons.gps_not_fixed_rounded,
                    dark: _dark,
                    highlight: _followBus,
                    onTap: () {
                      setState(() => _followBus = !_followBus);
                      if (_followBus) _centerOnBus(live);
                    },
                  ),
                ],
              ],
            ),
          ),

          // ── Top banner: route missing / trip off / weak signal ──
          if (routeMissing)
            _TopBanner(
              icon: Icons.route_outlined,
              color: NmbColors.info,
              bg: NmbColors.infoSoft,
              text: tr(
                "Route and stops haven't been published yet. The map will "
                'show your bus once the school sets up the route.',
                'रूट और स्टॉप अभी सेट नहीं हुए हैं। स्कूल के रूट सेट करते '
                'ही बस दिखने लगेगी।',
              ),
            )
          else if (!onTrip)
            _TopBanner(
              icon: Icons.no_transfer_rounded,
              color: NmbColors.textTertiary,
              bg: NmbColors.surface,
              text: tr(
                'No trip in progress — the bus appears here only while '
                'the driver is on a trip.',
                'अभी कोई ट्रिप नहीं चल रही — बस केवल ट्रिप के दौरान '
                'यहाँ दिखती है।',
              ),
            )
          else if (freshness == LocationFreshness.stale)
            _TopBanner(
              icon: Icons.history_rounded,
              color: NmbColors.warning,
              bg: NmbColors.warningSoft,
              text:
                  '${tr('Signal weak — last updated', 'सिग्नल कमज़ोर — आखिरी अपडेट')} '
                  '${Formatters.relativeTime(live.updatedAt)}',
            )
          else if (freshness == LocationFreshness.unavailable)
            _TopBanner(
              icon: Icons.location_off_rounded,
              color: NmbColors.textTertiary,
              bg: NmbColors.surface,
              text: tr('Location temporarily unavailable.',
                  'लोकेशन अस्थायी रूप से उपलब्ध नहीं है।',),
            ),

          // ── 🚌 BOTTOM LIVE CARD: speed + ETA + distance ──
          if (busVisible)
            Positioned(
              left: 14,
              right: 14,
              bottom: 14,
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(20),
                color: _dark ? const Color(0xFF1E2A44) : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: freshness == LocationFreshness.live
                                  ? NmbColors.success
                                  : NmbColors.warning,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            freshness == LocationFreshness.live
                                ? tr('LIVE', 'लाइव')
                                : tr('WEAK SIGNAL', 'कमज़ोर सिग्नल'),
                            style: NmbTypography.caption.copyWith(
                              color: freshness == LocationFreshness.live
                                  ? NmbColors.success
                                  : NmbColors.warning,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${tr('Updated', 'अपडेट')} '
                            '${Formatters.relativeTime(live.updatedAt)}',
                            style: NmbTypography.caption.copyWith(
                              color: _dark
                                  ? Colors.white54
                                  : NmbColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: _StatTile(
                              dark: _dark,
                              icon: Icons.speed_rounded,
                              iconColor: NmbColors.primary,
                              value:
                                  '${live.speedKmh.clamp(0, 120).toStringAsFixed(0)} km/h',
                              label: tr('Bus speed', 'बस की गति'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _StatTile(
                              dark: _dark,
                              icon: Icons.flag_rounded,
                              iconColor: NmbColors.success,
                              value: etaText ?? '—',
                              label: tr('Reach time', 'पहुँचने का समय'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _StatTile(
                              dark: _dark,
                              icon: Icons.straighten_rounded,
                              iconColor: NmbColors.accentDark,
                              value: distKm != null
                                  ? (distKm < 1
                                      ? '${(distKm * 1000).toStringAsFixed(0)} m'
                                      : '${distKm.toStringAsFixed(1)} km')
                                  : '—',
                              label: tr('To my stop', 'मेरे स्टॉप तक'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Map style toggle button (light / dark).
class _StyleBtn extends StatelessWidget {
  const _StyleBtn({
    required this.icon,
    required this.active,
    required this.onTap,
    this.darkStyle = false,
  });

  final IconData icon;
  final bool active;
  final bool darkStyle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: active
              ? (darkStyle ? const Color(0xFF17233B) : NmbColors.primary)
              : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 18,
          color: active
              ? (darkStyle ? NmbColors.accent : Colors.white)
              : NmbColors.textTertiary,
        ),
      ),
    );
  }
}

/// Floating circular map control button.
class _MapBtn extends StatelessWidget {
  const _MapBtn({
    required this.icon,
    required this.onTap,
    required this.dark,
    this.highlight = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool dark;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 4,
      shape: const CircleBorder(),
      color: highlight
          ? NmbColors.primary
          : dark
              ? const Color(0xFF1E2A44)
              : Colors.white,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Icon(
            icon,
            size: 22,
            color: highlight
                ? Colors.white
                : dark
                    ? Colors.white70
                    : NmbColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// Stat tile inside the bottom live card.
class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.dark,
  });

  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: dark ? Colors.white.withOpacity(0.06) : NmbColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: NmbTypography.cardTitle.copyWith(
              color: dark ? Colors.white : NmbColors.textPrimary,
              fontSize: 15,
            ),
          ),
          Text(
            label,
            style: NmbTypography.caption.copyWith(
              color: dark ? Colors.white54 : NmbColors.textTertiary,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// Top overlay banner.
class _TopBanner extends StatelessWidget {
  const _TopBanner({
    required this.icon,
    required this.color,
    required this.bg,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final Color bg;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 12,
      left: 16,
      right: 16,
      child: Material(
        borderRadius: BorderRadius.circular(14),
        color: bg,
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: <Widget>[
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: NmbTypography.caption
                      .copyWith(color: NmbColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/// Small circular pin used for school and stop markers.
class _PinMarker extends StatelessWidget {
  const _PinMarker({
    required this.icon,
    required this.color,
    required this.tooltip,
    this.large = false,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      triggerMode: TooltipTriggerMode.tap,
      child: Container(
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 2.5),
          boxShadow: const <BoxShadow>[
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.white, size: large ? 26 : 20),
      ),
    );
  }
}
