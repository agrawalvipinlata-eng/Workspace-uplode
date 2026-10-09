import '../core/constants/enums.dart';

/// A user profile document (`users/{uid}`).
///
/// NOTE: [role] and [busId] here are display mirrors. The *authoritative*
/// values live in Firebase Auth custom claims and are enforced by security
/// rules — the app never grants access based on this document alone.
class AppUser {
  const AppUser({
    required this.uid,
    required this.role,
    required this.fullName,
    required this.email,
    this.phone,
    this.busId,
    this.stopId,
    this.classSection,
    this.rollNumber,
    this.isActive = true,
    this.createdAt,
    this.activeDevice,
    this.fatherName,
    this.motherName,
    this.fatherPhotoB64,
    this.motherPhotoB64,
    this.dob,
    this.bloodGroup,
    this.address,
    this.admissionNumber,
    this.contactEmail,
    this.documents = const <String, bool>{},
    this.fees,
    this.photoB64,
    Map<String, dynamic>? settings,
  }) : _settings = settings;

  final String uid;
  final UserRole role;
  final String fullName;
  final String email;
  final String? phone;
  final String? busId;
  final String? stopId;
  final String? classSection;
  final String? rollNumber;
  final bool isActive;
  final DateTime? createdAt;

  /// Single-device login: {id, name, at(ms)} from settings.activeDevice.
  final Map<String, dynamic>? activeDevice;

  /// Raw settings map (mustChangePassword, language, prefs…).
  final Map<String, dynamic>? _settings;

  // ── Extended student profile (school records) ──
  final String? fatherName;
  final String? motherName;
  final String? fatherPhotoB64;
  final String? motherPhotoB64;
  final String? dob; // ISO date string e.g. 2014-05-21
  final String? bloodGroup;
  final String? address;
  final String? admissionNumber;

  /// Optional real contact email (student/parent) — login email alag hai.
  final String? contactEmail;

  /// Document checklist: name → submitted?
  final Map<String, bool> documents;

  /// Fees: {total: num, paid: num, dueDate: 'yyyy-mm-dd'}
  final Map<String, dynamic>? fees;

  /// Compressed profile photo (JPEG base64, ~25KB) — free-plan friendly.
  final String? photoB64;

  /// Age in years from dob (ISO yyyy-mm-dd), null if dob missing/invalid.
  int? get ageYears {
    if (dob == null) return null;
    final DateTime? d = DateTime.tryParse(dob!);
    if (d == null) return null;
    final DateTime now = DateTime.now();
    int a = now.year - d.year;
    if (now.month < d.month || (now.month == d.month && now.day < d.day)) a--;
    return (a >= 0 && a < 100) ? a : null;
  }

  double get feeTotal => ((fees?['total'] as num?) ?? 0).toDouble();
  double get feePaid => ((fees?['paid'] as num?) ?? 0).toDouble();
  double get feeDue => (feeTotal - feePaid).clamp(0, double.infinity);
  String? get feeDueDate => fees?['dueDate'] as String?;

  /// First-login forced password change (OTP ka free alternate).
  bool get mustChangePassword =>
      (activeDeviceSettings?['mustChangePassword'] as bool?) ?? false;

  Map<String, dynamic>? get activeDeviceSettings => _settings;

  /// Settings map se string value (e.g. parentPhoneSelf, addressSelf).
  String? settingsMapValue(String key) {
    final Object? v = _settings?[key];
    if (v is String && v.trim().isNotEmpty) return v;
    return null;
  }

  /// DOB FIX: Indian style dd-MM-yyyy me dikhao (store ISO me hi hota hai).
  String? get dobFormatted {
    if (dob == null) return null;
    final DateTime? d = DateTime.tryParse(dob!);
    if (d == null) return dob; // jaisa hai waisa
    return '${d.day.toString().padLeft(2, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-${d.year}';
  }

  List<String> get pendingDocuments => documents.entries
      .where((MapEntry<String, bool> e) => !e.value)
      .map((MapEntry<String, bool> e) => e.key)
      .toList();

  String get firstName =>
      fullName.trim().isEmpty ? 'there' : fullName.trim().split(' ').first;

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) => AppUser(
        uid: uid,
        role: UserRole.tryParse(map['role'] as String?) ?? UserRole.student,
        fullName: (map['fullName'] as String?) ?? '',
        email: (map['email'] as String?) ?? '',
        phone: map['phone'] as String?,
        busId: map['busId'] as String?,
        stopId: map['stopId'] as String?,
        classSection: map['classSection'] as String?,
        rollNumber: map['rollNumber'] as String?,
        isActive: (map['isActive'] as bool?) ?? true,
        createdAt: _toDate(map['createdAt']),
        activeDevice: ((map['settings'] as Map?)?['activeDevice'] as Map?)
            ?.cast<String, dynamic>(),
        fatherName: map['fatherName'] as String?,
        motherName: map['motherName'] as String?,
        fatherPhotoB64: map['fatherPhotoB64'] as String?,
        motherPhotoB64: map['motherPhotoB64'] as String?,
        dob: map['dob'] as String?,
        bloodGroup: map['bloodGroup'] as String?,
        address: map['address'] as String?,
        admissionNumber: map['admissionNumber'] as String?,
        contactEmail: map['contactEmail'] as String?,
        documents: Map<String, bool>.from(
          (map['documents'] as Map?)?.map(
                (Object? k, Object? v) =>
                    MapEntry<String, bool>('$k', v == true),
              ) ??
              <String, bool>{},
        ),
        fees: (map['fees'] as Map?)?.cast<String, dynamic>(),
        photoB64: map['photoB64'] as String?,
        settings: (map['settings'] as Map?)?.cast<String, dynamic>(),
      );

  Map<String, dynamic> toMap() => <String, dynamic>{
        'role': role.name,
        'fullName': fullName,
        'email': email,
        if (phone != null) 'phone': phone,
        if (busId != null) 'busId': busId,
        if (stopId != null) 'stopId': stopId,
        if (classSection != null) 'classSection': classSection,
        if (rollNumber != null) 'rollNumber': rollNumber,
        'isActive': isActive,
      };

  static DateTime? _toDate(Object? v) {
    if (v == null) return null;
    // cloud_firestore Timestamp exposes toDate(); avoid importing it here.
    try {
      return (v as dynamic).toDate() as DateTime?;
    } catch (_) {
      return null;
    }
  }
}
