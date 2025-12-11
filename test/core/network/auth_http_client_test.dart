// test/core/network/auth_http_client_test.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:firstassignbloc/core/network/auth_http_client.dart';
import 'package:firstassignbloc/core/network/refresh_manager.dart';
import 'package:firstassignbloc/core/secure_storage/token_storage.dart';
import 'package:firstassignbloc/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:firstassignbloc/features/auth/presentation/bloc/auth_event.dart';

// Mocks
class MockHttpClient extends Mock implements http.Client {}
class MockTokenStorage extends Mock implements TokenStorage {}
class MockAuthBloc extends Mock implements AuthBloc {}
class MockRefreshManager extends Mock implements RefreshManager {}

// Fallbacks for mocktail
class FakeBaseRequest extends Fake implements http.BaseRequest {}
class FakeAuthEvent extends Fake implements AuthEvent {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeBaseRequest());
    registerFallbackValue(FakeAuthEvent());
  });

  late MockHttpClient inner;
  late MockTokenStorage tokenStorage;
  late MockAuthBloc authBloc;
  late MockRefreshManager refreshManager;
  late AuthHttpClient client;

  setUp(() {
    inner = MockHttpClient();
    tokenStorage = MockTokenStorage();
    authBloc = MockAuthBloc();
    refreshManager = MockRefreshManager();

    // Default: make refreshManager methods return safely (avoid null)
    when(() => refreshManager.refreshIfNeeded()).thenAnswer((_) async => true);
    when(() => refreshManager.forceRefresh()).thenAnswer((_) async => true);

    // Also stub token storage write methods so future awaits don't fail when refresh manager writes
    when(() => tokenStorage.saveAccessToken(any())).thenAnswer((_) async {});
    when(() => tokenStorage.saveRefreshToken(any())).thenAnswer((_) async {});

    client = AuthHttpClient(
      inner: inner,
      tokenStorage: tokenStorage,
      authBloc: authBloc,
      refreshManager: refreshManager,
    );
  });

  test('succeeds when access token present and request returns 200', () async {
    when(() => tokenStorage.readAccessToken()).thenAnswer((_) async => 'valid-access');
    // ensure jwt_utils.isTokenExpired will treat 'valid-access' as not expired in test context.
    final streamed = http.StreamedResponse(Stream.fromIterable([utf8.encode('ok')]), 200);
    when(() => inner.send(any())).thenAnswer((_) async => streamed);

    final req = http.Request('GET', Uri.parse('https://example.com/test'));
    final resp = await client.send(req);

    expect(resp.statusCode, 200);
    verify(() => inner.send(any())).called(greaterThanOrEqualTo(1));
  });

  test('on 401 triggers refresh and retries once (success path)', () async {
    // initial access invalid
    when(() => tokenStorage.readAccessToken()).thenAnswer((_) async => 'expired-access');

    // inner: first call returns 401, second call returns 200
    final resp401 = http.StreamedResponse(Stream.fromIterable([utf8.encode('unauth')]), 401);
    final resp200 = http.StreamedResponse(Stream.fromIterable([utf8.encode('ok')]), 200);

    var call = 0;
    final captured = <http.BaseRequest>[];
    when(() => inner.send(any())).thenAnswer((inv) async {
      final arg = inv.positionalArguments.first as http.BaseRequest;
      captured.add(arg);
      call++;
      return call == 1 ? resp401 : resp200;
    });

    // refreshManager.forceRefresh() should be invoked and return true (simulate refresh succeeded)
    when(() => refreshManager.forceRefresh()).thenAnswer((_) async => true);

    // After refresh, tokenStorage returns new token
    when(() => tokenStorage.readAccessToken()).thenAnswer((_) async => 'new-access');

    final req = http.Request('GET', Uri.parse('https://example.com/test'));
    final res = await client.send(req);

    expect(res.statusCode, 200);
    verify(() => refreshManager.forceRefresh()).called(greaterThanOrEqualTo(1));
    verify(() => inner.send(any())).called(greaterThanOrEqualTo(2));

    if (captured.length >= 2) {
      expect(captured[1].headers['Authorization'], contains('new-access'));
    }
  });

  test('on 401 and refresh fails triggers logout', () async {
    when(() => tokenStorage.readAccessToken()).thenAnswer((_) async => 'expired-access');
    final resp401 = http.StreamedResponse(Stream.fromIterable([utf8.encode('unauth')]), 401);
    when(() => inner.send(any())).thenAnswer((_) async => resp401);

    when(() => refreshManager.forceRefresh()).thenAnswer((_) async => false);

    final req = http.Request('GET', Uri.parse('https://example.com/test'));
    final res = await client.send(req);

    expect(res.statusCode, 401);
    verify(() => refreshManager.forceRefresh()).called(greaterThanOrEqualTo(1));
    verify(() => authBloc.add(any())).called(greaterThanOrEqualTo(1));
  });
}
