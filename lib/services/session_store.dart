import 'dart:convert';

import 'package:callcenter_salonuser_mobil/models/auth_models.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Token + refreshToken + user JSON'ı güvenli depoda tutar.
/// Web'de IndexedDB, mobilde Keychain/Keystore arkasında.
class SessionStore {
  SessionStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _kToken = 'staff_token';
  static const _kRefresh = 'staff_refresh';
  static const _kUser = 'staff_user';

  final FlutterSecureStorage _storage;

  Future<void> save({
    required String token,
    required String refreshToken,
    required SalonStaffUser user,
  }) async {
    await Future.wait([
      _storage.write(key: _kToken, value: token),
      _storage.write(key: _kRefresh, value: refreshToken),
      _storage.write(key: _kUser, value: jsonEncode(user.toJson())),
    ]);
  }

  Future<({String? token, String? refreshToken, SalonStaffUser? user})> load() async {
    final results = await Future.wait([
      _storage.read(key: _kToken),
      _storage.read(key: _kRefresh),
      _storage.read(key: _kUser),
    ]);
    SalonStaffUser? user;
    final userRaw = results[2];
    if (userRaw != null && userRaw.isNotEmpty) {
      try {
        final map = jsonDecode(userRaw);
        if (map is Map<String, dynamic>) user = SalonStaffUser.fromJson(map);
      } catch (_) {}
    }
    return (token: results[0], refreshToken: results[1], user: user);
  }

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _kToken),
      _storage.delete(key: _kRefresh),
      _storage.delete(key: _kUser),
    ]);
  }
}
