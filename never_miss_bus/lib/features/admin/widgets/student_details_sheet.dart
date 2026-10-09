import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/nmb_constants.dart';
import '../../../core/theme/nmb_colors.dart';
import '../../../core/theme/nmb_typography.dart';
import '../../../core/utils/result.dart';
import '../../../core/widgets/nmb_dialogs.dart';
import '../../../models/app_user.dart';
import '../../../providers/app_providers.dart';
import '../../../providers/data_providers.dart';

/// Admin/Teacher sheet: student ke personal details, documents checklist
/// aur fees — sab ek jagah edit hota hai.
class StudentDetailsSheet extends ConsumerStatefulWidget {
  const StudentDetailsSheet({super.key, required this.student});

  final AppUser student;

  static Future<void> show(BuildContext context, AppUser student) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (_) => StudentDetailsSheet(student: student),
      );

  @override
  ConsumerState<StudentDetailsSheet> createState() =>
      _StudentDetailsSheetState();
}

class _StudentDetailsSheetState extends ConsumerState<StudentDetailsSheet> {
  late final TextEditingController _father =
      TextEditingController(text: widget.student.fatherName ?? '');
  late final TextEditingController _mother =
      TextEditingController(text: widget.student.motherName ?? '');
  // DOB: display dd-MM-yyyy (Indian), storage ISO yyyy-MM-dd
  late String _dobIso = widget.student.dob ?? '';
  late final TextEditingController _dob =
      TextEditingController(text: _fmtDob(widget.student.dob));

  static String _fmtDob(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final DateTime? d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return '${d.day.toString().padLeft(2, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-${d.year}';
  }

  late final TextEditingController _address =
      TextEditingController(text: widget.student.address ?? '');
  late final TextEditingController _admission =
      TextEditingController(text: widget.student.admissionNumber ?? '');
  late final TextEditingController _contactEmail =
      TextEditingController(text: widget.student.contactEmail ?? '');
  String? _bloodGroup;
  late Map<String, bool> _docs;

  late final TextEditingController _feeTotal = TextEditingController(
    text: widget.student.feeTotal > 0
        ? widget.student.feeTotal.toStringAsFixed(0)
        : '',
  );
  late final TextEditingController _feePaid = TextEditingController(
    text: widget.student.feePaid > 0
        ? widget.student.feePaid.toStringAsFixed(0)
        : '',
  );
  late final TextEditingController _feeDueDate =
      TextEditingController(text: widget.student.feeDueDate ?? '');

  bool _saving = false;
  String? _newPhotoB64; // naya photo (pick hua toh)

  static const List<String> _bloodGroups = <String>[
    'A+',
    'A-',
    'B+',
    'B-',
    'O+',
    'O-',
    'AB+',
    'AB-',
  ];

  @override
  void initState() {
    super.initState();
    _bloodGroup = widget.student.bloodGroup;
    _docs = <String, bool>{
      for (final String d in SchoolDocuments.all)
        d: widget.student.documents[d] ?? false,
    };
  }

  @override
  void dispose() {
    _father.dispose();
    _mother.dispose();
    _dob.dispose();
    _contactEmail.dispose();
    _address.dispose();
    _admission.dispose();
    _feeTotal.dispose();
    _feePaid.dispose();
    _feeDueDate.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 300,
        maxHeight: 300,
        imageQuality: 60, // ~15-30KB — Firestore-friendly
      );
      if (file == null) return;
      final List<int> bytes = await file.readAsBytes();
      if (bytes.length > 120000) {
        if (mounted) {
          showNmbSnack(
            context,
            'Photo bahut badi hai — chhoti photo choose karo.',
            isError: true,
          );
        }
        return;
      }
      setState(() => _newPhotoB64 = base64Encode(bytes));
      if (mounted) {
        showNmbSnack(
          context,
          'Photo selected ✓ — Save dabao.',
          isSuccess: true,
        );
      }
    } catch (e) {
      if (mounted) {
        showNmbSnack(context, 'Photo pick failed: $e', isError: true);
      }
    }
  }

  Future<void> _pickDob() async {
    final DateTime? d = await showDatePicker(
      context: context,
      initialDate: DateTime(2014),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (d != null) {
      _dobIso =
          '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      _dob.text =
          '${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}';
      setState(() {});
    }
  }

  /// FEES 2.0: payment record — paid amount update + history entry
  /// (PhonePe-style list student ko dikhti hai).
  Future<void> _recordPayment() async {
    if (ref.read(myProfileProvider).valueOrNull?.role.name == 'teacher') return;
    final TextEditingController amt = TextEditingController();
    final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
    final adminSvc = ref.read(adminServiceProvider);
    final bool? go = await showDialog<bool>(
      context: context,
      builder: (BuildContext ctx) => AlertDialog(
        title: const Text('Record payment'),
        content: TextField(
          controller: amt,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(hintText: 'Amount (Rs.)'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Record'),
          ),
        ],
      ),
    );
    if (go != true || !mounted) return;
    final double amount = double.tryParse(amt.text.trim()) ?? 0;
    if (amount <= 0) {
      showNmbSnack(context, 'Enter a valid amount.', isError: true);
      return;
    }
    setState(() => _saving = true);
    final Result<void> r = await adminSvc.recordFeePayment(
      uid: widget.student.uid,
      amount: amount,
    );
    if (mounted) setState(() => _saving = false);
    r.when(
      ok: (_) {
        // Local paid field bhi update dikhaao
        final double cur = double.tryParse(_feePaid.text.trim()) ?? 0;
        _feePaid.text = (cur + amount).toStringAsFixed(0);
        setState(() {});
        messenger.showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF1E8E3E),
            content: Text(
              'Payment recorded ✓',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      },
      err: (AppFailure f) => showNmbSnack(context, f.message, isError: true),
    );
  }

  Future<void> _save() async {
    if (ref.read(myProfileProvider).valueOrNull?.role.name == 'teacher') return;
    setState(() => _saving = true);
    final double total = double.tryParse(_feeTotal.text.trim()) ?? 0;
    final double paid = double.tryParse(_feePaid.text.trim()) ?? 0;
    if (!total.isFinite || !paid.isFinite || total < 0 || paid < 0) {
      setState(() => _saving = false);
      showNmbSnack(context, 'Fees cannot be negative.', isError: true);
      return;
    }
    if (total > 0 && paid > total) {
      setState(() => _saving = false);
      showNmbSnack(
        context,
        'Paid amount cannot exceed total fees.',
        isError: true,
      );
      return;
    }

    final Result<void> result =
        await ref.read(adminServiceProvider).updateUserProfile(
      uid: widget.student.uid,
      data: <String, dynamic>{
        'fatherName': _father.text.trim().isEmpty ? null : _father.text.trim(),
        'motherName': _mother.text.trim().isEmpty ? null : _mother.text.trim(),
        'dob': _dobIso.trim().isEmpty ? null : _dobIso.trim(),
        'bloodGroup': _bloodGroup,
        'address': _address.text.trim().isEmpty ? null : _address.text.trim(),
        'contactEmail': _contactEmail.text.trim().isEmpty
            ? null
            : _contactEmail.text.trim(),
        'admissionNumber':
            _admission.text.trim().isEmpty ? null : _admission.text.trim(),
        'documents': _docs,
        if (_newPhotoB64 != null) 'photoB64': _newPhotoB64,
        'fees': <String, dynamic>{
          'total': total,
          'paid': paid,
          'dueDate':
              _feeDueDate.text.trim().isEmpty ? null : _feeDueDate.text.trim(),
        },
      },
    );
    if (!mounted) return;
    setState(() => _saving = false);
    result.when(
      ok: (_) {
        final ScaffoldMessengerState m0 = ScaffoldMessenger.of(context);
        Navigator.of(context).pop();
        m0.showSnackBar(
          const SnackBar(
            backgroundColor: Color(0xFF1E8E3E),
            content: Text(
              'Student details saved.',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
      },
      err: (AppFailure f) => showNmbSnack(context, f.message, isError: true),
    );
  }

  Future<void> _promote() async {
    if (ref.read(myProfileProvider).valueOrNull?.role.name != 'admin') return;
    String? klass;
    String? section;
    final TextEditingController roll = TextEditingController(
      text: widget.student.rollNumber ?? '',
    );
    final Set<String> remove = <String>{};
    final Map<String, dynamic>? result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext dialogContext) => StatefulBuilder(
        builder: (BuildContext _, StateSetter setDialogState) => AlertDialog(
          title: const Text('Promote student'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                DropdownButtonFormField<String>(
                  value: klass,
                  decoration: const InputDecoration(labelText: 'New class'),
                  items: [
                    for (final String c in SchoolClasses.classes)
                      DropdownMenuItem<String>(value: c, child: Text(c)),
                  ],
                  onChanged: (String? v) => setDialogState(() => klass = v),
                ),
                DropdownButtonFormField<String>(
                  value: section,
                  decoration: const InputDecoration(labelText: 'New section'),
                  items: [
                    for (final String s in SchoolClasses.sections)
                      DropdownMenuItem<String>(value: s, child: Text(s)),
                  ],
                  onChanged: (String? v) => setDialogState(() => section = v),
                ),
                TextField(
                  controller: roll,
                  keyboardType: TextInputType.number,
                  decoration:
                      const InputDecoration(labelText: 'New roll number'),
                ),
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Remove documents not needed after promotion'),
                ),
                for (final String d in SchoolDocuments.all)
                  CheckboxListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(d),
                    value: remove.contains(d),
                    onChanged: (bool? v) => setDialogState(() {
                      if (v == true) {
                        remove.add(d);
                      } else {
                        remove.remove(d);
                      }
                    }),
                  ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: klass == null ||
                      section == null ||
                      roll.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(dialogContext, <String, dynamic>{
                        'classSection': SchoolClasses.label(klass!, section!),
                        'rollNumber': roll.text.trim(),
                        'remove': remove.toList(),
                      }),
              child: const Text('Promote'),
            ),
          ],
        ),
      ),
    );
    roll.dispose();
    if (result == null || !mounted) return;
    setState(() => _saving = true);
    final Result<void> saved = await ref
        .read(adminServiceProvider)
        .promoteStudent(
          uid: widget.student.uid,
          classSection: result['classSection'] as String,
          rollNumber: result['rollNumber'] as String,
          removeDocuments: (result['remove'] as List<dynamic>).cast<String>(),
        );
    if (mounted) setState(() => _saving = false);
    saved.when(
      ok: (_) => showNmbSnack(context, 'Student promoted.', isSuccess: true),
      err: (AppFailure f) => showNmbSnack(context, f.message, isError: true),
    );
  }

  InputDecoration _dec(String hint) => InputDecoration(hintText: hint);

  @override
  Widget build(BuildContext context) {
    final bool teacherReadOnly =
        ref.watch(myProfileProvider).valueOrNull?.role.name == 'teacher';
    final int pending = _docs.values.where((bool v) => !v).length;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              const Text(
                'Details, Documents & Fees',
                style: NmbTypography.screenTitle,
              ),
              Text(
                widget.student.fullName,
                style: NmbTypography.bodySecondary,
              ),
              const SizedBox(height: 16),

              // ── Photo ──
              Center(
                child: Column(
                  children: <Widget>[
                    GestureDetector(
                      onTap: teacherReadOnly ? null : _pickPhoto,
                      child: CircleAvatar(
                        radius: 42,
                        backgroundColor: NmbColors.primarySoft,
                        backgroundImage: _newPhotoB64 != null
                            ? MemoryImage(base64Decode(_newPhotoB64!))
                            : (widget.student.photoB64 != null
                                ? MemoryImage(
                                    base64Decode(widget.student.photoB64!),
                                  )
                                : null),
                        child: (_newPhotoB64 == null &&
                                widget.student.photoB64 == null)
                            ? Icon(
                                Icons.add_a_photo_rounded,
                                color: NmbColors.primary,
                                size: 30,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextButton.icon(
                      onPressed: teacherReadOnly ? null : _pickPhoto,
                      icon: const Icon(
                        Icons.photo_library_rounded,
                        size: 18,
                      ),
                      label: Text(
                        widget.student.photoB64 != null || _newPhotoB64 != null
                            ? 'Change photo'
                            : 'Add student photo',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // ── Personal details ──
              const Text(
                'Personal Details',
                style: NmbTypography.sectionTitle,
              ),
              const SizedBox(height: 10),
              TextField(
                readOnly: teacherReadOnly,
                controller: _father,
                decoration: _dec("Father's name"),
              ),
              const SizedBox(height: 10),
              TextField(
                readOnly: teacherReadOnly,
                controller: _mother,
                decoration: _dec("Mother's name"),
              ),
              const SizedBox(height: 10),
              TextField(
                readOnly: teacherReadOnly,
                controller: _contactEmail,
                keyboardType: TextInputType.emailAddress,
                decoration: _dec('Email (parent/student — optional)'),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      readOnly: true,
                      controller: _dob,
                      onTap: teacherReadOnly ? null : _pickDob,
                      decoration: _dec('Date of birth').copyWith(
                        suffixIcon: const Icon(Icons.calendar_month_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _bloodGroup,
                      decoration: _dec('Blood group'),
                      items: <DropdownMenuItem<String>>[
                        for (final String b in _bloodGroups)
                          DropdownMenuItem<String>(
                            value: b,
                            child: Text(b),
                          ),
                      ],
                      onChanged: teacherReadOnly
                          ? null
                          : (String? v) => setState(() => _bloodGroup = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                readOnly: teacherReadOnly,
                controller: _admission,
                decoration: _dec('Admission number'),
              ),
              const SizedBox(height: 10),
              TextField(
                readOnly: teacherReadOnly,
                controller: _address,
                maxLines: 2,
                decoration: _dec('Home address'),
              ),
              const SizedBox(height: 18),

              // ── Documents checklist ──
              Row(
                children: <Widget>[
                  const Text(
                    'Documents',
                    style: NmbTypography.sectionTitle,
                  ),
                  const Spacer(),
                  if (pending > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: NmbColors.warningSoft,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$pending pending',
                        style: NmbTypography.caption.copyWith(
                          color: NmbColors.warning,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              for (final String d in SchoolDocuments.all)
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(d, style: NmbTypography.body),
                  subtitle: Text(
                    _docs[d]! ? 'Submitted ✓' : 'Pending — not submitted',
                    style: NmbTypography.caption.copyWith(
                      color: _docs[d]! ? NmbColors.success : NmbColors.warning,
                    ),
                  ),
                  value: _docs[d],
                  onChanged: teacherReadOnly
                      ? null
                      : (bool? v) => setState(() => _docs[d] = v ?? false),
                ),
              if (!teacherReadOnly &&
                  ref.watch(myProfileProvider).valueOrNull?.role.name ==
                      'admin')
                OutlinedButton.icon(
                  onPressed: _saving ? null : _promote,
                  icon: const Icon(Icons.upgrade_rounded),
                  label: const Text('Promote / change class and roll'),
                ),
              const SizedBox(height: 12),

              // ── Fees ──
              const Text('Fees', style: NmbTypography.sectionTitle),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  Expanded(
                    child: TextField(
                      readOnly: teacherReadOnly,
                      controller: _feeTotal,
                      keyboardType: TextInputType.number,
                      decoration: _dec('Total fees (Rs.)'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      readOnly: teacherReadOnly,
                      controller: _feePaid,
                      keyboardType: TextInputType.number,
                      decoration: _dec('Paid (Rs.)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                readOnly: teacherReadOnly,
                controller: _feeDueDate,
                decoration: _dec('Due date (e.g. 2026-09-15)'),
              ),
              const SizedBox(height: 10),
              if (!teacherReadOnly)
                OutlinedButton.icon(
                  onPressed: _saving ? null : _recordPayment,
                  icon: const Icon(Icons.receipt_long_rounded),
                  label: const Text('Record a payment (adds to history)'),
                ),
              const SizedBox(height: 18),

              if (!teacherReadOnly)
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Saving…' : 'Save all details'),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}
