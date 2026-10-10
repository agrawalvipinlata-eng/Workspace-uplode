import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLockManager {
  static final LocalAuthentication _auth = LocalAuthentication();
  static final ValueNotifier<bool> enabled = ValueNotifier<bool>(false);

  static Future<void> load() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      enabled.value = prefs.getBool('nmb_app_lock') ?? false;
    } catch (_) {}
  }

  static Future<bool> setEnabled(bool value) async {
    if (value) {
      final bool available = await canAuthenticate();
      if (!available) return false;
    }
    enabled.value = value;
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('nmb_app_lock', value);
    } catch (_) {}
    return true;
  }

  static Future<bool> canAuthenticate() async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  static Future<bool> unlock() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Unlock Never Miss Bus to continue',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
