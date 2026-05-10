import 'dart:io';

import 'package:callcenter_salonuser_mobil/config/app_config.dart';
import 'package:callcenter_salonuser_mobil/models/appointment_models.dart';
import 'package:callcenter_salonuser_mobil/models/auth_models.dart';
import 'package:callcenter_salonuser_mobil/models/cash_models.dart';
import 'package:callcenter_salonuser_mobil/models/expense_models.dart';
import 'package:callcenter_salonuser_mobil/models/inventory_models.dart';
import 'package:callcenter_salonuser_mobil/models/invoice_models.dart';
import 'package:callcenter_salonuser_mobil/models/marketing_models.dart';
import 'package:callcenter_salonuser_mobil/models/before_after_models.dart';
import 'package:callcenter_salonuser_mobil/models/consent_form_models.dart';
import 'package:callcenter_salonuser_mobil/models/noshow_policy_models.dart';
import 'package:callcenter_salonuser_mobil/models/package_models.dart';
import 'package:callcenter_salonuser_mobil/models/waitlist_models.dart';
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

  // ─────────── Adisyon (Invoice) — sln-finance ───────────

  /// `GET /api/sln-finance/invoices` — opsiyonel from/to (UTC iso) + statusId filtreleri.
  Future<List<SlnInvoice>> fetchInvoices({DateTime? from, DateTime? to, int? statusId}) async {
    final res = await _dio.get<List<dynamic>>('/api/sln-finance/invoices', queryParameters: {
      if (from != null) 'from': from.toUtc().toIso8601String(),
      if (to != null) 'to': to.toUtc().toIso8601String(),
      if (statusId != null) 'statusId': statusId,
    });
    final raw = res.data ?? [];
    return raw.map((e) => SlnInvoice.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// `GET /api/sln-finance/invoices/{id}` — detay.
  Future<SlnInvoice> fetchInvoice(int id) async {
    final res = await _dio.get<Map<String, dynamic>>('/api/sln-finance/invoices/$id');
    final data = res.data;
    if (data == null) throw StateError('Adisyon bulunamadi');
    return SlnInvoice.fromJson(data);
  }

  /// `POST /api/sln-finance/invoices` — yeni adisyon (kayit + odeme).
  Future<SlnInvoice> createInvoice(SlnInvoiceCreate dto) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/sln-finance/invoices',
      data: dto.toJson(),
    );
    final data = res.data;
    if (data == null) throw StateError('Adisyon olusturulamadi');
    return SlnInvoice.fromJson(data);
  }

  /// `PUT /api/sln-finance/invoices/{id}/cancel` — adisyonu iptal et.
  Future<void> cancelInvoice(int id) async {
    await _dio.put<void>('/api/sln-finance/invoices/$id/cancel');
  }

  // ─────────── Kasa (cash register + transactions) — sln-finance ───────────

  Future<List<CashRegister>> fetchCashRegisters() async {
    final res = await _dio.get<dynamic>('/api/sln-finance/cash-registers');
    final raw = _asList(res.data);
    return raw.map((e) => CashRegister.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<CashTransaction>> fetchCashTransactions(
      int registerId, {DateTime? from, DateTime? to}) async {
    final res = await _dio.get<dynamic>(
      '/api/sln-finance/cash-registers/$registerId/transactions',
      queryParameters: {
        if (from != null) 'from': from.toUtc().toIso8601String(),
        if (to != null) 'to': to.toUtc().toIso8601String(),
      },
    );
    final raw = _asList(res.data);
    return raw.map((e) => CashTransaction.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<CashTransaction> addCashTransaction(
      int registerId, CashTransactionCreate dto) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/sln-finance/cash-registers/$registerId/transactions',
      data: dto.toJson(),
    );
    final data = res.data;
    if (data == null) throw StateError('Hareket eklenemedi');
    return CashTransaction.fromJson(data);
  }

  /// `GET /api/sln-finance/cash-registers/{id}/daily-summary` — anonymous summary
  /// (totalIncome, totalExpense, netCash, vb.). UI tarafi raw map kullanir.
  Future<Map<String, dynamic>> fetchCashDailySummary(int registerId) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/sln-finance/cash-registers/$registerId/daily-summary',
    );
    return res.data ?? {};
  }

  static List<dynamic> _asList(dynamic raw) {
    if (raw is List) return raw;
    if (raw is Map && raw['items'] is List) return raw['items'] as List<dynamic>;
    return const [];
  }

  // ─────────── Phase 9: Envanter (Products / Suppliers / Recipes) ───────────

  // Products
  Future<List<SlnProduct>> fetchProducts() async {
    final res = await _dio.get<List<dynamic>>('/api/sln-products');
    return (res.data ?? []).map((e) => SlnProduct.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<SlnProduct> fetchProduct(int id) async {
    final res = await _dio.get<Map<String, dynamic>>('/api/sln-products/$id');
    return SlnProduct.fromJson(res.data ?? {});
  }

  Future<SlnProduct> createProduct(SlnProductCreate dto) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/sln-products',
      data: dto.toJson(),
    );
    return SlnProduct.fromJson(res.data ?? {});
  }

  Future<void> updateProduct(int id, SlnProductCreate dto) async {
    await _dio.put<void>('/api/sln-products/$id', data: dto.toJson());
  }

  Future<void> deleteProduct(int id) async {
    await _dio.delete<void>('/api/sln-products/$id');
  }

  // Product Categories + Brands (urun formu icin gerekli)
  Future<List<SlnProductCategory>> fetchProductCategories() async {
    final res = await _dio.get<List<dynamic>>('/api/sln-products/categories');
    return (res.data ?? []).map((e) => SlnProductCategory.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<SlnBrand>> fetchProductBrands() async {
    final res = await _dio.get<List<dynamic>>('/api/sln-products/brands');
    return (res.data ?? []).map((e) => SlnBrand.fromJson(e as Map<String, dynamic>)).toList();
  }

  // Suppliers (sln-products altinda)
  Future<List<SlnSupplier>> fetchSuppliers() async {
    final res = await _dio.get<List<dynamic>>('/api/sln-products/suppliers');
    return (res.data ?? []).map((e) => SlnSupplier.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<SlnSupplier> createSupplier(SlnSupplierCreate dto) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/sln-products/suppliers',
      data: dto.toJson(),
    );
    return SlnSupplier.fromJson(res.data ?? {});
  }

  Future<void> updateSupplier(int id, SlnSupplierCreate dto) async {
    await _dio.put<void>('/api/sln-products/suppliers/$id', data: dto.toJson());
  }

  Future<void> deleteSupplier(int id) async {
    await _dio.delete<void>('/api/sln-products/suppliers/$id');
  }

  // Recipes (sln-recipes)
  Future<List<SlnRecipe>> fetchRecipes() async {
    final res = await _dio.get<List<dynamic>>('/api/sln-recipes');
    return (res.data ?? []).map((e) => SlnRecipe.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<SlnRecipe> fetchRecipe(int id) async {
    final res = await _dio.get<Map<String, dynamic>>('/api/sln-recipes/$id');
    return SlnRecipe.fromJson(res.data ?? {});
  }

  Future<SlnRecipe> createRecipe(SlnRecipeCreate dto) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/sln-recipes',
      data: dto.toJson(),
    );
    return SlnRecipe.fromJson(res.data ?? {});
  }

  Future<void> updateRecipe(int id, SlnRecipeCreate dto) async {
    await _dio.put<void>('/api/sln-recipes/$id', data: dto.toJson());
  }

  Future<void> deleteRecipe(int id) async {
    await _dio.delete<void>('/api/sln-recipes/$id');
  }

  // ─────────── Phase 10: Pazarlama (Campaigns/Email/Winback/GiftCards) ───────────

  // SMS Campaigns (sln-marketing/campaigns)
  Future<List<SlnCampaign>> fetchCampaigns() async {
    final res = await _dio.get<List<dynamic>>('/api/sln-marketing/campaigns');
    return (res.data ?? []).map((e) => SlnCampaign.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<SlnCampaign> fetchCampaign(int id) async {
    final res = await _dio.get<Map<String, dynamic>>('/api/sln-marketing/campaigns/$id');
    return SlnCampaign.fromJson(res.data ?? {});
  }

  Future<SlnCampaign> createCampaign(SlnCampaignCreate dto) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/sln-marketing/campaigns',
      data: dto.toJson(),
    );
    return SlnCampaign.fromJson(res.data ?? {});
  }

  Future<void> updateCampaign(int id, SlnCampaignCreate dto) async {
    await _dio.put<void>('/api/sln-marketing/campaigns/$id', data: dto.toJson());
  }

  Future<void> deleteCampaign(int id) async {
    await _dio.delete<void>('/api/sln-marketing/campaigns/$id');
  }

  Future<void> sendCampaign(int id) async {
    await _dio.post<void>('/api/sln-marketing/campaigns/$id/send');
  }

  // Email Campaigns (sln-email-campaigns)
  Future<List<SlnEmailCampaign>> fetchEmailCampaigns() async {
    final res = await _dio.get<List<dynamic>>('/api/sln-email-campaigns');
    return (res.data ?? []).map((e) => SlnEmailCampaign.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<SlnEmailCampaign> createEmailCampaign(SlnEmailCampaignCreate dto) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/sln-email-campaigns',
      data: dto.toJson(),
    );
    return SlnEmailCampaign.fromJson(res.data ?? {});
  }

  Future<void> updateEmailCampaign(int id, SlnEmailCampaignCreate dto) async {
    await _dio.put<void>('/api/sln-email-campaigns/$id', data: dto.toJson());
  }

  Future<void> deleteEmailCampaign(int id) async {
    await _dio.delete<void>('/api/sln-email-campaigns/$id');
  }

  Future<void> sendEmailCampaign(int id) async {
    await _dio.post<void>('/api/sln-email-campaigns/$id/send');
  }

  // Winback (sln-winback)
  Future<List<SlnWinbackRule>> fetchWinbackRules() async {
    final res = await _dio.get<List<dynamic>>('/api/sln-winback');
    return (res.data ?? []).map((e) => SlnWinbackRule.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<SlnWinbackRule> createWinbackRule(SlnWinbackRuleCreate dto) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/sln-winback',
      data: dto.toJson(),
    );
    return SlnWinbackRule.fromJson(res.data ?? {});
  }

  Future<void> updateWinbackRule(int id, SlnWinbackRuleCreate dto) async {
    await _dio.put<void>('/api/sln-winback/$id', data: dto.toJson());
  }

  Future<void> deleteWinbackRule(int id) async {
    await _dio.delete<void>('/api/sln-winback/$id');
  }

  Future<void> toggleWinbackRule(int id) async {
    await _dio.post<void>('/api/sln-winback/$id/toggle');
  }

  Future<SlnWinbackPreview> previewWinback(int id) async {
    final res = await _dio.get<Map<String, dynamic>>('/api/sln-winback/$id/preview');
    return SlnWinbackPreview.fromJson(res.data ?? {});
  }

  Future<void> winbackToCampaign(int id) async {
    await _dio.post<void>('/api/sln-winback/$id/create-campaign');
  }

  // Gift Cards (sln-gift-cards)
  Future<List<SlnGiftCard>> fetchGiftCards() async {
    final res = await _dio.get<List<dynamic>>('/api/sln-gift-cards');
    return (res.data ?? []).map((e) => SlnGiftCard.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<SlnGiftCard> fetchGiftCardByCode(String code) async {
    final res = await _dio.get<Map<String, dynamic>>('/api/sln-gift-cards/by-code/$code');
    return SlnGiftCard.fromJson(res.data ?? {});
  }

  Future<SlnGiftCard> createGiftCard(SlnGiftCardCreate dto) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/sln-gift-cards',
      data: dto.toJson(),
    );
    return SlnGiftCard.fromJson(res.data ?? {});
  }

  Future<void> deactivateGiftCard(int id) async {
    await _dio.put<void>('/api/sln-gift-cards/$id/deactivate');
  }

  // ─────────── Phase 11.1: Expenses ───────────

  Future<List<ExpenseCategory>> fetchExpenseCategories() async {
    final res = await _dio.get<List<dynamic>>('/api/sln-finance/expense-categories');
    return (res.data ?? []).map((e) => ExpenseCategory.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ExpenseCategory> createExpenseCategory(String name) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/sln-finance/expense-categories',
      data: {'name': name},
    );
    return ExpenseCategory.fromJson(res.data ?? {});
  }

  Future<List<Expense>> fetchExpenses({DateTime? from, DateTime? to, int? categoryId}) async {
    final res = await _dio.get<List<dynamic>>(
      '/api/sln-finance/expenses',
      queryParameters: {
        if (from != null) 'from': from.toUtc().toIso8601String(),
        if (to != null) 'to': to.toUtc().toIso8601String(),
        if (categoryId != null) 'categoryId': categoryId,
      },
    );
    return (res.data ?? []).map((e) => Expense.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Expense> createExpense(ExpenseCreate dto) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/sln-finance/expenses',
      data: dto.toJson(),
    );
    return Expense.fromJson(res.data ?? {});
  }

  Future<void> deleteExpense(int id) async {
    await _dio.delete<void>('/api/sln-finance/expenses/$id');
  }

  // ─────────── Phase 11.2: Waitlist ───────────

  Future<List<WaitlistEntry>> fetchWaitlist() async {
    final res = await _dio.get<List<dynamic>>('/api/sln-waitlist');
    return (res.data ?? []).map((e) => WaitlistEntry.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<WaitlistEntry> createWaitlistEntry(WaitlistEntryCreate dto) async {
    final res = await _dio.post<Map<String, dynamic>>('/api/sln-waitlist', data: dto.toJson());
    return WaitlistEntry.fromJson(res.data ?? {});
  }

  Future<void> updateWaitlistEntry(int id, WaitlistEntryCreate dto) async {
    await _dio.put<void>('/api/sln-waitlist/$id', data: dto.toJson());
  }

  Future<void> updateWaitlistStatus(int id, int statusId) async {
    await _dio.put<void>('/api/sln-waitlist/$id/status/$statusId');
  }

  Future<void> deleteWaitlistEntry(int id) async {
    await _dio.delete<void>('/api/sln-waitlist/$id');
  }

  // ─────────── Phase 11.3: BeforeAfter ───────────

  Future<List<BeforeAfterPhoto>> fetchBeforeAfter() async {
    final res = await _dio.get<List<dynamic>>('/api/sln-before-after');
    return (res.data ?? []).map((e) => BeforeAfterPhoto.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<BeforeAfterPhoto> createBeforeAfter(BeforeAfterPhotoCreate dto) async {
    final res = await _dio.post<Map<String, dynamic>>('/api/sln-before-after', data: dto.toJson());
    return BeforeAfterPhoto.fromJson(res.data ?? {});
  }

  Future<void> updateBeforeAfter(int id, BeforeAfterPhotoCreate dto) async {
    await _dio.put<void>('/api/sln-before-after/$id', data: dto.toJson());
  }

  Future<void> deleteBeforeAfter(int id) async {
    await _dio.delete<void>('/api/sln-before-after/$id');
  }

  // ─────────── Phase 11.4: ConsentForms ───────────

  Future<List<ConsentForm>> fetchConsentForms() async {
    final res = await _dio.get<List<dynamic>>('/api/sln-consent-forms');
    return (res.data ?? []).map((e) => ConsentForm.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ConsentForm> createConsentForm(ConsentFormCreate dto) async {
    final res = await _dio.post<Map<String, dynamic>>('/api/sln-consent-forms', data: dto.toJson());
    return ConsentForm.fromJson(res.data ?? {});
  }

  Future<void> updateConsentForm(int id, ConsentFormCreate dto) async {
    await _dio.put<void>('/api/sln-consent-forms/$id', data: dto.toJson());
  }

  Future<void> deleteConsentForm(int id) async {
    await _dio.delete<void>('/api/sln-consent-forms/$id');
  }

  // ─────────── Phase 11.5: NoShow Policy ───────────

  Future<NoShowPolicy?> fetchNoShowPolicy() async {
    final res = await _dio.get<dynamic>('/api/sln-noshow-policy');
    final data = res.data;
    if (data == null) return null;
    if (data is Map<String, dynamic>) return NoShowPolicy.fromJson(data);
    return null;
  }

  Future<NoShowPolicy> upsertNoShowPolicy(NoShowPolicyUpdate dto) async {
    final res = await _dio.post<Map<String, dynamic>>('/api/sln-noshow-policy', data: dto.toJson());
    return NoShowPolicy.fromJson(res.data ?? {});
  }

  // ─────────── Phase 11.6: Packages ───────────

  Future<List<PackageDefinition>> fetchPackageDefinitions() async {
    final res = await _dio.get<List<dynamic>>('/api/sln-packages/definitions');
    return (res.data ?? []).map((e) => PackageDefinition.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<PackageDefinition> createPackageDefinition(PackageDefinitionCreate dto) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/sln-packages/definitions',
      data: dto.toJson(),
    );
    return PackageDefinition.fromJson(res.data ?? {});
  }

  Future<void> updatePackageDefinition(int id, PackageDefinitionCreate dto) async {
    await _dio.put<void>('/api/sln-packages/definitions/$id', data: dto.toJson());
  }

  Future<void> deletePackageDefinition(int id) async {
    await _dio.delete<void>('/api/sln-packages/definitions/$id');
  }

  Future<List<ClientPackage>> fetchClientPackages() async {
    final res = await _dio.get<List<dynamic>>('/api/sln-packages/client-packages');
    return (res.data ?? []).map((e) => ClientPackage.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<ClientPackage> sellPackage({required int packageDefinitionId, int? slnClientId, int paymentMethodId = 1}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/api/sln-packages/sell',
      data: {
        'packageDefinitionId': packageDefinitionId,
        if (slnClientId != null) 'slnClientId': slnClientId,
        'paymentMethodId': paymentMethodId,
      },
    );
    return ClientPackage.fromJson(res.data ?? {});
  }

  Future<void> usePackage({required int clientPackageId, String? notes}) async {
    await _dio.post<void>(
      '/api/sln-packages/use',
      data: {
        'clientPackageId': clientPackageId,
        if (notes != null) 'notes': notes,
      },
    );
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

  // ─────────── Reports (sln-reports) ───────────

  Future<Map<String, dynamic>> getReportKpis({DateTime? from, DateTime? to}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/sln-reports/kpis',
      queryParameters: <String, dynamic>{
        if (from != null) 'from': from.toUtc().toIso8601String(),
        if (to != null) 'to': to.toUtc().toIso8601String(),
      },
    );
    return res.data ?? {};
  }

  Future<List<Map<String, dynamic>>> getReportStaff(
      {DateTime? from, DateTime? to}) async {
    final res = await _dio.get<dynamic>(
      '/api/sln-reports/staff',
      queryParameters: <String, dynamic>{
        if (from != null) 'from': from.toUtc().toIso8601String(),
        if (to != null) 'to': to.toUtc().toIso8601String(),
      },
    );
    final raw = res.data;
    if (raw is List) return raw.cast<Map<String, dynamic>>();
    if (raw is Map<String, dynamic>) {
      final items = raw['items'] ?? raw['data'] ?? raw['rows'];
      if (items is List) return items.cast<Map<String, dynamic>>();
    }
    return const [];
  }

  Future<Map<String, dynamic>> getReportSales(
      {DateTime? from, DateTime? to}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/api/sln-reports/sales',
      queryParameters: <String, dynamic>{
        if (from != null) 'from': from.toUtc().toIso8601String(),
        if (to != null) 'to': to.toUtc().toIso8601String(),
      },
    );
    return res.data ?? {};
  }

  // ─────────── Loyalty (sln-loyalty) ───────────

  Future<Map<String, dynamic>> getLoyaltyConfig() async {
    final res = await _dio.get<Map<String, dynamic>>('/api/sln-loyalty/config');
    return res.data ?? {};
  }

  Future<void> saveLoyaltyConfig(Map<String, dynamic> body) async {
    await _dio.post<void>('/api/sln-loyalty/config', data: body);
  }

  Future<List<Map<String, dynamic>>> getLoyaltyClients() async {
    final res = await _dio.get<List<dynamic>>('/api/sln-loyalty/clients');
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
