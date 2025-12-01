import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/auth_model.dart';
import 'auth_remote_datasource.dart';

abstract class AuthRefreshRemoteDataSource {
  Future<AuthModel> refresh({required String refreshToken});
}

class AuthRefreshRemoteDataSourceImpl implements AuthRefreshRemoteDataSource {
  final http.Client client;
  static const _baseUrl = 'https://api.escuelajs.co/api/v1';

  AuthRefreshRemoteDataSourceImpl({required this.client});

  @override
  Future<AuthModel> refresh({required String refreshToken}) async {
    final uri = Uri.parse('$_baseUrl/auth/refresh-token');
    final response = await client.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'refreshToken': refreshToken}),
    );

    if (response.statusCode >= 200 && response.statusCode < 300) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return AuthModel.fromJson(data);
    } else {
      final body = response.body;
      throw Exception('Refresh failed: ${response.statusCode} — $body');
    }
  }
}
