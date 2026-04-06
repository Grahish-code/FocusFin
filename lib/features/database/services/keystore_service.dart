import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class KeystoreService {
  static const _keyEncryptionKey = 'db_encryption_key';

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // Save the derived key to Android Keystore
  Future<void> saveKey(String key) async {
    await _storage.write(key: _keyEncryptionKey, value: key);
  }

  // Fetch the key from Android Keystore
  Future<String?> getKey() async {
    return await _storage.read(key: _keyEncryptionKey);
  }

  // Delete key on logout or account wipe
  Future<void> deleteKey() async {
    await _storage.delete(key: _keyEncryptionKey);
  }

  // Check if key exists (user has set up SQLCipher before)
  Future<bool> hasKey() async {
    final key = await _storage.read(key: _keyEncryptionKey);
    return key != null;
  }
}