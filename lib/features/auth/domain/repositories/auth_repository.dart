import '../../data/models/auth_model.dart';

abstract class AuthRepository {
  Future<AuthModel> login({
    required String email,
    required String password,
  });

  Future<AuthModel> refresh({
    required String refreshToken,
  });
}
