import '../repositories/auth_repository.dart';
import '../../data/models/auth_model.dart';

class RefreshTokenUseCase {
  final AuthRepository repository;

  RefreshTokenUseCase(this.repository);

  Future<AuthModel> call({required String refreshToken}) {
    return repository.refresh(refreshToken: refreshToken);
  }
}
