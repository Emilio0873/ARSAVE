import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../core/api/api_client.dart';
import '../../core/crypto/crypto_service.dart';
import '../../core/feedback.dart';
import '../../core/models/models.dart';
import '../../core/platform_info.dart';
import '../../core/storage/session_store.dart';

class AuthState extends ChangeNotifier {
  AuthState({
    required this.api,
    required this.crypto,
    required this.store,
  });

  final ApiClient api;
  final CryptoService crypto;
  final SessionStore store;

  UserModel? user;
  bool bootstrapping = true;
  String? error;
  bool busy = false;

  bool get isAuthenticated => user != null && crypto.hasMasterKey;

  Future<void> bootstrap() async {
    bootstrapping = true;
    notifyListeners();
    try {
      final token = await store.getToken();
      if (token == null) {
        user = null;
        return;
      }
      // Token present but master key requires password — force login screen
      // while keeping token only after successful password unlock.
      user = null;
      await store.clearSession();
    } finally {
      bootstrapping = false;
      notifyListeners();
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      await api.register(email: email, password: password, name: name);
      await login(email: email, password: password);
    } catch (e) {
      error = friendlyError(e);
      rethrow;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      final deviceUid = await store.getOrCreateDeviceUid();
      final deviceName = deviceDisplayName();
      final data = await api.login(
        email: email,
        password: password,
        deviceUid: deviceUid,
        deviceName: deviceName,
      );
      final token = data['token'] as String;
      final saltB64 = data['kdf_salt_b64'] as String;
      final userJson = data['user'] as Map<String, dynamic>;
      user = UserModel.fromJson(userJson);

      await store.saveSession(
        token: token,
        email: email,
        kdfSaltB64: saltB64,
      );
      await crypto.deriveAndSetMasterKey(
        password: password,
        salt: base64Decode(saltB64),
      );

      await api.registerDevice(deviceUid: deviceUid, deviceName: deviceName);
    } catch (e) {
      error = friendlyError(e);
      user = null;
      crypto.clearMasterKey();
      rethrow;
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      await api.logout();
    } finally {
      crypto.clearMasterKey();
      await store.clearSession();
      user = null;
      notifyListeners();
    }
  }

  Future<void> updateName(String name) async {
    user = await api.updateProfile(name);
    notifyListeners();
  }
}
