import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/nmb_colors.dart';
import '../../../core/theme/nmb_typography.dart';
import '../../../core/widgets/nmb_card.dart';
import '../../../core/widgets/responsive_scaffold_body.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/bus_stop.dart';
import '../../../providers/data_providers.dart';

/// Ordered list of the route's stops as a friendly timeline; the student's
/// assigned stop is highlighted with a star.
class StudentStopsScreen extends ConsumerWidget {
  const StudentStopsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<BusStop>> stopsAsync = ref.watch(myStopsProvider);
    final BusStop? myStop = ref.watch(myAssignedStopProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Bus Stops')),
      body: stopsAsync.when(
        loading: () => const LoadingView(),
        error: (Object e, _) => ErrorView(
          message: 'Couldn\'t load the stop list.',
          onRetry: () => ref.invalidate(myStopsProvider),
        ),
        data: (List<BusStop> stops) {
          if (stops.isEmpty) {
            return const EmptyState(
              icon: Icons.pin_drop_outlined,
              title: 'No stops yet',
              message: 'The stop list for your route hasn\'t been '
                  'published yet.',
            );
          }
          return ResponsiveBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (int i = 0; i < stops.length; i++) ...<Widget>[
                  _StopTile(
                    stop: stops[i],
                    index: i,
                    isLast: i == stops.length - 1,
                    isMine: stops[i].id == myStop?.id,
                  ),
                ],
                const SizedBox(height: 16),
                const NmbCard(
                  color: NmbColors.infoSoft,
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.info_outline_rounded,
                          color: NmbColors.info,),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Your pickup stop is set by the school. To change '
                          'it, please contact the school office.',
                          style: NmbTypography.bodySecondary,
                        ),
                      ),
                    ],
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

class _StopTile extends StatelessWidget {
  const _StopTile({
    required this.stop,
    required this.index,
    required this.isLast,
    required this.isMine,
  });

  final BusStop stop;
  final int index;
  final bool isLast;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          // Timeline rail
          SizedBox(
            width: 36,
            child: Column(
              children: <Widget>[
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: isMine ? NmbColors.accent : NmbColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isMine
                        ? const Icon(Icons.star_rounded,
                            size: 16, color: Colors.white,)
                        : Text(
                            '${index + 1}',
                            style: NmbTypography.caption.copyWith(
                              color: NmbColors.primaryDark,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2.4,
                      color: NmbColors.divider,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: NmbCard(
                color: isMine ? NmbColors.accentSoft : NmbColors.surface,
                borderColor: isMine ? NmbColors.accent : null,
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(stop.name, style: NmbTypography.cardTitle),
                          if (isMine)
                            Text(
                              'My assigned stop',
                              style: NmbTypography.caption.copyWith(
                                color: NmbColors.accentDark,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (stop.scheduledTime != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: NmbColors.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: NmbColors.divider),
                        ),
                        child: Text(
                          stop.scheduledTime!,
                          style: NmbTypography.caption.copyWith(
                            color: NmbColors.textSecondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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
