import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  final FlutterSecureStorage secureStorage;
  static const _accessTokenKey = 'ACCESS_TOKEN';
  static const _refreshTokenKey = 'REFRESH_TOKEN';

  TokenStorage({FlutterSecureStorage? secureStorage})
    : secureStorage = secureStorage ?? const FlutterSecureStorage();

  Future<void> saveAccessToken(String token) =>
      secureStorage.write(key: _accessTokenKey, value: token);

  Future<String?> readAccessToken() =>
      secureStorage.read(key: _accessTokenKey);

  Future<void> deleteAccessToken() =>
      secureStorage.delete(key: _accessTokenKey);

  // Optional refresh token helpers
  Future<void> saveRefreshToken(String token) =>
      secureStorage.write(key: _refreshTokenKey, value: token);

  Future<String?> readRefreshToken() =>
      secureStorage.read(key: _refreshTokenKey);

  Future<void> deleteRefreshToken() =>
      secureStorage.delete(key: _refreshTokenKey);

  Future<void> clearAll() => secureStorage.deleteAll();
}
