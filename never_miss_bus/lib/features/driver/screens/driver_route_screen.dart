import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/nmb_colors.dart';
import '../../../core/theme/nmb_typography.dart';
import '../../../core/widgets/nmb_card.dart';
import '../../../core/widgets/responsive_scaffold_body.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/bus_route.dart';
import '../../../models/bus_stop.dart';
import '../../../providers/data_providers.dart';

/// Read-only route/stop list for the driver — big text, glanceable.
class DriverRouteScreen extends ConsumerWidget {
  const DriverRouteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final BusRoute? route = ref.watch(myRouteProvider).valueOrNull;
    final AsyncValue<List<BusStop>> stopsAsync = ref.watch(myStopsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Route')),
      body: stopsAsync.when(
        loading: () => const LoadingView(),
        error: (Object e, _) => ErrorView(
          message: 'Couldn\'t load the route.',
          onRetry: () => ref.invalidate(myStopsProvider),
        ),
        data: (List<BusStop> stops) {
          if (stops.isEmpty) {
            return const EmptyState(
              icon: Icons.route_outlined,
              title: 'No route published',
              message: 'The transport office hasn\'t published your route '
                  'yet.',
            );
          }
          return ResponsiveBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                if (route != null) ...<Widget>[
                  Text(route.name, style: NmbTypography.screenTitle),
                  const SizedBox(height: 4),
                  Text(
                    '${stops.length} stops • ${route.direction.label}',
                    style: NmbTypography.bodySecondary,
                  ),
                  const SizedBox(height: 16),
                ],
                for (int i = 0; i < stops.length; i++) ...<Widget>[
                  NmbCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: NmbColors.primarySoft,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: NmbTypography.cardTitle
                                  .copyWith(color: NmbColors.primaryDark),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(stops[i].name,
                              style: NmbTypography.cardTitle,),
                        ),
                        if (stops[i].scheduledTime != null)
                          Text(
                            stops[i].scheduledTime!,
                            style: NmbTypography.cardTitle
                                .copyWith(color: NmbColors.primary),
                          ),
                      ],
                    ),
                  ),
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
