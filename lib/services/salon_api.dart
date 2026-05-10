import 'dart:io';

import 'package:callcenter_salonuser_mobil/config/app_config.dart';
import 'package:callcenter_salonuser_mobil/models/auth_models.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

typedef AuthHeaderGetter = String? Function();
typedef UnauthorizedCallback = void Function();

/// CallCenter.Api ile **salon staff** auth uçları:
/// - `POST /api/auth/login` → LoginResponse
/// - `POST /api/auth/refresh` → RefreshTokenResponse
/// - `POST /api/auth/forgot-password` (UserName)
/// - `POST /api/auth/reset-password` (Token, NewPassword)
/// - `POST /api/auth/send-verification-email` (UserName)
/// - `GET  /api/auth/verify-email?token=...`
/// - `POST /api/auth/change-password` (Authorize)
class SalonApiClient {
  SalonApiClient({AuthHeaderGetter? getBearer, UnauthorizedCallback? onUnauthorized})
      : _getBearer = getBearer,
        _onUnauthorized = onUnauthorized {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl.trimRight(),
        connectTimeout: const Duration(seconds: 25),
        receiveTimeout: const Duration(seconds: 35),
        sendTimeout: const Duration(seconds: 35),
        headers: {'Accept': 'application/json'},
      ),
    );

    if (AppConfig.allowBadSsl && _dio.httpClientAdapter is IOHttpClientAdapter) {
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
        final c = HttpClient();
        c.badCertificateCallback = (cert, host, port) => true;
        return c;
      };
    }

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final t = _getBearer?.call();
          if (t != null && t.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $t';
          }
          handler.next(options);
        },
        onError: (err, handler) {
          final code = err.response?.statusCode;
          final sent = err.requestOptions.headers['Authorization'];
          if (code == 401 && sent != null) {
            _onUnauthorized?.call();
          }
          handler.next(err);
        },
      ),
    );
  }

  late final Dio _dio;
  final AuthHeaderGetter? _getBearer;
  final UnauthorizedCallback? _onUnauthorized;

  Future<LoginResult> login({
    required String userName,
    required String password,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/auth/login',
      data: {'userName': userName, 'password': password},
    );
    final data = res.data;
    if (data == null) throw StateError('Boş yanıt');
    return LoginResult.fromJson(data);
  }

  Future<({String token, String refreshToken, DateTime expiresAt})> refresh(
      String refreshToken) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    final data = res.data;
    if (data == null) throw StateError('Boş yanıt');
    DateTime exp = DateTime.now();
    final raw = data['expiresAt'];
    if (raw is String) exp = DateTime.tryParse(raw)?.toLocal() ?? exp;
    return (
      token: data['token'] as String? ?? '',
      refreshToken: data['refreshToken'] as String? ?? '',
      expiresAt: exp,
    );
  }

  /// Backend her durumda 200 döner (kullanıcı sızıntısı önler).
  Future<void> forgotPassword({required String userName}) async {
    await _dio.post<void>(
      '/api/auth/forgot-password',
      data: {'userName': userName},
    );
  }

  Future<void> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    await _dio.post<void>(
      '/api/auth/reset-password',
      data: {'token': token, 'newPassword': newPassword},
    );
  }

  Future<void> sendVerificationEmail({required String userName}) async {
    await _dio.post<void>(
      '/api/auth/send-verification-email',
      data: {'userName': userName},
    );
  }

  Future<void> verifyEmail({required String token}) async {
    await _dio.get<void>(
      '/api/auth/verify-email',
      queryParameters: {'token': token},
    );
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dio.post<void>(
      '/api/auth/change-password',
      data: {'currentPassword': currentPassword, 'newPassword': newPassword},
    );
  }
}
