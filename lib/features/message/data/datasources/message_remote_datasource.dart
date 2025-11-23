import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message_model.dart';
import '../../../../core/error/exceptions.dart';

abstract class MessageRemoteDataSource {
  /// Throws [ServerException] or [NetworkException] on error
  Future<MessageModel> getMessage();
}

class MessageRemoteDataSourceImpl implements MessageRemoteDataSource {
  final http.Client client;

  MessageRemoteDataSourceImpl({required this.client});

  @override
  Future<MessageModel> getMessage() async {
    try {
      // Example public API that returns a random quote:
      final uri = Uri.parse('https://jsonplaceholder.typicode.com/todos/1');
      final response = await client.get(uri);

      if (response.statusCode == 200) {
        final Map<String, dynamic> decoded = jsonDecode(response.body);
        // JSONPlaceholder's TODO object has "title" field — MessageModel.fromJson handles it
        return MessageModel.fromJson(decoded);
      } else {
        throw ServerException(
            'Failed to load message. Status code: ${response.statusCode}');
      }
    } on http.ClientException catch (e) {
      throw NetworkException(e.message);
    } catch (e) {
      // For unexpected errors
      throw ServerException(e.toString());
    }
  }
}
