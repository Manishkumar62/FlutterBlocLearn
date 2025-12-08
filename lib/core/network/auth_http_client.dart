import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../secure_storage/token_storage.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../core/network/jwt_utils.dart';

/// A BaseClient wrapper that automatically adds Authorization header,
/// detects 401 -> triggers refresh using AuthBloc -> retries request once.
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
    // Clone request body if needed
    final access = await _tokenStorage.readAccessToken();

    if (access != null) {
      // if token is near expiry, request refresh proactively (background)
      if (isTokenExpired(access, graceSeconds: 60)) {
        // trigger refresh but do not wait for it to complete (optimistic)
        unawaited(_authBloc.ensureToken());
      }

      request.headers['Authorization'] = 'Bearer $access';
    }

    http.StreamedResponse response = await _inner.send(request);

    // --- NEW: safety guard to avoid infinite retry loops ---
    final int retryCount = int.tryParse(request.headers['x-retry-count'] ?? '0') ?? 0;

    // If 401 -> try refresh and retry once
    if (response.statusCode == 401) {

      // If already retried once, do NOT attempt refresh again.
      if (retryCount >= 1) {
        // Option A: force logout (safer)
        _authBloc.add(AuthLoggedOut());
        return response; // return original 401
      }


      // Drain body to avoid leak
      final body = await http.Response.fromStream(response);
      final bodyText = body.body;
      // Try to refresh
      final refreshed = await _authBloc.ensureToken();
      if (!refreshed) {
        // refresh failed -> force logout
        _authBloc.add(AuthLoggedOut());
        return response; // original 401
      }

      // read new access token
      final newAccess = await _tokenStorage.readAccessToken();
      if (newAccess == null) {
        _authBloc.add(AuthLoggedOut());
        return response;
      }

      // Recreate the original request to retry
      final newRequest = _copyRequest(request, newAccess);
      return _inner.send(newRequest);
    }

    return response;
  }

  // Helper to copy request with same method, url, headers, body
  http.BaseRequest _copyRequest(http.BaseRequest request, String accessToken) {
    final newRequest = http.Request(request.method, request.url);
    newRequest.headers.addAll(request.headers);

    // increment retry count on clone (important)
    final prev = int.tryParse(newRequest.headers['x-retry-count'] ?? '0') ?? 0;
    newRequest.headers['x-retry-count'] = (prev + 1).toString();
    
    newRequest.headers['Authorization'] = 'Bearer $accessToken';

    if (request is http.Request) {
      newRequest.bodyBytes = request.bodyBytes;
    }
    return newRequest;
  }
}

// simple unawaited helper
void unawaited(Future<dynamic> f) {}
