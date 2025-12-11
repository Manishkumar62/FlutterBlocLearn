// test/core/network/refresh_manager_test.dart
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firstassignbloc/core/network/refresh_manager.dart';
import 'package:firstassignbloc/core/secure_storage/token_storage.dart';
import 'package:firstassignbloc/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:firstassignbloc/features/auth/domain/usecases/refresh_token_usecase.dart';
import 'package:firstassignbloc/features/auth/data/models/auth_model.dart';
import 'package:firstassignbloc/features/auth/presentation/bloc/auth_event.dart';

// Mocks
class _MockRefreshUseCase extends Mock implements RefreshTokenUseCase {}
class _MockTokenStorage extends Mock implements TokenStorage {}
class _MockAuthBloc extends Mock implements AuthBloc {}

// Fallback for AuthEvent (required by mocktail when matching any() for authBloc.add)
class FakeAuthEvent extends Fake implements AuthEvent {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeAuthEvent());
  });

  late _MockRefreshUseCase mockUseCase;
  late _MockTokenStorage mockStorage;
  late _MockAuthBloc mockAuthBloc;
  late RefreshManager manager;

  setUp(() {
    mockUseCase = _MockRefreshUseCase();
    mockStorage = _MockTokenStorage();
    mockAuthBloc = _MockAuthBloc();

    // Ensure token storage write methods don't throw
    when(() => mockStorage.saveAccessToken(any())).thenAnswer((_) async {});
    when(() => mockStorage.saveRefreshToken(any())).thenAnswer((_) async {});

    manager = RefreshManager(
      refreshUseCase: mockUseCase,
      tokenStorage: mockStorage,
      authBloc: mockAuthBloc,
    );
  });

  test('single-flight: concurrent forceRefresh calls call usecase only once', () async {
    // arrange: make storage return a refresh token
    when(() => mockStorage.readRefreshToken()).thenAnswer((_) async => 'refresh-token');

    // stub usecase to return an AuthModel after a delay (named parameter)
    when(() => mockUseCase.call(refreshToken: any(named: 'refreshToken')))
        .thenAnswer((_) async {
      await Future.delayed(const Duration(milliseconds: 50));

      // Provide a robust JSON with multiple key variants so AuthModel.fromJson won't miss fields.
      final payload = {
        'accessToken': 'new-access',
        'refreshToken': 'new-refresh',
        'access_token': 'new-access',
        'refresh_token': 'new-refresh',
        // sometimes models expect nested structure — include common extras
        'token': 'new-access',
        'refresh': 'new-refresh',
      };

      return AuthModel.fromJson(payload);
    });

    // act: call forceRefresh() concurrently multiple times
    final futures = List.generate(5, (_) => manager.forceRefresh());
    final results = await Future.wait(futures);

    // assert: all callers got true, and usecase called only once (with refresh-token)
    expect(results, everyElement(isTrue));
    verify(() => mockUseCase.call(refreshToken: 'refresh-token')).called(1);
  });

  test('refresh failure triggers logout and returns false to callers', () async {
    // arrange
    when(() => mockStorage.readRefreshToken()).thenAnswer((_) async => 'refresh-token');
    when(() => mockUseCase.call(refreshToken: any(named: 'refreshToken')))
        .thenThrow(Exception('server error'));

    // act
    final res = await manager.forceRefresh();

    // assert
    expect(res, isFalse);
    verify(() => mockUseCase.call(refreshToken: 'refresh-token')).called(1);
    // authBloc.add(AuthLoggedOut()) should be called at least once
    verify(() => mockAuthBloc.add(any())).called(greaterThanOrEqualTo(1));
  });
}
