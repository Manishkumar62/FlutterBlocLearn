import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/auth_model.dart';

abstract class AuthRemoteDataSource {
  Future<AuthModel> login({required String email, required String password});
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final http.Client client;

  AuthRemoteDataSourceImpl({required this.client});

  // Using reqres.in test API (for development/testing)
  static const _baseUrl = 'https://api.escuelajs.co/api/v1';

  @override
  Future<AuthModel> login({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$_baseUrl/auth/login');
    print('→ LOGIN REQUEST: $uri');
    print('→ HEADERS: ${{'Content-Type': 'application/json'}}');
    print('→ BODY: ${jsonEncode({'email': email, 'password': password})}');
    final response = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    print('← STATUS: ${response.statusCode}');
    print('← BODY: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return AuthModel.fromJson(data);
    } else {
      // Map other status codes as needed; throw a descriptive error
      final body = response.body;
      throw Exception('Login failed: ${response.statusCode} — $body');
    }
  }
}
