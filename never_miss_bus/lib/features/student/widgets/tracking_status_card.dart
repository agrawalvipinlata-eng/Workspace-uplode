import 'package:flutter/material.dart';

import '../../../core/constants/enums.dart';
import '../../../core/theme/nmb_colors.dart';
import '../../../core/theme/nmb_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/nmb_card.dart';
import '../../../core/widgets/status_pill.dart';
import '../../../models/live_location.dart';
import '../../../models/trip.dart';

/// Honest tracking status: LIVE / last-updated / unavailable.
/// Never shows an old fix as live.
class TrackingStatusCard extends StatelessWidget {
  const TrackingStatusCard({
    super.key,
    required this.freshness,
    required this.live,
    required this.trip,
    this.etaText,
  });

  final LocationFreshness freshness;
  final LiveLocation? live;
  final Trip? trip;
  final String? etaText;

  @override
  Widget build(BuildContext context) {
    final (String title, String subtitle, IconData icon, Color color) info =
        switch (freshness) {
      LocationFreshness.live => (
          'Bus is being tracked live',
          etaText ?? 'Follow it on the Live Map',
          Icons.gps_fixed_rounded,
          NmbColors.live,
        ),
      LocationFreshness.stale => (
          'Location temporarily unavailable',
          live != null
              ? 'Last updated ${Formatters.relativeTime(live!.updatedAt)}'
              : 'Waiting for the bus signal…',
          Icons.gps_not_fixed_rounded,
          NmbColors.stale,
        ),
      LocationFreshness.unavailable => (
          trip == null ? 'No trip in progress' : 'Location unavailable',
          trip == null
              ? 'Tracking starts when the driver begins the trip.'
              : 'We\'ll show the bus as soon as the signal returns.',
          Icons.location_off_rounded,
          NmbColors.offline,
        ),
    };

    return NmbCard(
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: info.$4.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(info.$3, color: info.$4),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(info.$1, style: NmbTypography.cardTitle),
                const SizedBox(height: 3),
                Text(info.$2, style: NmbTypography.bodySecondary),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusPill.freshness(freshness),
        ],
      ),
    );
  }
}
