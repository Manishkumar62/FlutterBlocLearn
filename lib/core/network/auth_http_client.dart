// lib/core/network/auth_http_client.dart
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../secure_storage/token_storage.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../core/network/jwt_utils.dart';

/// AuthHttpClient: adds Authorization header, proactively triggers refresh
/// when access near-expiry, and on 401 attempts one refresh+retry then stops.
class AuthHttpClient extends http.BaseClient {
  final http.Client _inner;
  final TokenStorage _tokenStorage;
  final AuthBloc _authBloc;

  AuthHttpClient({
    required http.Client inner,
    required TokenStorage tokenStorage,
    required AuthBloc authBloc,
  })  : _inner = inner,
        _tokenStorage = tokenStorage,
        _authBloc = authBloc;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Read current access token
    final access = await _tokenStorage.readAccessToken();

    if (access != null) {
      // If access is near expiry, trigger background refresh (optimistic)
      if (isTokenExpired(access, graceSeconds: 60)) {
        // unawaited background ensureToken so we don't block every request
        _unawaited(_authBloc.ensureToken());
      }
      request.headers['Authorization'] = 'Bearer $access';
    }

    // Read current retry-count (custom header). Default 0.
    final int retryCount = int.tryParse(request.headers['x-retry-count'] ?? '0') ?? 0;

    final response = await _inner.send(request);

    // If server responds 401, attempt refresh + one retry (only once)
    if (response.statusCode == 401) {
      // If we've already retried once, do not retry again (avoid loops)
      if (retryCount >= 1) {
        // safer to force logout so app doesn't loop forever
        _authBloc.add(AuthLoggedOut());
        return response;
      }

      // Drain original response to avoid stream leak
      await http.Response.fromStream(response);

      // Try to refresh token
      final refreshed = await _authBloc.ensureToken();
      if (!refreshed) {
        // refresh failed -> force logout
        _authBloc.add(AuthLoggedOut());
        return response;
      }

      // Get new access token
      final newAccess = await _tokenStorage.readAccessToken();
      if (newAccess == null) {
        _authBloc.add(AuthLoggedOut());
        return response;
      }

      // Recreate original request and increment retry count
      final newRequest = _copyRequestWithRetry(request, newAccess, retryCount + 1);
      return _inner.send(newRequest);
    }

    return response;
  }

  // Clone request (method, url, headers, body) and set Authorization + retry header
  http.BaseRequest _copyRequestWithRetry(http.BaseRequest request, String accessToken, int newRetryCount) {
    final newRequest = http.Request(request.method, request.url);

    // copy headers, then overwrite Authorization and x-retry-count
    newRequest.headers.addAll(request.headers);
    newRequest.headers['Authorization'] = 'Bearer $accessToken';
    newRequest.headers['x-retry-count'] = '$newRetryCount';

    if (request is http.Request) {
      newRequest.bodyBytes = request.bodyBytes;
    }

    return newRequest;
  }
}

// Helper to fire-and-forget Futures (avoid returning Null)
void _unawaited(Future<dynamic> f) {}
