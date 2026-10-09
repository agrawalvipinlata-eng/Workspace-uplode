/// Client-side input validation (server re-validates everything).
abstract final class Validators {
  static final RegExp _email =
      RegExp(r'^[\w.+-]+@[a-zA-Z\d-]+(\.[a-zA-Z\d-]+)+$');

  static String? email(String? value) {
    final String v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter your email address';
    if (!_email.hasMatch(v)) return 'That email address doesn\'t look right';
    return null;
  }

  static String? password(String? value) {
    final String v = value ?? '';
    if (v.isEmpty) return 'Please enter your password';
    if (v.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  static String? strongPassword(String? value) {
    final String v = value ?? '';
    if (v.length < 10) return 'Use at least 10 characters';
    if (!v.contains(RegExp(r'[A-Z]'))) return 'Add an uppercase letter';
    if (!v.contains(RegExp(r'[0-9]'))) return 'Add a number';
    return null;
  }

  static String? requiredField(String? value, {String label = 'This field'}) {
    if ((value ?? '').trim().isEmpty) return '$label is required';
    return null;
  }

  static String? latitude(String? value) {
    final double? v = double.tryParse((value ?? '').trim());
    if (v == null || v < -90 || v > 90) return 'Enter a valid latitude';
    return null;
  }

  static String? longitude(String? value) {
    final double? v = double.tryParse((value ?? '').trim());
    if (v == null || v < -180 || v > 180) return 'Enter a valid longitude';
    return null;
  }
}
