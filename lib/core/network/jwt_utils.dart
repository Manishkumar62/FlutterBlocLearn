import 'dart:convert';

/// Decode JWT payload and return map. Returns null on malformed token.
Map<String, dynamic>? decodeJwtPayload(String token) {
  try {
    final parts = token.split('.');
    if (parts.length != 3) return null;
    final payload = base64Url.normalize(parts[1]);
    final decoded = utf8.decode(base64Url.decode(payload));
    return jsonDecode(decoded) as Map<String, dynamic>;
  } catch (_) {
    return null;
  }
}

/// Return expiry epoch seconds from token or null.
int? jwtExpiry(String token) {
  final payload = decodeJwtPayload(token);
  if (payload == null) return null;
  final exp = payload['exp'];
  if (exp is int) return exp;
  if (exp is String) return int.tryParse(exp);
  return null;
}

/// Is token expired (or will expire in `graceSeconds`)?
bool isTokenExpired(String token, {int graceSeconds = 60}) {
  final exp = jwtExpiry(token);
  if (exp == null) return true;
  final now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
  return (exp - now) <= graceSeconds;
}
