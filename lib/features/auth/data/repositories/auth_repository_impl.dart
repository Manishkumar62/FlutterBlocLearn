import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../datasources/auth_refresh_datasource.dart';
import '../models/auth_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthRefreshRemoteDataSource refreshRemoteDataSource;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.refreshRemoteDataSource,
  });

  @override
  Future<AuthModel> login({required String email, required String password}) {
    return remoteDataSource.login(email: email, password: password);
  }

  @override
  Future<AuthModel> refresh({required String refreshToken}) {
    return refreshRemoteDataSource.refresh(refreshToken: refreshToken);
  }
}
