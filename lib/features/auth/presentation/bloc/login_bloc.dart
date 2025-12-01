import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/login_usecase.dart';
import '../../../../core/secure_storage/token_storage.dart';
import 'login_event.dart';
import 'login_state.dart';
import '../../presentation/bloc/auth_bloc.dart';
import '../../presentation/bloc/auth_event.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final LoginUseCase loginUseCase;
  final TokenStorage tokenStorage;
  final AuthBloc authBloc;

  LoginBloc({required this.loginUseCase, required this.tokenStorage, required this.authBloc,})
    : super(LoginState.initial()) {
    on<LoginEmailChanged>(_onEmailChanged);
    on<LoginPasswordChanged>(_onPasswordChanged);
    on<LoginSubmitted>(_onSubmitted);
  }

  void _onEmailChanged(LoginEmailChanged event, Emitter<LoginState> emit) {
    final email = event.email.trim();
    final emailError = _validateEmail(email);
    emit(state.copyWith(email: email, emailError: emailError));
  }

  void _onPasswordChanged(
    LoginPasswordChanged event,
    Emitter<LoginState> emit,
  ) {
    final password = event.password;
    final passwordError = _validatePassword(password);
    emit(state.copyWith(password: password, passwordError: passwordError));
  }

  Future<void> _onSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    // validate again
    final emailError = _validateEmail(state.email);
    final passwordError = _validatePassword(state.password);

    if (emailError != null || passwordError != null) {
      emit(
        state.copyWith(emailError: emailError, passwordError: passwordError),
      );
      return;
    }

    emit(state.copyWith(status: LoginStatus.submitting, errorMessage: null));

    try {
      final auth = await loginUseCase.call(
        email: state.email,
        password: state.password,
      );
      // Save both tokens securely
      await tokenStorage.saveAccessToken(auth.accessToken);
      await tokenStorage.saveRefreshToken(auth.refreshToken);

      // notify global auth state machine:
      authBloc.add(AuthLoggedIn(
        accessToken: auth.accessToken,
        refreshToken: auth.refreshToken,
      ));
      emit(state.copyWith(status: LoginStatus.success));
    } catch (e) {
      emit(
        state.copyWith(status: LoginStatus.failure, errorMessage: e.toString()),
      );
    }
  }

  String? _validateEmail(String email) {
    if (email.isEmpty) return 'Email required';
    final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
    if (!emailRegex.hasMatch(email)) return 'Invalid email';
    return null;
  }

  String? _validatePassword(String password) {
    if (password.isEmpty) return 'Password required';
    if (password.length < 6) return 'Must be at least 6 characters';
    return null;
  }
}
