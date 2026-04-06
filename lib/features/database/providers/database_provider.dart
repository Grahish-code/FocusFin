import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/database_service.dart';
import '../services/keystore_service.dart';

class DatabaseState {
  final bool isOpen;
  final bool isLoading;
  final String? errorMessage;

  DatabaseState({
    this.isOpen = false,
    this.isLoading = false,
    this.errorMessage,
  });

  DatabaseState copyWith({
    bool? isOpen,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DatabaseState(
      isOpen: isOpen ?? this.isOpen,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class DatabaseNotifier extends Notifier<DatabaseState> {
  final _databaseService = DatabaseService();
  final _keystoreService = KeystoreService();

  @override
  DatabaseState build() {
    return DatabaseState();
  }

  // Called at signup — derives key, saves to keystore, opens SQLCipher
  Future<bool> initializeWithMasterPassword(String masterPassword) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final encryptionKey = _databaseService.deriveKey(masterPassword); // GENERATE ENCRYPTION KEY FROM THE USER MASTER PASSWORD
      await _keystoreService.saveKey(encryptionKey); // SAVED THAT KEY IN THE ANDROID KEY STORAGE
      await _databaseService.openEncryptedDatabase(encryptionKey); // OPEN THE ENCRYPTED DATABASE WITH THE ENCRYPTED KEY

      state = state.copyWith(isOpen: true, isLoading: false);
      return true;

    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to initialize database',
      );
      return false;
    }
  }

  // Called on every login — fetches key from keystore and opens DB
  Future<bool> openWithStoredKey() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final encryptionKey = await _keystoreService.getKey();

      if (encryptionKey == null) {
        // Key not found — uninstall/reinstall wiped the keystore
        state = state.copyWith(isLoading: false, isOpen: false);
        return false;
      }

      await _databaseService.openEncryptedDatabase(encryptionKey);

      state = state.copyWith(isOpen: true, isLoading: false);
      return true;

    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to open database',
      );
      return false;
    }
  }

  // Called when key is lost — re-derives key from master password and reopens DB
  Future<bool> recoverWithMasterPassword(String masterPassword) async {
    return await initializeWithMasterPassword(masterPassword);
  }

  // Exposes whether a stored key exists — used to distinguish lost key vs DB error
  Future<String?> getStoredKey() async {
    return await _keystoreService.getKey();
  }

  // Called on logout
  Future<void> closeDatabase() async {
    await _databaseService.closeDatabase();
    state = state.copyWith(isOpen: false);
  }

  DatabaseService get databaseService => _databaseService;
}

final databaseProvider = NotifierProvider<DatabaseNotifier, DatabaseState>(
  DatabaseNotifier.new,
);