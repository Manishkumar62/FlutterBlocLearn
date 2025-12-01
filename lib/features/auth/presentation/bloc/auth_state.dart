import 'package:equatable/equatable.dart';

enum AuthStatus { unknown, authenticated, unauthenticated, refreshing }

class AuthState extends Equatable {
  final AuthStatus status;
  final String? accessToken;
  final String? refreshToken;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.accessToken,
    this.refreshToken,
    this.errorMessage,
  });

  factory AuthState.unknown() => const AuthState(status: AuthStatus.unknown);

  factory AuthState.unauthenticated() =>
      const AuthState(status: AuthStatus.unauthenticated);

  factory AuthState.authenticated({
    required String accessToken,
    required String refreshToken,
  }) =>
      AuthState(
          status: AuthStatus.authenticated,
          accessToken: accessToken,
          refreshToken: refreshToken);

  AuthState copyWith({
    AuthStatus? status,
    String? accessToken,
    String? refreshToken,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, accessToken, refreshToken, errorMessage];
}
