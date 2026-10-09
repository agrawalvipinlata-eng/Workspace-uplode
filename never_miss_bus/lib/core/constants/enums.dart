/// Core enums shared across the app. Names match backend string values.
library;

enum UserRole {
  student,
  driver,
  teacher,
  admin;

  static UserRole? tryParse(String? raw) {
    for (final UserRole r in UserRole.values) {
      if (r.name == raw) return r;
    }
    return null;
  }
}

enum TripStatus {
  active,
  completed,
  autoClosed;

  static TripStatus parse(String raw) => TripStatus.values.firstWhere(
        (TripStatus s) => s.name == raw,
        orElse: () => TripStatus.completed,
      );
}

enum TripDirection {
  pickup,
  drop;

  static TripDirection parse(String raw) => TripDirection.values.firstWhere(
        (TripDirection d) => d.name == raw,
        orElse: () => TripDirection.pickup,
      );

  String get label => this == TripDirection.pickup ? 'Pickup' : 'Drop-off';
}

/// Freshness of the live bus location — drives honest status UI.
enum LocationFreshness {
  /// Updated within the last 30 seconds. Safe to call "LIVE".
  live,

  /// Updated 30s–3min ago. Show "Last updated X ago", never "live".
  stale,

  /// Older than 3 minutes, or no data / no active trip.
  unavailable,
}

enum NotificationType {
  tripStarted,
  busApproaching,
  busReachedStop,
  busReachedSchool,
  busDelayed,
  trackingUnavailable,
  announcement;

  static NotificationType parse(String raw) =>
      NotificationType.values.firstWhere(
        (NotificationType t) => t.name == raw,
        orElse: () => NotificationType.announcement,
      );
}
