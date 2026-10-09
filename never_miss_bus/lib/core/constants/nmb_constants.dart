/// App-wide constants and tuning values.
abstract final class NmbConstants {
  static const String appName = 'SRBS International School';
  static const String appTagline = 'Never Miss Bus — live bus tracking';
  static const String schoolName = 'SRBS International School';

  // Live location freshness thresholds
  static const Duration liveThreshold = Duration(seconds: 30);
  static const Duration staleThreshold = Duration(minutes: 3);

  // Driver GPS stream tuning
  static const int locationDistanceFilterMeters = 20;
  static const Duration locationMinInterval = Duration(seconds: 5);

  // ETA guardrails
  static const double etaMinSpeedKmh = 12; // floor so ETA never explodes
  static const double etaMaxReliableDistanceKm = 30;

  // Geofence for "Bus Approaching" (also enforced server-side)
  static const double approachingRadiusMeters = 800;

  // Layout
  static const double screenPadding = 20;
  static const double cardGap = 14;
  static const double maxContentWidth = 560; // keeps tablets/large phones tidy
}

/// School classes & sections — admin dropdowns mein use hote hain
/// (typing ki zaroorat nahi, sirf select karna hai).
abstract final class SchoolClasses {
  static const List<String> classes = <String>[
    'Nursery', 'LKG', 'UKG',
    '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12',
  ];

  static const List<String> sections = <String>['A', 'B', 'C', 'D'];

  /// "7" + "B" → "7-B" ; "Nursery" + "A" → "Nursery-A"
  static String label(String klass, String section) => '$klass-$section';
}

/// Student login IDs: bachhon ko email yaad nahi rakhna padta.
/// Class + Section + Roll Number se ek internal login-email banta hai jo
/// Firebase Auth ke andar use hota hai — user ko kabhi nahi dikhta.
abstract final class StudentLoginId {
  static const String domain = 'student.nmb-srbs.app';

  /// e.g. class "7", section "B", roll "23" → "st.7b.23@student.nmb-srbs.app"
  /// [gen] > 1 hone par ".g2" jaisa suffix lagta hai — password reset par
  /// naya internal account banta hai (purana disable ho jaata hai).
  static String email({
    required String klass,
    required String section,
    required String roll,
    int gen = 1,
  }) {
    final String k = klass.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final String s = section.toLowerCase();
    final String r = roll.trim();
    final String g = gen <= 1 ? '' : '.g$gen';
    return 'st.$k$s.$r$g@$domain';
  }

  /// Login ke waqt kitni generations try karni hain.
  static const int maxGenerations = 6;
}


/// Standard school documents checklist.
abstract final class SchoolDocuments {
  static const List<String> all = <String>[
    'Birth Certificate',
    'Aadhaar Card',
    'Transfer Certificate',
    'Passport Photos',
    'Previous Marksheet',
    'Address Proof',
  ];
}
