import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final client = http.Client();
  final uri = Uri.parse('https://reqres.in/api/login');

  final body = jsonEncode({
    'email': 'eve.holt@reqres.in',
    'password': 'cityslicka'
  });

  final resp = await client.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: body,
  );

  print('STATUS: ${resp.statusCode}');
  print('BODY: ${resp.body}');

  client.close();
}
