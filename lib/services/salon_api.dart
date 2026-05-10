import 'dart:io';

import 'package:callcenter_salonuser_mobil/config/app_config.dart';
import 'package:callcenter_salonuser_mobil/models/appointment_models.dart';
import 'package:callcenter_salonuser_mobil/models/auth_models.dart';
import 'package:callcenter_salonuser_mobil/models/portal_personnel.dart';
import 'package:callcenter_salonuser_mobil/models/sln_client.dart';
import 'package:callcenter_salonuser_mobil/models/sln_membership.dart';
import 'package:callcenter_salonuser_mobil/models/sln_review.dart';
import 'package:callcenter_salonuser_mobil/models/sln_service.dart';
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

  // ─────────── Appointments (sln-appointments) ───────────

  /// `GET /api/sln-appointments?from=&to=&personnelId=&statusId=&slnClientId=&branchId=`
  Future<List<Appointment>> getAppointments({
    DateTime? from,
    DateTime? to,
    int? personnelId,
    int? statusId,
    int? slnClientId,
    int? branchId,
  }) async {
    final res = await _dio.get<List<dynamic>>(
      '/api/sln-appointments',
      queryParameters: <String, dynamic>{
        if (from != null) 'from': from.toUtc().toIso8601String(),
        if (to != null) 'to': to.toUtc().toIso8601String(),
        if (personnelId != null) 'personnelId': personnelId,
        if (statusId != null) 'statusId': statusId,
        if (slnClientId != null) 'slnClientId': slnClientId,
        if (branchId != null) 'branchId': branchId,
      },
    );
    final raw = res.data ?? [];
    return raw.map((e) => Appointment.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Appointment> getAppointment(int id) async {
    final res = await _dio.get<Map<String, dynamic>>('/api/sln-appointments/$id');
    final data = res.data;
    if (data == null) throw StateError('Boş yanıt');
    return Appointment.fromJson(data);
  }

  Future<Appointment> createAppointment(AppointmentCreate dto) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/sln-appointments',
      data: dto.toJson(),
    );
    final data = res.data;
    if (data == null) throw StateError('Boş yanıt');
    return Appointment.fromJson(data);
  }

  Future<void> updateAppointment(int id, AppointmentCreate dto) async {
    await _dio.put<void>('/api/sln-appointments/$id', data: dto.toJson());
  }

  /// `PUT /api/sln-appointments/{id}/status` — yanıtta `{penalty, message}`.
  Future<AppointmentStatusUpdate> updateAppointmentStatus({
    required int id,
    required int statusId,
  }) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/api/sln-appointments/$id/status',
      data: {'statusId': statusId},
    );
    return AppointmentStatusUpdate.fromJson(res.data ?? const {});
  }

  Future<void> deleteAppointment(int id) async {
    await _dio.delete<void>('/api/sln-appointments/$id');
  }

  Future<bool> checkConflict({
    required int personnelId,
    required DateTime startTime,
    required DateTime endTime,
    int? excludeId,
  }) async {
    final res = await _dio.get<dynamic>(
      '/api/sln-appointments/check-conflict',
      queryParameters: {
        'personnelId': personnelId,
        'startTime': startTime.toUtc().toIso8601String(),
        'endTime': endTime.toUtc().toIso8601String(),
        if (excludeId != null) 'excludeId': excludeId,
      },
    );
    return res.data == true;
  }

  Future<List<Map<String, dynamic>>> getAvailableStaff(List<int> serviceIds) async {
    final res = await _dio.get<List<dynamic>>(
      '/api/sln-appointments/available-staff',
      queryParameters: {'serviceIds': serviceIds.join(',')},
    );
    final raw = res.data ?? [];
    return raw.cast<Map<String, dynamic>>();
  }

  // ─────────── Clients (sln-clients) ───────────

  Future<List<SlnClient>> getClients({String? search}) async {
    final res = await _dio.get<List<dynamic>>(
      '/api/sln-clients',
      queryParameters: <String, dynamic>{
        if (search != null && search.isNotEmpty) 'search': search,
      },
    );
    final raw = res.data ?? [];
    return raw.map((e) => SlnClient.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<SlnClientDetail> getClient(int id) async {
    final res = await _dio.get<Map<String, dynamic>>('/api/sln-clients/$id');
    final data = res.data;
    if (data == null) throw StateError('Boş yanıt');
    return SlnClientDetail.fromJson(data);
  }

  Future<SlnClient> createClient(SlnClientCreate dto) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/sln-clients',
      data: dto.toJson(),
    );
    final data = res.data;
    if (data == null) throw StateError('Boş yanıt');
    return SlnClient.fromJson(data);
  }

  Future<void> updateClient(int id, SlnClientCreate dto, {bool isFavorite = false}) async {
    final body = {...dto.toJson(), 'isFavorite': isFavorite};
    await _dio.put<void>('/api/sln-clients/$id', data: body);
  }

  Future<void> deleteClient(int id) async {
    await _dio.delete<void>('/api/sln-clients/$id');
  }

  Future<void> unblockClient(int id) async {
    await _dio.put<void>('/api/sln-clients/$id/unblock');
  }

  // ─────────── Services + Categories (sln-services) ───────────

  Future<List<SlnServiceCategory>> getServiceCategories() async {
    final res = await _dio.get<List<dynamic>>('/api/sln-services/categories');
    final raw = res.data ?? [];
    return raw
        .map((e) => SlnServiceCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<SlnServiceCategory> createCategory(SlnServiceCategoryCreate dto) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/sln-services/categories',
      data: dto.toJson(),
    );
    final data = res.data;
    if (data == null) throw StateError('Boş yanıt');
    return SlnServiceCategory.fromJson(data);
  }

  Future<void> updateCategory(int id, SlnServiceCategoryCreate dto) async {
    await _dio.put<void>('/api/sln-services/categories/$id', data: dto.toJson());
  }

  Future<void> deleteCategory(int id) async {
    await _dio.delete<void>('/api/sln-services/categories/$id');
  }

  Future<SlnService> createService(SlnServiceCreate dto) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/sln-services',
      data: dto.toJson(),
    );
    final data = res.data;
    if (data == null) throw StateError('Boş yanıt');
    return SlnService.fromJson(data);
  }

  Future<void> updateService(int id, SlnServiceCreate dto) async {
    await _dio.put<void>('/api/sln-services/$id', data: dto.toJson());
  }

  Future<void> deleteService(int id) async {
    await _dio.delete<void>('/api/sln-services/$id');
  }

  // ─────────── Personnel (portal) — read-only ───────────

  /// `GET /api/portal/personnel` — CustomerPersonnel listesi.
  /// CustomerId JWT claim'inden okunur (server-side); query param vermeye gerek yok.
  Future<List<PortalPersonnel>> getPersonnel() async {
    final res = await _dio.get<List<dynamic>>('/api/portal/personnel');
    final raw = res.data ?? [];
    return raw.map((e) => PortalPersonnel.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ─────────── Reviews moderation (sln-reviews) ───────────

  Future<List<SlnReview>> getReviews({int? statusId}) async {
    final res = await _dio.get<List<dynamic>>(
      '/api/sln-reviews',
      queryParameters: <String, dynamic>{
        if (statusId != null) 'statusId': statusId,
      },
    );
    final raw = res.data ?? [];
    return raw.map((e) => SlnReview.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<SlnReviewStats> getReviewStats() async {
    final res = await _dio.get<Map<String, dynamic>>('/api/sln-reviews/stats');
    final data = res.data ?? const <String, dynamic>{};
    return SlnReviewStats.fromJson(data);
  }

  /// `PUT /api/sln-reviews/{id}/status/{statusId}` (1=Bekliyor, 2=Onaylandı, 3=Reddedildi).
  Future<void> updateReviewStatus({required int id, required int statusId}) async {
    await _dio.put<void>('/api/sln-reviews/$id/status/$statusId');
  }

  Future<void> deleteReview(int id) async {
    await _dio.delete<void>('/api/sln-reviews/$id');
  }

  // ─────────── Memberships (sln-memberships) ───────────

  Future<List<SlnMembershipPlan>> getMembershipPlans() async {
    final res = await _dio.get<List<dynamic>>('/api/sln-memberships/plans');
    final raw = res.data ?? [];
    return raw.map((e) => SlnMembershipPlan.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<SlnMembershipPlan> createMembershipPlan(SlnMembershipPlanCreate dto) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/sln-memberships/plans',
      data: dto.toJson(),
    );
    return SlnMembershipPlan.fromJson(res.data ?? const {});
  }

  Future<void> updateMembershipPlan(int id, SlnMembershipPlanCreate dto) async {
    await _dio.put<void>('/api/sln-memberships/plans/$id', data: dto.toJson());
  }

  Future<void> deleteMembershipPlan(int id) async {
    await _dio.delete<void>('/api/sln-memberships/plans/$id');
  }

  Future<List<SlnClientMembership>> getClientMemberships() async {
    final res = await _dio.get<List<dynamic>>('/api/sln-memberships');
    final raw = res.data ?? [];
    return raw
        .map((e) => SlnClientMembership.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> cancelClientMembership(int id) async {
    await _dio.put<void>('/api/sln-memberships/$id/cancel');
  }

  Future<void> freezeClientMembership(int id) async {
    await _dio.put<void>('/api/sln-memberships/$id/freeze');
  }

  Future<void> reactivateClientMembership(int id) async {
    await _dio.put<void>('/api/sln-memberships/$id/reactivate');
  }

  // ─────────── Salon profile + page settings + payment info (sln-profile) ───────────

  /// `GET /api/sln-profile` — full profile JSON (raw map; UI gerekli alanları seçer).
  Future<Map<String, dynamic>> getSalonProfile() async {
    final res = await _dio.get<Map<String, dynamic>>('/api/sln-profile');
    return res.data ?? {};
  }

  /// `POST /api/sln-profile` — `SlnSalonProfileUpdateDto`.
  Future<void> saveSalonProfile({
    String? description,
    String? website,
    String? instagramHandle,
    String? facebookUrl,
    bool isPublished = true,
    int billingType = 1,
  }) async {
    await _dio.post<void>('/api/sln-profile', data: {
      'description': description,
      'website': website,
      'instagramHandle': instagramHandle,
      'facebookUrl': facebookUrl,
      'isPublished': isPublished,
      'billingType': billingType,
    });
  }

  /// `PUT /api/sln-profile/page-settings` — visibility flags + JSON sectionOrder.
  Future<void> savePageSettings(Map<String, dynamic> body) async {
    await _dio.put<void>('/api/sln-profile/page-settings', data: body);
  }

  /// `GET /api/sln-profile/payment-info` — sub-merchant onboarding durumu.
  Future<Map<String, dynamic>> getPaymentInfo() async {
    final res = await _dio.get<Map<String, dynamic>>('/api/sln-profile/payment-info');
    return res.data ?? {};
  }

  /// `POST /api/payments/sub-merchant` — onboarding (PS.4).
  Future<Map<String, dynamic>> submitSubMerchant(Map<String, dynamic> body) async {
    final res = await _dio.post<Map<String, dynamic>>('/api/payments/sub-merchant', data: body);
    return res.data ?? {};
  }

  // ─────────── Branches (sln-branches) ───────────

  Future<List<Map<String, dynamic>>> getBranches() async {
    final res = await _dio.get<List<dynamic>>('/api/sln-branches');
    final raw = res.data ?? [];
    return raw.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getAvailableSlots({
    required int personnelId,
    required DateTime date,
    int durationMinutes = 30,
  }) async {
    final res = await _dio.get<List<dynamic>>(
      '/api/sln-appointments/available-slots',
      queryParameters: {
        'personnelId': personnelId,
        'date': date.toIso8601String().split('T').first,
        'durationMinutes': durationMinutes,
      },
    );
    final raw = res.data ?? [];
    return raw.cast<Map<String, dynamic>>();
  }
}
