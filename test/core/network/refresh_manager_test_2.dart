import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:firstassignbloc/core/network/refresh_manager.dart';
import 'package:firstassignbloc/features/auth/domain/usecases/refresh_token_usecase.dart';
import 'package:firstassignbloc/core/secure_storage/token_storage.dart';
import 'package:firstassignbloc/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:firstassignbloc/features/auth/data/models/auth_model.dart';
import 'package:firstassignbloc/features/auth/presentation/bloc/auth_event.dart';

class MockRefreshTokenUseCase extends Mock implements RefreshTokenUseCase {}

class MockTokenStorage extends Mock implements TokenStorage {}

class MockAuthBloc extends Mock implements AuthBloc {}

class FakeAuthEvent extends Fake implements AuthEvent {}

String validJwt({int expiresInSeconds = 3600}) {
  final header = base64Url.encode(utf8.encode('{"alg":"HS256","typ":"JWT"}'));
  final payload = base64Url.encode(
    utf8.encode(
      '{"exp": ${(DateTime.now().millisecondsSinceEpoch ~/ 1000) + expiresInSeconds}}',
    ),
  );
  return '$header.$payload.signature';
}


void main() {
  setUpAll(() {
    registerFallbackValue(FakeAuthEvent());
  });

  late MockRefreshTokenUseCase refreshUseCase;
  late MockTokenStorage tokenStorage;
  late MockAuthBloc authBloc;
  late RefreshManager refreshManager;

  setUp(() {
    refreshUseCase = MockRefreshTokenUseCase();
    tokenStorage = MockTokenStorage();
    authBloc = MockAuthBloc();

    refreshManager = RefreshManager(
      refreshUseCase: refreshUseCase,
      tokenStorage: tokenStorage,
      authBloc: authBloc,
    );
  });

  test(
    'single-flight: multiple refresh calls trigger only one refresh',
    () async {
      // arrange
      when(
        () => tokenStorage.readAccessToken(),
      ).thenAnswer((_) async => 'expired-token');

      when(
        () => tokenStorage.readRefreshToken(),
      ).thenAnswer((_) async => 'refresh-token');

      when(
        () => refreshUseCase.call(refreshToken: any(named: 'refreshToken')),
      ).thenAnswer((_) async {
        // simulate network delay
        await Future.delayed(const Duration(milliseconds: 100));
        return AuthModel(
          accessToken: 'new-access',
          refreshToken: 'new-refresh',
        );
      });

      when(() => tokenStorage.saveAccessToken(any())).thenAnswer((_) async {});
      when(() => tokenStorage.saveRefreshToken(any())).thenAnswer((_) async {});

      // act: fire multiple concurrent refresh calls
      final results = await Future.wait([
        refreshManager.forceRefresh(),
        refreshManager.forceRefresh(),
        refreshManager.forceRefresh(),
      ]);

      // assert
      expect(results, [true, true, true]);

      verify(
        () => refreshUseCase.call(refreshToken: 'refresh-token'),
      ).called(1); // 🔥 ONLY ONE CALL

      verifyNever(() => authBloc.add(any<AuthEvent>()));
    },
  );

  test('refresh failure triggers logout and returns false', () async {
    // arrange
    when(
      () => tokenStorage.readAccessToken(),
    ).thenAnswer((_) async => 'expired-token');

    when(
      () => tokenStorage.readRefreshToken(),
    ).thenAnswer((_) async => 'refresh-token');

    when(
      () => refreshUseCase.call(refreshToken: any(named: 'refreshToken')),
    ).thenThrow(Exception('Refresh failed'));

    // act
    final result = await refreshManager.forceRefresh();

    // assert
    expect(result, false);
    verify(() => authBloc.add(any<AuthEvent>())).called(1);
  });

  test('returns true without refresh when token is still valid', () async {
    // arrange
    when(
      () => tokenStorage.readAccessToken(),
    ).thenAnswer((_) async => validJwt());

    // act
    final result = await refreshManager.refreshIfNeeded();

    // assert
    expect(result, true);
    verifyNever(
      () => refreshUseCase.call(refreshToken: any(named: 'refreshToken')),
    );
  });
}
