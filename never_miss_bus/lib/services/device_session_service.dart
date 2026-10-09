import 'dart:math';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, TargetPlatform;
import 'package:shared_preferences/shared_preferences.dart';

/// Single-device login support.
///
/// Each install gets a persistent random device ID. On login the ID is
/// written to the user's profile (settings.activeDevice). If the profile
/// later shows a DIFFERENT device ID, this device was replaced by a newer
/// login and must sign out ("last login wins" — WhatsApp style).
class DeviceSessionService {
  static const String _prefsKey = 'nmb_device_id';

  /// Special marker used by admin "Force logout".
  static const String revokedId = 'REVOKED';

  String? _cachedId;

  /// True while a fresh login is still writing its device registration —
  /// the kick-listener must not act on stale data during this window.
  bool loginWriteInProgress = false;

  Future<String> getDeviceId() async {
    if (_cachedId != null) return _cachedId!;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? id = prefs.getString(_prefsKey);
    if (id == null || id.isEmpty) {
      final Random rng = Random.secure();
      const String chars =
          'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
      id = List<String>.generate(
        24,
        (_) => chars[rng.nextInt(chars.length)],
      ).join();
      await prefs.setString(_prefsKey, id);
    }
    _cachedId = id;
    return id;
  }

  Future<String> getDeviceName() async {
    try {
      final DeviceInfoPlugin plugin = DeviceInfoPlugin();
      if (defaultTargetPlatform == TargetPlatform.android) {
        final AndroidDeviceInfo a = await plugin.androidInfo;
        return '${a.brand} ${a.model}'.trim();
      }
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        final IosDeviceInfo i = await plugin.iosInfo;
        return i.utsname.machine;
      }
    } catch (_) {/* fall through */}
    return 'Device';
  }
}
