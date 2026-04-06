import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'; // 👈 Required for the password check

// ─── 1. THE NOTIFIER CLASS ───
class BalanceVisibilityNotifier extends Notifier<bool> {
  Timer? _timer;
  final _secureStorage = const FlutterSecureStorage();

  @override
  bool build() {
    // Clean up the timer if the provider is ever destroyed
    ref.onDispose(() {
      _timer?.cancel();
    });

    return false; // false = locked by default
  }

  // Unlocks the balance and starts the 20-second countdown
  void unlock() {
    state = true;
    _timer?.cancel(); // Cancel any existing timer so they don't overlap

    // Automatically lock again after 20 seconds
    _timer = Timer(const Duration(seconds: 20), () {
      state = false;
    });
  }

  // Manually lock the balance immediately
  void lock() {
    _timer?.cancel();
    state = false;
  }

  // 👇 THIS IS THE MISSING PIECE! 👇
  // This handles the Firebase background login secretly
  // 👇 THE NEW LOCAL PIN CHECKER
  Future<bool> verifyPassword(String enteredPin) async {
    try {
      // 1. Pull the saved PIN from the phone's hardware vault
      // This matches the key 'user_ui_pin' we used in AuthNotifier
      final savedPin = await _secureStorage.read(key: 'user_ui_pin');

      // 2. Compare what they typed (enteredPin) to what is saved (savedPin)
      if (savedPin != null && savedPin == enteredPin) {
        return true; // Matches! Unlock instantly.
      } else {
        return false; // Wrong PIN
      }
    } catch (e) {
      return false;
    }
  }
}

// ─── 2. THE PROVIDER ───
final balanceVisibilityProvider = NotifierProvider<BalanceVisibilityNotifier, bool>(
  BalanceVisibilityNotifier.new,
);