// lib/core/network/refresh_manager.dart
import 'dart:async';
import 'package:firstassignbloc/core/secure_storage/token_storage.dart';
import 'package:firstassignbloc/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:firstassignbloc/features/auth/domain/usecases/refresh_token_usecase.dart';
import 'package:firstassignbloc/core/network/jwt_utils.dart';
import 'package:firstassignbloc/features/auth/presentation/bloc/auth_event.dart';
import 'package:firstassignbloc/features/auth/data/models/auth_model.dart';

/// RefreshManager ensures only one refresh runs at a time (single-flight).
/// It uses dynamic invocation to be tolerant to small differences in
/// method names/signatures in your existing usecase/storage code.
class RefreshManager {
  final RefreshTokenUseCase _refreshUseCase;
  final TokenStorage _tokenStorage;
  final AuthBloc _authBloc;

  bool _isRefreshing = false;
  Completer<bool>? _completer;

  RefreshManager({
    required RefreshTokenUseCase refreshUseCase,
    required TokenStorage tokenStorage,
    required AuthBloc authBloc,
  }) : _refreshUseCase = refreshUseCase,
       _tokenStorage = tokenStorage,
       _authBloc = authBloc;

  /// Checks token expiry and refreshes if needed. Returns true if there is a valid token after.
  Future<bool> refreshIfNeeded({int graceSeconds = 60}) async {
    final access = await _tokenStorage.readAccessToken();
    if (access == null) return false;
    if (!isTokenExpired(access, graceSeconds: graceSeconds)) {
      return true; // no refresh needed
    }
    return await _doRefresh();
  }

  /// Force a refresh regardless of expiry.
  Future<bool> forceRefresh() async {
    return await _doRefresh();
  }

  Future<bool> _doRefresh() async {
    // single-flight: if currently refreshing, wait for its completion
    if (_isRefreshing) {
      return _completer?.future ?? false;
    }

    _isRefreshing = true;
    _completer = Completer<bool>();

    // DEBUG: log entry
    print('[RefreshManager] _doRefresh() ENTER');

    try {
      final refreshToken = await _tokenStorage.readRefreshToken();
      print('[RefreshManager] readRefreshToken -> $refreshToken');

      if (refreshToken == null || refreshToken.isEmpty) {
        // no refresh token -> trigger logout
        print('[RefreshManager] no refresh token -> logout');
        _authBloc.add(AuthLoggedOut());
        _completer?.complete(false);
        return false;
      }

      // call the refresh usecase using the named parameter (important)
      print('[RefreshManager] calling refreshUseCase.call(refreshToken: ...)');
      final authModel = await _refreshUseCase.call(refreshToken: refreshToken);
      print('[RefreshManager] refreshUseCase returned: $authModel');

      // write tokens to storage using actual TokenStorage API
      print('[RefreshManager] saving tokens to storage');
      await _tokenStorage.saveAccessToken(authModel.accessToken);
      await _tokenStorage.saveRefreshToken(authModel.refreshToken);
      print('[RefreshManager] tokens saved');

      _completer?.complete(true);
      return true;
    } catch (e, st) {
      // refresh failed -> logout & notify waiters
      print('[RefreshManager] Refresh failed: $e\n$st');
      try {
        _authBloc.add(AuthLoggedOut());
      } catch (_) {}
      _completer?.complete(false);
      return false;
    } finally {
      _isRefreshing = false;
      _completer = null;
      print('[RefreshManager] _doRefresh() EXIT');
    }
  }
}
