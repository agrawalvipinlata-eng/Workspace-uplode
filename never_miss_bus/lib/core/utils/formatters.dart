import 'package:intl/intl.dart';

/// Shared human-friendly formatting. Keeping ETA wording here guarantees the
/// app never presents an estimate as a promise.
abstract final class Formatters {
  static String relativeTime(DateTime time) {
    final Duration diff = DateTime.now().difference(time);
    if (diff.inSeconds < 45) return 'just now';
    if (diff.inMinutes < 1) return 'less than a minute ago';
    if (diff.inMinutes == 1) return '1 minute ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes} minutes ago';
    if (diff.inHours == 1) return '1 hour ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return DateFormat('d MMM, h:mm a').format(time);
  }

  /// Always approximate, never exact: "arriving in approximately 8 minutes".
  static String eta(Duration eta) {
    final int mins = eta.inMinutes;
    if (mins <= 1) return 'Bus arriving in approximately 1 minute';
    return 'Bus arriving in approximately $mins minutes';
  }

  static String etaShort(Duration eta) {
    final int mins = eta.inMinutes.clamp(1, 999);
    return '~$mins min';
  }

  static String timeOfDay(DateTime t) => DateFormat('h:mm a').format(t);

  static String dateTime(DateTime t) =>
      DateFormat('EEE, d MMM • h:mm a').format(t);

  static String greetingForNow({required String firstName}) {
    final int h = DateTime.now().hour;
    final String part = h < 12
        ? 'Good morning'
        : h < 17
            ? 'Good afternoon'
            : 'Good evening';
    return '$part, $firstName!';
  }
}
