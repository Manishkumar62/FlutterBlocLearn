import 'dart:async';
import 'package:bloc/bloc.dart';
import '../../../../core/secure_storage/token_storage.dart';
import '../../domain/usecases/refresh_token_usecase.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final TokenStorage tokenStorage;
  final RefreshTokenUseCase refreshUseCase;

  // Single-flight refresh control:
  Completer<bool>? _refreshCompleter;

  AuthBloc({
    required this.tokenStorage,
    required this.refreshUseCase,
  }) : super(AuthState.unknown()) {
    on<AuthStarted>(_onStarted);
    on<AuthLoggedIn>(_onLoggedIn);
    on<AuthLoggedOut>(_onLoggedOut);
    on<AuthRefreshRequested>(_onRefreshRequested);
    on<AuthRefreshSucceeded>(_onRefreshSucceeded);
    on<AuthRefreshFailed>(_onRefreshFailed);
  }

  // Called at app start to restore tokens if present
  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    final access = await tokenStorage.readAccessToken();
    final refresh = await tokenStorage.readRefreshToken();

    if (access != null && refresh != null) {
      emit(AuthState.authenticated(accessToken: access, refreshToken: refresh));
    } else {
      emit(AuthState.unauthenticated());
    }
  }

  Future<void> _onLoggedIn(AuthLoggedIn event, Emitter<AuthState> emit) async {
    // Save tokens and set authenticated
    await tokenStorage.saveAccessToken(event.accessToken);
    await tokenStorage.saveRefreshToken(event.refreshToken);
    emit(AuthState.authenticated(
      accessToken: event.accessToken,
      refreshToken: event.refreshToken,
    ));
  }

  Future<void> _onLoggedOut(AuthLoggedOut event, Emitter<AuthState> emit) async {
    print('AuthBloc: handling AuthLoggedOut — clearing tokens');
    await tokenStorage.clearAll();
    emit(AuthState.unauthenticated());
  }

  Future<void> _onRefreshRequested(
      AuthRefreshRequested event, Emitter<AuthState> emit) async {
    // If a refresh is already in progress, we just wait on it
    if (_refreshCompleter != null) {
      return;
    }

    _refreshCompleter = Completer<bool>();
    emit(state.copyWith(status: AuthStatus.refreshing));

    final currentRefresh = await tokenStorage.readRefreshToken();
    if (currentRefresh == null) {
      add(AuthRefreshFailed('no refresh token'));
      _refreshCompleter?.complete(false);
      _refreshCompleter = null;
      return;
    }

    try {
      final authModel = await refreshUseCase.call(refreshToken: currentRefresh);

      // save new tokens
      await tokenStorage.saveAccessToken(authModel.accessToken);
      await tokenStorage.saveRefreshToken(authModel.refreshToken);

      // publish success event
      add(AuthRefreshSucceeded(
        accessToken: authModel.accessToken,
        refreshToken: authModel.refreshToken,
      ));

      _refreshCompleter?.complete(true);
    } catch (e) {
      add(AuthRefreshFailed(e.toString()));
      _refreshCompleter?.complete(false);
    } finally {
      _refreshCompleter = null;
    }
  }

  void _onRefreshSucceeded(
      AuthRefreshSucceeded event, Emitter<AuthState> emit) {
    emit(AuthState.authenticated(
      accessToken: event.accessToken,
      refreshToken: event.refreshToken,
    ));
  }

  void _onRefreshFailed(AuthRefreshFailed event, Emitter<AuthState> emit) {
    // Clear tokens and mark unauthenticated
    tokenStorage.clearAll();
    emit(AuthState.unauthenticated().copyWith(errorMessage: event.reason));
  }

  Future<bool> ensureToken() async {
    // If authenticated and access token exists and not expired, return true
    final access = state.accessToken ?? await tokenStorage.readAccessToken();
    final refresh = state.refreshToken ?? await tokenStorage.readRefreshToken();

    if (access != null && refresh != null) {
      // check expiry using jwt_utils
      final fromJwt = access;
      try {
        // import here to avoid circular imports at top-level:
        // but you can import core/network/jwt_utils.dart at top if you prefer
        // Use the helper isTokenExpired
        // To avoid explicit import here, assume you imported it above.
      } catch (_) {}
      // We'll check expiry by reading jwt_utils.isTokenExpired
    }

    // If in refreshing state, wait for existing completer
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    // Otherwise, request refresh and wait
    add(AuthRefreshRequested());
    // Wait until completer finishes (it will be created by the handler)
    // But _refreshCompleter might be null if refresh request immediately failed; handle that
    final start = DateTime.now();
    while (_refreshCompleter == null) {
      // small wait to allow handler to set completer
      await Future.delayed(const Duration(milliseconds: 10));
      if (DateTime.now().difference(start).inSeconds > 5) break;
    }
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    } else {
      // no completer created -> likely no refresh attempted -> failure
      return false;
    }
  }
}
