// test/core/network/auth_http_client_test.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:firstassignbloc/core/network/auth_http_client.dart';
import 'package:firstassignbloc/core/secure_storage/token_storage.dart';
import 'package:firstassignbloc/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:firstassignbloc/features/auth/presentation/bloc/auth_event.dart';

// Mocks
class MockHttpClient extends Mock implements http.Client {}
class MockTokenStorage extends Mock implements TokenStorage {}
class MockAuthBloc extends Mock implements AuthBloc {}

// Fallback Fake types required by mocktail for any() on non-primitive types
class FakeBaseRequest extends Fake implements http.BaseRequest {}
class FakeAuthEvent extends Fake implements AuthEvent {} // <-- implement AuthEvent

void main() {
  // Register fallback values once for mocktail (before any usage)
  setUpAll(() {
    registerFallbackValue(FakeBaseRequest());
    registerFallbackValue(FakeAuthEvent());
  });

  late MockHttpClient inner;
  late MockTokenStorage tokenStorage;
  late MockAuthBloc authBloc;
  late AuthHttpClient client;

  setUp(() {
    inner = MockHttpClient();
    tokenStorage = MockTokenStorage();
    authBloc = MockAuthBloc();

    // Default stub: ensureToken returns false unless a test overrides it.
    when(() => authBloc.ensureToken()).thenAnswer((_) async => false);

    client = AuthHttpClient(inner: inner, tokenStorage: tokenStorage, authBloc: authBloc);
  });

  test('succeeds when access token present and request returns 200', () async {
    when(() => tokenStorage.readAccessToken()).thenAnswer((_) async => 'valid-access');
    final streamed = http.StreamedResponse(Stream.fromIterable([utf8.encode('ok')]), 200);
    when(() => inner.send(any())).thenAnswer((_) async => streamed);

    final req = http.Request('GET', Uri.parse('https://example.com/test'));
    final resp = await client.send(req);

    expect(resp.statusCode, 200);
    // allow >=1 since the client might attempt proactive refresh in background
    verify(() => inner.send(any())).called(greaterThanOrEqualTo(1));
  });

  test('on 401 triggers refresh and retries once (success path)', () async {
    // initial access invalid
    when(() => tokenStorage.readAccessToken()).thenAnswer((_) async => 'expired-access');

    // inner: first call returns 401, second call returns 200
    final resp401 = http.StreamedResponse(Stream.fromIterable([utf8.encode('unauth')]), 401);
    final resp200 = http.StreamedResponse(Stream.fromIterable([utf8.encode('ok')]), 200);

    // We need to capture the first call, then second call.
    var call = 0;
    final captured = <http.BaseRequest>[];
    when(() => inner.send(any())).thenAnswer((inv) async {
      final arg = inv.positionalArguments.first as http.BaseRequest;
      captured.add(arg);
      call++;
      return call == 1 ? resp401 : resp200;
    });

    // authBloc.ensureToken() should be invoked and return true (simulate refresh succeeded)
    when(() => authBloc.ensureToken()).thenAnswer((_) async => true);

    // After refresh, tokenStorage returns new token
    when(() => tokenStorage.readAccessToken()).thenAnswer((_) async => 'new-access');

    final req = http.Request('GET', Uri.parse('https://example.com/test'));
    final res = await client.send(req);

    expect(res.statusCode, 200);
    // ensureToken should have been called at least once
    verify(() => authBloc.ensureToken()).called(greaterThanOrEqualTo(1));
    // inner.send should have been called at least twice (initial + retry)
    verify(() => inner.send(any())).called(greaterThanOrEqualTo(2));

    // optional: assert that the retried request had x-retry-count == '1'
    if (captured.length >= 2) {
      expect(captured[1].headers['x-retry-count'] == '1' || captured[1].headers.containsKey('x-retry-count'), isTrue);
    }
  });

  test('on 401 and refresh fails triggers logout', () async {
    when(() => tokenStorage.readAccessToken()).thenAnswer((_) async => 'expired-access');
    final resp401 = http.StreamedResponse(Stream.fromIterable([utf8.encode('unauth')]), 401);

    // inner always returns 401
    when(() => inner.send(any())).thenAnswer((_) async => resp401);

    // ensureToken returns false (default), but make explicit for clarity
    when(() => authBloc.ensureToken()).thenAnswer((_) async => false);

    final req = http.Request('GET', Uri.parse('https://example.com/test'));
    final res = await client.send(req);

    // still 401
    expect(res.statusCode, 401);
    verify(() => authBloc.ensureToken()).called(greaterThanOrEqualTo(1));
    // authBloc.add should be called at least once (AuthLoggedOut)
    verify(() => authBloc.add(any())).called(greaterThanOrEqualTo(1));
  });
}
