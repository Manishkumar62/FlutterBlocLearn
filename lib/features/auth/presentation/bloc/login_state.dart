import 'package:equatable/equatable.dart';

enum LoginStatus { initial, submitting, success, failure }

class LoginState extends Equatable {
  final String email;
  final String password;
  final String? emailError;
  final String? passwordError;
  final LoginStatus status;
  final String? errorMessage;

  const LoginState({
    required this.email,
    required this.password,
    this.emailError,
    this.passwordError,
    required this.status,
    this.errorMessage,
  });

  factory LoginState.initial() {
    return const LoginState(
      email: '',
      password: '',
      emailError: null,
      passwordError: null,
      status: LoginStatus.initial,
      errorMessage: null,
    );
  }

  LoginState copyWith({
    String? email,
    String? password,
    String? emailError,
    String? passwordError,
    LoginStatus? status,
    String? errorMessage,
  }) {
    return LoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      emailError: emailError,
      passwordError: passwordError,
      status: status ?? this.status,
      errorMessage: errorMessage,
    );
  }

  bool get isValid => emailError == null && passwordError == null && email.isNotEmpty && password.isNotEmpty;

  @override
  List<Object?> get props => [email, password, emailError, passwordError, status, errorMessage];
}
