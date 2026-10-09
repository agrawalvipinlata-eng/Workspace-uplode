import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/enums.dart';
import '../../../core/theme/nmb_colors.dart';
import '../../../core/theme/nmb_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/nmb_card.dart';
import '../../../core/widgets/responsive_scaffold_body.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/bus.dart';
import '../../../models/trip.dart';
import '../../../providers/data_providers.dart';

/// Trip History: kaunsi bus kab chali, kab khatam hui — poora record.
class AdminTripHistoryScreen extends ConsumerWidget {
  const AdminTripHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Trip>> tripsAsync = ref.watch(recentTripsProvider);
    final List<Bus> buses =
        ref.watch(allBusesProvider).valueOrNull ?? const <Bus>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Trip History')),
      body: tripsAsync.when(
        loading: () => const ListSkeleton(),
        error: (Object e, _) => ErrorView(
          message: 'Couldn\'t load trip history.',
          onRetry: () => ref.invalidate(recentTripsProvider),
        ),
        data: (List<Trip> trips) {
          if (trips.isEmpty) {
            return const EmptyState(
              icon: Icons.history_rounded,
              title: 'No trips yet',
              message:
                  'Trip records will appear here once drivers start trips.',
            );
          }
          return ResponsiveBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (final Trip trip in trips) ...<Widget>[
                  _TripTile(trip: trip, buses: buses),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TripTile extends StatelessWidget {
  const _TripTile({required this.trip, required this.buses});

  final Trip trip;
  final List<Bus> buses;

  @override
  Widget build(BuildContext context) {
    Bus? bus;
    for (final Bus b in buses) {
      if (b.id == trip.busId) bus = b;
    }
    final (String label, Color color, Color bg) = switch (trip.status) {
      TripStatus.active => ('RUNNING', NmbColors.success, NmbColors.successSoft),
      TripStatus.completed => ('COMPLETED', NmbColors.info, NmbColors.infoSoft),
      TripStatus.autoClosed => (
          'AUTO-CLOSED',
          NmbColors.warning,
          NmbColors.warningSoft
        ),
    };

    String duration = '';
    if (trip.startedAt != null && trip.endedAt != null) {
      final int mins = trip.endedAt!.difference(trip.startedAt!).inMinutes;
      duration = ' • $mins min';
    }

    return NmbCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.directions_bus_rounded, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${bus?.busNumber ?? trip.busId} • '
                  '${trip.direction.label}',
                  style: NmbTypography.cardTitle,
                ),
                Text(
                  trip.startedAt != null
                      ? '${Formatters.dateTime(trip.startedAt!)}$duration'
                      : '—',
                  style: NmbTypography.bodySecondary,
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: NmbTypography.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
