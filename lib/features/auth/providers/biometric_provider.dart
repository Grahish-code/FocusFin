import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricNotifier extends Notifier<bool> {
  final LocalAuthentication _auth = LocalAuthentication();

  @override
  bool build() {
    _loadPreference();
    return false; // False by default until we load from SharedPreferences
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool('biometric_enabled') ?? false;
  }

  // Toggles the lock ON/OFF from the Setup or Profile Screen
  // Toggles the lock ON/OFF from the Setup or Profile Screen
  Future<bool> toggleBiometric(bool enable) async {
    if (enable) {
      // ─── STRICT FINGERPRINT CHECK ───
      final availableBiometrics = await _auth.getAvailableBiometrics();

      // On older Androids it returns 'fingerprint'. On newer Androids it returns 'strong'.
      // If neither exists, it means the device only has weak Face Unlock or no biometrics.
      if (!availableBiometrics.contains(BiometricType.fingerprint) &&
          !availableBiometrics.contains(BiometricType.strong)) {
        return false; // Reject enablement
      }

      // Ask for fingerprint BEFORE turning it on
      final authenticated = await requireAuth(reason: 'Scan fingerprint to enable App Lock');
      if (authenticated) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('biometric_enabled', true);
        state = true;
        return true;
      }
      return false; // Failed to authenticate, keep it off
    } else {
      // Turning it off
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('biometric_enabled', false);
      state = false;
      return true;
    }
  }

  // The reusable function to trigger the Fingerprint/Face ID scanner
  // The reusable function to trigger the Fingerprint/Face ID scanner
  Future<bool> requireAuth({String reason = 'Verify identity'}) async {
    try {
      final isAvailable = await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
      if (!isAvailable) return true; // If device has no scanner, just let them pass

      // 👇 EXACT SYNTAX FOR local_auth ^3.0.1 👇
      return await _auth.authenticate(
        localizedReason: reason,
        biometricOnly: true,
        persistAcrossBackgrounding: true, // This replaced stickyAuth in v3.0.0
      );
    } catch (e) {
      return false; // User canceled or error
    }
  }
}

final biometricProvider = NotifierProvider<BiometricNotifier, bool>(
  BiometricNotifier.new,
);