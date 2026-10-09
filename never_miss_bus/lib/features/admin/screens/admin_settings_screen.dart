import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/nmb_typography.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/nmb_card.dart';
import '../../../core/widgets/nmb_dialogs.dart';
import '../../../core/widgets/responsive_scaffold_body.dart';
import '../../../providers/data_providers.dart';

/// School profile settings (contact card shown to students) — admin only.
class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() =>
      _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _lat = TextEditingController();
  final TextEditingController _lng = TextEditingController();
  final TextEditingController _upi = TextEditingController();
  bool _loaded = false;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _lat.dispose();
    _lng.dispose();
    _upi.dispose();
    super.dispose();
  }

  void _fill(Map<String, dynamic>? config) {
    if (_loaded || config == null) return;
    _loaded = true;
    _name.text = (config['name'] as String?) ?? '';
    _phone.text = (config['phone'] as String?) ?? '';
    _email.text = (config['email'] as String?) ?? '';
    _address.text = (config['address'] as String?) ?? '';
    _upi.text = (config['upiId'] as String?) ?? '';
    final Map<String, dynamic>? loc =
        (config['location'] as Map?)?.cast<String, dynamic>();
    if (loc != null) {
      _lat.text = '${loc['lat']}';
      _lng.text = '${loc['lng']}';
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('config')
          .doc('school')
          .set(<String, dynamic>{
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'email': _email.text.trim(),
        'address': _address.text.trim(),
        if (_upi.text.trim().isNotEmpty) 'upiId': _upi.text.trim(),
        if (_lat.text.trim().isNotEmpty && _lng.text.trim().isNotEmpty)
          'location': <String, double>{
            'lat': double.parse(_lat.text.trim()),
            'lng': double.parse(_lng.text.trim()),
          },
      }, SetOptions(merge: true),);
      if (!mounted) return;
      showNmbSnack(context, 'School profile saved.', isSuccess: true);
    } catch (_) {
      if (!mounted) return;
      showNmbSnack(context, 'Couldn\'t save. Try again.', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    _fill(ref.watch(schoolConfigProvider).valueOrNull);

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Settings')),
      body: ResponsiveBody(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text('School profile', style: NmbTypography.sectionTitle),
              const SizedBox(height: 6),
              const Text(
                'Shown to students and drivers as the school contact card.',
                style: NmbTypography.bodySecondary,
              ),
              const SizedBox(height: 14),
              NmbCard(
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      controller: _name,
                      decoration:
                          const InputDecoration(hintText: 'School name'),
                      validator: (String? v) =>
                          Validators.requiredField(v, label: 'School name'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration:
                          const InputDecoration(hintText: 'Office phone'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      decoration:
                          const InputDecoration(hintText: 'Office email'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _address,
                      decoration:
                          const InputDecoration(hintText: 'Address'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _upi,
                      decoration: const InputDecoration(
                        hintText: 'School UPI ID (e.g. school@sbi)',
                        helperText:
                            'Students will pay fees to this UPI ID',
                      ),
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
                            decoration: const InputDecoration(
                                hintText: 'School latitude',),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _lng,
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true, signed: true,),
                            decoration: const InputDecoration(
                                hintText: 'School longitude',),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving…' : 'Save school profile'),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
