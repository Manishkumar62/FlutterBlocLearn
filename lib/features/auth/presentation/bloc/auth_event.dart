import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {} // app start, check tokens

class AuthLoggedIn extends AuthEvent {
  final String accessToken;
  final String refreshToken;
  AuthLoggedIn({required this.accessToken, required this.refreshToken});
  @override
  List<Object?> get props => [accessToken, refreshToken];
}

class AuthLoggedOut extends AuthEvent {}

class AuthRefreshRequested extends AuthEvent {
  // optional: triggered internally when refresh required
  @override
  List<Object?> get props => [];
}

class AuthRefreshSucceeded extends AuthEvent {
  final String accessToken;
  final String refreshToken;
  AuthRefreshSucceeded({required this.accessToken, required this.refreshToken});
  @override
  List<Object?> get props => [accessToken, refreshToken];
}

class AuthRefreshFailed extends AuthEvent {
  final String reason;
  AuthRefreshFailed(this.reason);
  @override
  List<Object?> get props => [reason];
}
