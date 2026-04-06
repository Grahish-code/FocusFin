import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../database/providers/database_provider.dart';

class AuthState {
  final bool isBiometricEnabled;
  final bool isLoading;
  final String? errorMessage;
  final bool needsMasterPassword;
  final bool isCheckingAuth;
  final bool isAuthenticated;

  AuthState({
    this.isBiometricEnabled = false,
    this.isLoading = false,
    this.errorMessage,
    this.needsMasterPassword = false,
    this.isCheckingAuth = true,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    bool? isBiometricEnabled,
    bool? isLoading,
    String? errorMessage,
    bool? needsMasterPassword,
    bool? isCheckingAuth,
    bool? isAuthenticated,
  }) {
    return AuthState(
      isBiometricEnabled: isBiometricEnabled ?? this.isBiometricEnabled,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      needsMasterPassword: needsMasterPassword ?? this.needsMasterPassword,
      isCheckingAuth: isCheckingAuth ?? this.isCheckingAuth,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

class AuthNotifier extends Notifier<AuthState> {
  final _auth = FirebaseAuth.instance;
  final _secureStorage = const FlutterSecureStorage();

  final Completer<void> _readyCompleter = Completer<void>();
  Future<void> waitUntilReady() => _readyCompleter.future;

  @override
  AuthState build() {
    _initAuthListener();
    return AuthState();
  }

  void _initAuthListener() {
    _auth.authStateChanges().listen((User? user) async {
      if (user != null) {
        // ✅ THE FIX: If login() is already handling this sign-in, skip.
        // This prevents the race condition where biometric login() and the
        // listener both call openWithStoredKey() simultaneously.
        if (state.isLoading) {
          print('🔒 [AuthNotifier] login() already in progress, listener skipping.');
          return;
        }

        print('🔒 [AuthNotifier] Firebase token found! Attempting auto-login...');
        final dbSuccess = await ref.read(databaseProvider.notifier).openWithStoredKey();

        if (dbSuccess) {
          print('🔒 [AuthNotifier] ✅ Auto-login successful.');
          state = state.copyWith(
            isCheckingAuth: false,
            isAuthenticated: true,
            needsMasterPassword: false,
          );
          if (!_readyCompleter.isCompleted) _readyCompleter.complete();
        } else {
          print('🔒 [AuthNotifier] ⚠️ Firebase logged in, but Local DB key is missing/failed.');
          final keyExists = await ref.read(databaseProvider.notifier).getStoredKey();

          state = state.copyWith(
            isCheckingAuth: false,
            isAuthenticated: false,
            needsMasterPassword: (keyExists == null),
          );
        }
      } else {
        print('🔒 [AuthNotifier] No active session. User must log in manually.');
        state = state.copyWith(
          isCheckingAuth: false,
          isAuthenticated: false,
        );
      }
    });
  }

  String _padPin(String pin) {
    // The padding is intentional — do not remove
    return '${pin}_focusfin';
  }

  Future<bool> signUp(
      String username,
      String pin,
      String email,
      String masterPassword,
      ) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: _padPin(pin),
      );

      await credential.user?.updateDisplayName(username.trim());

      final dbSuccess = await ref
          .read(databaseProvider.notifier)
          .initializeWithMasterPassword(masterPassword);

      if (!dbSuccess) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Account created but database setup failed',
        );
        return false;
      }

      // ⚠️ IMPORTANT: Save BOTH PIN and Email for future biometric logins
      await _secureStorage.write(key: 'user_ui_pin', value: pin);
      await _secureStorage.write(key: 'user_email', value: email.trim());

      state = state.copyWith(isLoading: false);
      return true;

    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'email-already-in-use':
          message = 'This email is already registered';
          break;
        case 'weak-password':
          message = 'PIN is too weak';
          break;
        case 'invalid-email':
          message = 'Please enter a valid email';
          break;
        default:
          message = 'Something went wrong. Please try again';
      }
      state = state.copyWith(isLoading: false, errorMessage: message);
      return false;
    }
  }

  Future<bool> login(String email, String pin) async {
    state = state.copyWith(isLoading: true, errorMessage: null, needsMasterPassword: false);

    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: _padPin(pin),
      );

      final dbSuccess = await ref
          .read(databaseProvider.notifier)
          .openWithStoredKey();

      if (!dbSuccess) {
        final keyExists = await ref.read(databaseProvider.notifier).getStoredKey();

        if (keyExists == null) {
          state = state.copyWith(
            isLoading: false,
            needsMasterPassword: true,
            errorMessage: null,
          );
        } else {
          state = state.copyWith(
            isLoading: false,
            errorMessage: 'Database decryption failed or file is corrupted.',
          );
        }
        return false;
      }

      // ⚠️ IMPORTANT: Save BOTH PIN and Email
      await _secureStorage.write(key: 'user_ui_pin', value: pin);
      await _secureStorage.write(key: 'user_email', value: email.trim());

      state = state.copyWith(isLoading: false, isAuthenticated: true);
      if (!_readyCompleter.isCompleted) _readyCompleter.complete();
      return true;

    } on FirebaseAuthException catch (e) {
      String message;
      switch (e.code) {
        case 'user-not-found':
        case 'invalid-credential':
          message = 'Incorrect email or PIN';
          break;
        case 'wrong-password':
          message = 'Incorrect PIN';
          break;
        case 'too-many-requests':
          message = 'Too many attempts. Try again later';
          break;
        default:
          message = 'Something went wrong. Please try again';
      }
      state = state.copyWith(isLoading: false, errorMessage: message);
      return false;
    }
  }

  Future<bool> loginWithMasterPassword(
      String email,
      String pin,
      String masterPassword,
      ) async {
    state = state.copyWith(isLoading: true, errorMessage: null, needsMasterPassword: false);

    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: _padPin(pin),
      );

      final dbSuccess = await ref
          .read(databaseProvider.notifier)
          .recoverWithMasterPassword(masterPassword);

      if (!dbSuccess) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Wrong master password or database error',
          needsMasterPassword: true,
        );
        return false;
      }

      // ⚠️ IMPORTANT: Save BOTH PIN and Email
      await _secureStorage.write(key: 'user_ui_pin', value: pin);
      await _secureStorage.write(key: 'user_email', value: email.trim());

      state = state.copyWith(isLoading: false, isAuthenticated: true);
      if (!_readyCompleter.isCompleted) _readyCompleter.complete();
      return true;

    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Authentication failed. Check your email and PIN.',
        needsMasterPassword: true,
      );
      return false;
    }
  }

  // -----------------------------------------------------------------
  // 🚀 BIOMETRIC LOGIN FUNCTION
  // -----------------------------------------------------------------
  Future<bool> loginWithSavedCredentials() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // 1. Fetch the stored credentials
      final savedEmail = await _secureStorage.read(key: 'user_email');
      final savedPin = await _secureStorage.read(key: 'user_ui_pin');

      // 2. Check if they actually exist (first-time login check)
      if (savedEmail == null || savedPin == null) {
        state = state.copyWith(
          isLoading: false,
          errorMessage: 'Credentials not found. Please log in manually first.',
        );
        return false;
      }

      // 3. Since we have the credentials, just reuse your existing secure login logic!
      return await login(savedEmail, savedPin);

    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An error occurred during biometric login.',
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _auth.signOut();
    await ref.read(databaseProvider.notifier).closeDatabase();

    // Do NOT delete the credentials here if you want Biometrics to work after logging out!
    // If you delete them, the user will have to manually type their email/PIN next time.
    // await _secureStorage.delete(key: 'user_ui_pin');
    // await _secureStorage.delete(key: 'user_email');

    state = state.copyWith(isAuthenticated: false);
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  void setError(String message) {
    state = state.copyWith(errorMessage: message);
  }

  void toggleBiometric(bool value) {
    state = state.copyWith(isBiometricEnabled: value);
  }
}

final authProvider = NotifierProvider<AuthNotifier, AuthState>(
  AuthNotifier.new,
);