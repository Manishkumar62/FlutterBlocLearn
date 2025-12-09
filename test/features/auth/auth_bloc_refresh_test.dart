// test/features/auth/auth_bloc_refresh_test.dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:firstassignbloc/core/network/jwt_utils.dart';

/// Helper to create a dummy JWT with an `exp` claim (no signature verification).
String makeJwtWithExp(int epochSeconds) {
  final header = base64Url.encode(utf8.encode(jsonEncode({'alg': 'none', 'typ': 'JWT'})))
    .replaceAll('=', '');
  final payload = base64Url.encode(utf8.encode(jsonEncode({'exp': epochSeconds})))
    .replaceAll('=', '');
  // signature can be empty for this util (it just decodes)
  return '$header.$payload.';
}

void main() {
  test('isTokenExpired returns false when token exp is in future', () {
    final future = DateTime.now().add(Duration(minutes: 10)).toUtc();
    final epoch = (future.millisecondsSinceEpoch / 1000).round();
    final token = makeJwtWithExp(epoch);

    // Should not be expired (with default or 60s grace)
    final expired = isTokenExpired(token, graceSeconds: 60);
    expect(expired, isFalse);
  });

  test('isTokenExpired returns true when token exp is in past', () {
    final past = DateTime.now().subtract(Duration(minutes: 10)).toUtc();
    final epochPast = (past.millisecondsSinceEpoch / 1000).round();
    final tokenPast = makeJwtWithExp(epochPast);

    final expired = isTokenExpired(tokenPast, graceSeconds: 0);
    expect(expired, isTrue);
  });
}
