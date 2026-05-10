import 'package:callcenter_salonuser_mobil/models/auth_models.dart';
import 'package:callcenter_salonuser_mobil/services/session_store.dart';
import 'package:flutter/foundation.dart';

/// Provider üzerinde dolaşan oturum state'i. `signIn` LoginResult'tan
/// üretilmiş user + token'ı kalıcı depoya yazar; `signOut` temizler.
class SessionState extends ChangeNotifier {
  SessionState(this._store);

  final SessionStore _store;

  String? _token;
  String? _refreshToken;
  SalonStaffUser? _user;

  String? get token => _token;
  String? get refreshToken => _refreshToken;
  SalonStaffUser? get user => _user;
  bool get isLoggedIn => _token != null && _token!.isNotEmpty && _user != null;

  Future<void> loadFromDisk() async {
    final loaded = await _store.load();
    _token = loaded.token;
    _refreshToken = loaded.refreshToken;
    _user = loaded.user;
    notifyListeners();
  }

  Future<void> signIn(LoginResult result) async {
    final user = result.toUser();
    _token = result.token;
    _refreshToken = result.refreshToken;
    _user = user;
    await _store.save(
      token: result.token,
      refreshToken: result.refreshToken,
      user: user,
    );
    notifyListeners();
  }

  Future<void> updateTokens({
    required String token,
    required String refreshToken,
    DateTime? expiresAt,
  }) async {
    _token = token;
    _refreshToken = refreshToken;
    final u = _user;
    if (u != null && expiresAt != null) {
      _user = SalonStaffUser(
        fullName: u.fullName,
        role: u.role,
        preferredLanguage: u.preferredLanguage,
        mustChangePassword: u.mustChangePassword,
        expiresAt: expiresAt,
        claims: u.claims,
      );
    }
    if (_user != null) {
      await _store.save(token: token, refreshToken: refreshToken, user: _user!);
    }
    notifyListeners();
  }

  Future<void> signOut() async {
    _token = null;
    _refreshToken = null;
    _user = null;
    await _store.clear();
    notifyListeners();
  }
}
