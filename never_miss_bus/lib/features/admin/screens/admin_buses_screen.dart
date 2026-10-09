import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/nmb_colors.dart';
import '../../../core/theme/nmb_typography.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/nmb_card.dart';
import '../../../core/widgets/nmb_dialogs.dart';
import '../../../core/widgets/responsive_scaffold_body.dart';
import '../../../core/widgets/state_views.dart';
import '../../../models/app_user.dart';
import '../../../models/bus.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';

/// Manage buses: create/edit fleet. Structure: each bus gets a driver, a
/// route, stops and students (assigned from their own screens).
class AdminBusesScreen extends ConsumerWidget {
  const AdminBusesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Bus>> busesAsync = ref.watch(allBusesProvider);
    final List<AppUser> drivers =
        ref.watch(allDriversProvider).valueOrNull ?? const <AppUser>[];
    final List<AppUser> students =
        ref.watch(allStudentsProvider).valueOrNull ?? const <AppUser>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Buses')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _BusEditorSheet.show(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add bus'),
      ),
      body: busesAsync.when(
        loading: () => const LoadingView(),
        error: (Object e, _) => ErrorView(
          message: 'Couldn\'t load buses.',
          onRetry: () => ref.invalidate(allBusesProvider),
        ),
        data: (List<Bus> buses) {
          if (buses.isEmpty) {
            return const EmptyState(
              icon: Icons.directions_bus_outlined,
              title: 'No buses yet',
              message: 'Create your first bus to start building the '
                  'transport structure.',
            );
          }
          return ResponsiveBody(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (final Bus bus in buses) ...<Widget>[
                  _BusTile(
                    bus: bus,
                    driverName: _driverName(bus, drivers),
                    studentCount: students
                        .where((AppUser s) => s.busId == bus.id)
                        .length,
                  ),
                  const SizedBox(height: 10),
                ],
                const SizedBox(height: 90),
              ],
            ),
          );
        },
      ),
    );
  }

  String _driverName(Bus bus, List<AppUser> drivers) {
    for (final AppUser d in drivers) {
      if (d.busId == bus.id) return d.fullName;
    }
    return 'No driver';
  }
}

class _BusTile extends ConsumerWidget {
  const _BusTile({
    required this.bus,
    required this.driverName,
    required this.studentCount,
  });

  final Bus bus;
  final String driverName;
  final int studentCount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NmbCard(
      onTap: () => _BusEditorSheet.show(context, bus: bus),
      child: Row(
        children: <Widget>[
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bus.isActive
                  ? NmbColors.accentSoft
                  : NmbColors.divider,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.directions_bus_rounded,
              color: bus.isActive
                  ? NmbColors.accentDark
                  : NmbColors.textTertiary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('${bus.busNumber} • ${bus.plateNumber}',
                    style: NmbTypography.cardTitle,),
                Text(
                  '$driverName • $studentCount students • '
                  '${bus.capacity} seats',
                  style: NmbTypography.bodySecondary,
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: NmbColors.textTertiary,),
        ],
      ),
    );
  }
}

class _BusEditorSheet extends ConsumerStatefulWidget {
  const _BusEditorSheet({this.bus});

  final Bus? bus;

  static Future<void> show(BuildContext context, {Bus? bus}) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => _BusEditorSheet(bus: bus),
      );

  @override
  ConsumerState<_BusEditorSheet> createState() => _BusEditorSheetState();
}

class _BusEditorSheetState extends ConsumerState<_BusEditorSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _number =
      TextEditingController(text: widget.bus?.busNumber);
  late final TextEditingController _plate =
      TextEditingController(text: widget.bus?.plateNumber);
  late final TextEditingController _capacity = TextEditingController(
      text: widget.bus == null ? '' : '${widget.bus!.capacity}',);
  late bool _isActive = widget.bus?.isActive ?? true;
  bool _saving = false;

  @override
  void dispose() {
    _number.dispose();
    _plate.dispose();
    _capacity.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final Map<String, dynamic> data = <String, dynamic>{
        'busNumber': _number.text.trim(),
        'plateNumber': _plate.text.trim(),
        'capacity': int.tryParse(_capacity.text.trim()) ?? 0,
        'isActive': _isActive,
      };
      if (widget.bus == null) {
        await ref.read(firestoreServiceProvider).createBus(
              Bus(
                id: '',
                busNumber: data['busNumber'] as String,
                plateNumber: data['plateNumber'] as String,
                capacity: data['capacity'] as int,
                isActive: _isActive,
              ),
            );
      } else {
        await ref
            .read(firestoreServiceProvider)
            .updateBus(widget.bus!.id, data);
      }
      if (!mounted) return;
      final ScaffoldMessengerState m0 = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      m0.showSnackBar(const SnackBar(
        backgroundColor: Color(0xFF1E8E3E),
        content: Text('Bus saved.',
            style: TextStyle(color: Colors.white),),
      ),);
    } catch (_) {
      if (!mounted) return;
      showNmbSnack(context, 'Couldn\'t save the bus. Try again.',
          isError: true,);
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
                  widget.bus == null ? 'Add bus' : 'Edit bus',
                  style: NmbTypography.screenTitle,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _number,
                  decoration: const InputDecoration(
                      hintText: 'Bus number (e.g. Bus 3)',),
                  validator: (String? v) =>
                      Validators.requiredField(v, label: 'Bus number'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _plate,
                  decoration: const InputDecoration(
                      hintText: 'Plate number (e.g. UK07 PA 1234)',),
                  validator: (String? v) =>
                      Validators.requiredField(v, label: 'Plate number'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _capacity,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(hintText: 'Seat capacity'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Bus is active'),
                  value: _isActive,
                  onChanged: (bool v) => setState(() => _isActive = v),
                ),
                const SizedBox(height: 10),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(widget.bus == null ? 'Create bus' : 'Save'),
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
