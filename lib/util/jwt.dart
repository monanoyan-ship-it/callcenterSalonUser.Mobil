import 'dart:convert';

/// Saf JWT body decode (signature doğrulamaz — backend zaten doğrular).
/// Token expire kontrolü ve role/permission claim okuma için.
Map<String, dynamic>? decodeJwtPayload(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    final body = parts[1];
    final padded = body + '=' * ((4 - body.length % 4) % 4);
    final bytes = base64Url.decode(padded);
    final decoded = utf8.decode(bytes);
    final json = jsonDecode(decoded);
    if (json is Map<String, dynamic>) return json;
    return null;
  } catch (_) {
    return null;
  }
}

/// Token expire mı (DateTime karşılaştırması; backend `expiresAt` daha güvenilir
/// ama JWT exp claim'i de fallback olarak kullanılabilir).
bool isJwtExpired(String token, {Duration tolerance = const Duration(seconds: 30)}) {
  final payload = decodeJwtPayload(token);
  final exp = payload?['exp'];
  if (exp is! int) return false;
  final expiresAt = DateTime.fromMillisecondsSinceEpoch(exp * 1000, isUtc: true);
  return DateTime.now().toUtc().isAfter(expiresAt.subtract(tolerance));
}
