import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/nmb_colors.dart';
import '../../../core/theme/nmb_typography.dart';
import '../../../core/widgets/nmb_card.dart';
import '../../../core/widgets/responsive_scaffold_body.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/bus.dart';
import '../../../models/bus_route.dart';
import '../../../models/bus_stop.dart';
import '../../../models/trip.dart';
import '../../../providers/data_providers.dart';

/// Bus & route details for the student's assigned bus. Read-only:
/// students cannot change anything here by design.
class StudentBusDetailsScreen extends ConsumerWidget {
  const StudentBusDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<Bus?> busAsync = ref.watch(myBusProvider);
    final BusRoute? route = ref.watch(myRouteProvider).valueOrNull;
    final List<BusStop> stops =
        ref.watch(myStopsProvider).valueOrNull ?? const <BusStop>[];
    final Trip? trip = ref.watch(myBusActiveTripProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('My Bus & Route')),
      body: busAsync.when(
        loading: () => const LoadingView(),
        error: (Object e, _) => ErrorView(
          message: 'Couldn\'t load bus details.',
          onRetry: () => ref.invalidate(myBusProvider),
        ),
        data: (Bus? bus) {
          if (bus == null) {
            return const EmptyState(
              icon: Icons.no_transfer_rounded,
              title: 'No bus assigned',
              message:
                  'A bus hasn\'t been assigned to your account yet. Please '
                  'contact the school office.',
            );
          }
          return ResponsiveBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                NmbCard(
                  child: Column(
                    children: <Widget>[
                      _InfoRow(
                        icon: Icons.directions_bus_rounded,
                        label: 'Bus number',
                        value: bus.busNumber,
                      ),
                      const Divider(height: 22),
                      _InfoRow(
                        icon: Icons.pin_outlined,
                        label: 'Plate number',
                        value: bus.plateNumber,
                      ),
                      const Divider(height: 22),
                      _InfoRow(
                        icon: Icons.event_seat_outlined,
                        label: 'Capacity',
                        value: '${bus.capacity} seats',
                      ),
                      const Divider(height: 22),
                      _InfoRow(
                        icon: Icons.play_circle_outline_rounded,
                        label: 'Current status',
                        value: trip != null
                            ? 'On a ${trip.direction.label.toLowerCase()} trip'
                            : 'No trip in progress',
                        valueColor: trip != null
                            ? NmbColors.success
                            : NmbColors.textSecondary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (route != null) ...<Widget>[
                  const Text('Route', style: NmbTypography.sectionTitle),
                  const SizedBox(height: 10),
                  NmbCard(
                    child: Column(
                      children: <Widget>[
                        _InfoRow(
                          icon: Icons.route_rounded,
                          label: 'Route name',
                          value: route.name,
                        ),
                        const Divider(height: 22),
                        _InfoRow(
                          icon: Icons.pin_drop_outlined,
                          label: 'Stops on route',
                          value: '${stops.length}',
                        ),
                        const Divider(height: 22),
                        _InfoRow(
                          icon: Icons.swap_vert_rounded,
                          label: 'Direction',
                          value: route.direction.label,
                        ),
                      ],
                    ),
                  ),
                ] else
                  const NmbCard(
                    child: Text(
                      'Route details haven\'t been published yet.',
                      style: NmbTypography.bodySecondary,
                    ),
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 22, color: NmbColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: NmbTypography.bodySecondary),
        ),
        Text(
          value,
          style: NmbTypography.cardTitle.copyWith(
            color: valueColor ?? NmbColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
