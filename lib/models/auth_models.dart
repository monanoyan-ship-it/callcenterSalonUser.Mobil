import 'package:callcenter_salonuser_mobil/util/jwt.dart';

/// Backend `LoginResponse` ile birebir eşleşir.
class LoginResult {
  LoginResult({
    required this.token,
    required this.refreshToken,
    required this.fullName,
    required this.role,
    required this.expiresAt,
    required this.mustChangePassword,
    this.preferredLanguage,
  });

  final String token;
  final String refreshToken;
  final String fullName;
  final String role;
  final DateTime expiresAt;
  final bool mustChangePassword;
  final String? preferredLanguage;

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    DateTime exp = DateTime.now();
    final raw = json['expiresAt'];
    if (raw is String) exp = DateTime.tryParse(raw)?.toLocal() ?? exp;
    return LoginResult(
      token: json['token'] as String? ?? '',
      refreshToken: json['refreshToken'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      role: json['role'] as String? ?? '',
      expiresAt: exp,
      mustChangePassword: json['mustChangePassword'] as bool? ?? false,
      preferredLanguage: json['preferredLanguage'] as String?,
    );
  }

  /// Token + ek metadata içeren immutable kullanıcı modeli.
  SalonStaffUser toUser() {
    final claims = decodeJwtPayload(token) ?? {};
    return SalonStaffUser(
      fullName: fullName,
      role: role,
      preferredLanguage: preferredLanguage,
      mustChangePassword: mustChangePassword,
      expiresAt: expiresAt,
      claims: claims,
    );
  }
}

/// Salon staff oturum modeli (token ayrı tutulur, bu sadece kullanıcı bilgisi).
class SalonStaffUser {
  SalonStaffUser({
    required this.fullName,
    required this.role,
    required this.expiresAt,
    required this.claims,
    this.preferredLanguage,
    this.mustChangePassword = false,
  });

  final String fullName;
  final String role;
  final String? preferredLanguage;
  final bool mustChangePassword;
  final DateTime expiresAt;

  /// JWT body claim'leri (PermissionIds, CustomerId, IsCustomerAdmin vb.).
  final Map<String, dynamic> claims;

  /// Backend `AuthFactory` JWT'ye `Role` claim'ini ekler. Salon roller için
  /// `SalonRolePermissions.cs` matrisi: SalonOwner / SalonAdmin / SalonStaff.
  bool get isSalonOwner => role == 'SalonOwner' || (claims['IsCustomerAdmin'] == true || claims['IsCustomerAdmin'] == 'true');
  bool get isSalonAdmin => role == 'SalonAdmin' || isSalonOwner;
  bool get isCustomerAdmin =>
      claims['IsCustomerAdmin'] == true || claims['IsCustomerAdmin'] == 'true';

  /// Kullanıcının çalıştığı tenant (CustomerId claim).
  int? get customerId {
    final v = claims['CustomerId'];
    if (v is int) return v;
    if (v is String) return int.tryParse(v);
    return null;
  }

  /// Virgülle ayrılmış izin ID listesi (claim PermissionIds).
  Set<int> get permissionIds {
    final raw = claims['PermissionIds'];
    if (raw is! String || raw.isEmpty) return const {};
    return raw
        .split(',')
        .map((s) => int.tryParse(s.trim()))
        .whereType<int>()
        .toSet();
  }

  bool hasPermission(int id) => isCustomerAdmin || permissionIds.contains(id);

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'role': role,
        'preferredLanguage': preferredLanguage,
        'mustChangePassword': mustChangePassword,
        'expiresAt': expiresAt.toIso8601String(),
        'claims': claims,
      };

  factory SalonStaffUser.fromJson(Map<String, dynamic> json) {
    DateTime exp = DateTime.now();
    final raw = json['expiresAt'];
    if (raw is String) exp = DateTime.tryParse(raw)?.toLocal() ?? exp;
    final claims = json['claims'];
    return SalonStaffUser(
      fullName: json['fullName'] as String? ?? '',
      role: json['role'] as String? ?? '',
      preferredLanguage: json['preferredLanguage'] as String?,
      mustChangePassword: json['mustChangePassword'] as bool? ?? false,
      expiresAt: exp,
      claims: claims is Map<String, dynamic> ? claims : <String, dynamic>{},
    );
  }
}
