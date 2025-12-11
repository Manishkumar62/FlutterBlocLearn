// lib/core/network/auth_http_client.dart
import 'dart:async';
import 'package:http/http.dart' as http;
import '../secure_storage/token_storage.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../core/network/jwt_utils.dart';
import '../network/refresh_manager.dart'; // <-- new

/// AuthHttpClient: adds Authorization header and integrates RefreshManager
class AuthHttpClient extends http.BaseClient {
  final http.Client _inner;
  final TokenStorage _tokenStorage;
  final AuthBloc _authBloc;
  final RefreshManager _refreshManager; // new dependency

  AuthHttpClient({
    required http.Client inner,
    required TokenStorage tokenStorage,
    required AuthBloc authBloc,
    required RefreshManager refreshManager,
  })  : _inner = inner,
        _tokenStorage = tokenStorage,
        _authBloc = authBloc,
        _refreshManager = refreshManager;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Read current access token
    var access = await _tokenStorage.readAccessToken();

    if (access != null) {
      // If access is near expiry, BLOCK and refresh so the request uses fresh token.
      // This avoids an immediate 401 and makes UX seamless.
      final needsRefresh = isTokenExpired(access, graceSeconds: 60);
      if (needsRefresh) {
        final refreshed = await _refreshManager.refreshIfNeeded(graceSeconds: 60);
        if (!refreshed) {
          // refresh failed -> logout already triggered by manager
          // return a synthetic 401 response or let the server decide.
          // We'll attempt to continue and let server respond; but header won't contain Authorization.
        } else {
          // read updated access
          access = await _tokenStorage.readAccessToken();
        }
      }
      if (access != null) {
        request.headers['Authorization'] = 'Bearer $access';
      }
    }

    // Read current retry-count (custom header). Default 0.
    final int retryCount = int.tryParse(request.headers['x-retry-count'] ?? '0') ?? 0;

    final response = await _inner.send(request);

    // If server responds 401, attempt refresh + one retry (only once)
    if (response.statusCode == 401) {
      // If we've already retried once, do not retry again (avoid loops)
      if (retryCount >= 1) {
        _authBloc.add(AuthLoggedOut());
        return response;
      }

      // Drain original response to avoid stream leak
      await http.Response.fromStream(response);

      // Force refresh (single-flight ensured by manager)
      final refreshed = await _refreshManager.forceRefresh();
      if (!refreshed) {
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
    } else if (request is http.MultipartRequest) {
      final m = http.MultipartRequest(request.method, request.url);
      m.headers.addAll(request.headers);
      m.fields.addAll(request.fields);
      m.files.addAll(request.files);
      final prev = int.tryParse(m.headers['x-retry-count'] ?? '0') ?? 0;
      m.headers['x-retry-count'] = (prev + 1).toString();
      m.headers['Authorization'] = 'Bearer $accessToken';
      return m;
    }

    return newRequest;
  }
}
