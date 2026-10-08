import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class SessionStore {
  SessionStore({
    FlutterSecureStorage? secureStorage,
  }) : _secure = secureStorage ??
            const FlutterSecureStorage(
              webOptions: WebOptions(
                dbName: 'arsave',
                publicKey: 'arsave',
              ),
            );

  final FlutterSecureStorage _secure;

  static const _tokenKey = 'arsave_token';
  static const _emailKey = 'arsave_email';
  static const _saltKey = 'arsave_kdf_salt';
  static const _deviceKey = 'arsave_device_uid';

  Future<void> saveSession({
    required String token,
    required String email,
    required String kdfSaltB64,
  }) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      await prefs.setString(_emailKey, email);
      await prefs.setString(_saltKey, kdfSaltB64);
      return;
    }
    await _secure.write(key: _tokenKey, value: token);
    await _secure.write(key: _emailKey, value: email);
    await _secure.write(key: _saltKey, value: kdfSaltB64);
  }

  Future<String?> getToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_tokenKey);
    }
    return _secure.read(key: _tokenKey);
  }

  Future<String?> getEmail() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_emailKey);
    }
    return _secure.read(key: _emailKey);
  }

  Future<String?> getKdfSaltB64() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_saltKey);
    }
    return _secure.read(key: _saltKey);
  }

  Future<void> clearSession() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_emailKey);
      await prefs.remove(_saltKey);
      return;
    }
    await _secure.delete(key: _tokenKey);
    await _secure.delete(key: _emailKey);
    await _secure.delete(key: _saltKey);
  }

  Future<String> getOrCreateDeviceUid() async {
    final prefs = await SharedPreferences.getInstance();
    var uid = prefs.getString(_deviceKey);
    if (uid == null || uid.isEmpty) {
      uid = const Uuid().v4();
      await prefs.setString(_deviceKey, uid);
    }
    return uid;
  }
}
