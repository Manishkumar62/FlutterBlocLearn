import '../../data/models/auth_model.dart';
import '../entities/auth_entity.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<AuthEntity> call({
    required String email,
    required String password,
  }) async {
    final AuthModel model = await repository.login(email: email, password: password);
    return AuthEntity(
      accessToken: model.accessToken,
      refreshToken: model.refreshToken,
    );
  }
}
