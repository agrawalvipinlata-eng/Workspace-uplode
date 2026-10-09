import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/nmb_colors.dart';
import '../../../core/theme/nmb_typography.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/nmb_card.dart';
import '../../../core/widgets/nmb_dialogs.dart';
import '../../../core/widgets/responsive_scaffold_body.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/bus.dart';
import '../../../models/bus_stop.dart';
import '../../../models/geo_point_data.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';

/// Routes & Stops manager: pick a bus, then build its ordered stop list.
/// School → Stop 1 → Stop 2 → … exactly as the transport structure defines.
class AdminRoutesStopsScreen extends ConsumerStatefulWidget {
  const AdminRoutesStopsScreen({super.key});

  @override
  ConsumerState<AdminRoutesStopsScreen> createState() =>
      _AdminRoutesStopsScreenState();
}

class _AdminRoutesStopsScreenState
    extends ConsumerState<AdminRoutesStopsScreen> {
  String? _busId;

  /// Stop ko list mein upar/neeche karo aur naya order save karo.
  Future<void> _moveStop(List<BusStop> stops, int from, int to) async {
    final List<String> ids =
        stops.map((BusStop s) => s.id).toList(growable: true);
    final String moved = ids.removeAt(from);
    ids.insert(to, moved);
    try {
      await ref.read(firestoreServiceProvider).reorderStops(ids);
    } catch (_) {
      if (mounted) {
        showNmbSnack(context, 'Couldn\'t save the order, try again.',
            isError: true,);
      }
    }
  }

  Future<void> _deleteStop(BusStop stop) async {
    final bool ok = await showNmbConfirmDialog(
      context,
      title: 'Delete stop?',
      message:
          '"${stop.name}" will be removed from the route. Students assigned '
          'to this stop will need a new stop.',
      confirmLabel: 'Delete',
      destructive: true,
      icon: Icons.delete_outline_rounded,
    );
    if (!ok || !mounted) return;
    try {
      await ref.read(firestoreServiceProvider).deactivateStop(stop.id);
      if (mounted) {
        showNmbSnack(context, 'Stop deleted.', isSuccess: true);
      }
    } catch (_) {
      if (mounted) {
        showNmbSnack(context, 'Couldn\'t delete the stop, try again.',
            isError: true,);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Bus> buses =
        ref.watch(allBusesProvider).valueOrNull ?? const <Bus>[];
    final List<BusStop> stops = _busId == null
        ? const <BusStop>[]
        : ref.watch(stopsOfBusProvider(_busId!)).valueOrNull ??
            const <BusStop>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Routes & Stops')),
      floatingActionButton: _busId == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _StopEditorSheet.show(
                context,
                busId: _busId!,
                nextOrder: stops.length + 1,
              ),
              icon: const Icon(Icons.add_location_alt_rounded),
              label: const Text('Add stop'),
            ),
      body: ResponsiveBody(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            DropdownButtonFormField<String>(
              value: _busId,
              decoration: const InputDecoration(
                hintText: 'Select a bus to manage its route',
                prefixIcon: Icon(Icons.directions_bus_rounded),
              ),
              items: <DropdownMenuItem<String>>[
                for (final Bus b in buses)
                  DropdownMenuItem<String>(
                    value: b.id,
                    child: Text('${b.busNumber} — ${b.plateNumber}'),
                  ),
              ],
              onChanged: (String? v) => setState(() => _busId = v),
            ),
            const SizedBox(height: 16),
            if (_busId == null)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: EmptyState(
                  icon: Icons.route_outlined,
                  title: 'Pick a bus',
                  message:
                      'Choose a bus above to view and edit its route and '
                      'stops in order.',
                ),
              )
            else if (stops.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 40),
                child: EmptyState(
                  icon: Icons.add_location_alt_outlined,
                  title: 'No stops yet',
                  message:
                      'Add the first stop for this route. Stops appear to '
                      'students in the order you create them.',
                ),
              )
            else ...<Widget>[
              const Text('Route stops (in order)',
                  style: NmbTypography.sectionTitle,),
              const SizedBox(height: 10),
              for (int i = 0; i < stops.length; i++) ...<Widget>[
                NmbCard(
                  onTap: () => _StopEditorSheet.show(
                    context,
                    busId: _busId!,
                    stop: stops[i],
                    nextOrder: stops[i].order,
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: NmbColors.primarySoft,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: NmbTypography.caption.copyWith(
                              color: NmbColors.primaryDark,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(stops[i].name,
                                style: NmbTypography.cardTitle,),
                            Text(
                              '${stops[i].location.lat.toStringAsFixed(5)}, '
                              '${stops[i].location.lng.toStringAsFixed(5)}'
                              '${stops[i].scheduledTime != null ? ' • ${stops[i].scheduledTime}' : ''}',
                              style: NmbTypography.caption,
                            ),
                          ],
                        ),
                      ),
                      // Upar / neeche reorder
                      if (i > 0)
                        IconButton(
                          tooltip: 'Move up',
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.arrow_upward_rounded,
                              size: 20, color: NmbColors.textSecondary,),
                          onPressed: () => _moveStop(stops, i, i - 1),
                        ),
                      if (i < stops.length - 1)
                        IconButton(
                          tooltip: 'Move down',
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(Icons.arrow_downward_rounded,
                              size: 20, color: NmbColors.textSecondary,),
                          onPressed: () => _moveStop(stops, i, i + 1),
                        ),
                      IconButton(
                        tooltip: 'Delete stop',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.delete_outline_rounded,
                            size: 20, color: NmbColors.danger,),
                        onPressed: () => _deleteStop(stops[i]),
                      ),
                      const Icon(Icons.edit_outlined,
                          size: 18, color: NmbColors.textTertiary,),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ],
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }
}

class _StopEditorSheet extends ConsumerStatefulWidget {
  const _StopEditorSheet({
    required this.busId,
    required this.nextOrder,
    this.stop,
  });

  final String busId;
  final int nextOrder;
  final BusStop? stop;

  static Future<void> show(
    BuildContext context, {
    required String busId,
    required int nextOrder,
    BusStop? stop,
  }) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => _StopEditorSheet(
          busId: busId,
          nextOrder: nextOrder,
          stop: stop,
        ),
      );

  @override
  ConsumerState<_StopEditorSheet> createState() => _StopEditorSheetState();
}

class _StopEditorSheetState extends ConsumerState<_StopEditorSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _name =
      TextEditingController(text: widget.stop?.name);
  late final TextEditingController _lat = TextEditingController(
      text: widget.stop == null ? '' : '${widget.stop!.location.lat}',);
  late final TextEditingController _lng = TextEditingController(
      text: widget.stop == null ? '' : '${widget.stop!.location.lng}',);
  late final TextEditingController _time =
      TextEditingController(text: widget.stop?.scheduledTime);
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _lat.dispose();
    _lng.dispose();
    _time.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final BusStop stop = BusStop(
        id: widget.stop?.id ?? '',
        name: _name.text.trim(),
        routeId: widget.stop?.routeId ?? '',
        busId: widget.busId,
        location: GeoPointData(
          lat: double.parse(_lat.text.trim()),
          lng: double.parse(_lng.text.trim()),
        ),
        order: widget.nextOrder,
        scheduledTime:
            _time.text.trim().isEmpty ? null : _time.text.trim(),
      );
      if (widget.stop == null) {
        await ref.read(firestoreServiceProvider).createStop(stop);
      } else {
        await ref
            .read(firestoreServiceProvider)
            .updateStop(widget.stop!.id, stop.toMap());
      }
      if (!mounted) return;
      final ScaffoldMessengerState m0 = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      m0.showSnackBar(const SnackBar(
        backgroundColor: Color(0xFF1E8E3E),
        content: Text('Stop saved.',
            style: TextStyle(color: Colors.white),),
      ),);
    } catch (_) {
      if (!mounted) return;
      showNmbSnack(context, 'Couldn\'t save the stop.', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  widget.stop == null ? 'Add stop' : 'Edit stop',
                  style: NmbTypography.screenTitle,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                      hintText: 'Stop name (e.g. Rajpur Road Gate 2)',),
                  validator: (String? v) =>
                      Validators.requiredField(v, label: 'Stop name'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: TextFormField(
                        controller: _lat,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                                decimal: true, signed: true,),
                        decoration:
                            const InputDecoration(hintText: 'Latitude'),
                        validator: Validators.latitude,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _lng,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                                decimal: true, signed: true,),
                        decoration:
                            const InputDecoration(hintText: 'Longitude'),
                        validator: Validators.longitude,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _time,
                  decoration: const InputDecoration(
                      hintText: 'Scheduled time (e.g. 07:15) — optional',),
                ),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child:
                      Text(widget.stop == null ? 'Create stop' : 'Save'),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
