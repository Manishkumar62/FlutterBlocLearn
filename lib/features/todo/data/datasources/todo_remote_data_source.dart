// features/todo/data/datasources/todo_remote_data_source.dart

import 'package:http/http.dart' as http;
import 'dart:convert';

import '../models/todo_model.dart';

abstract class TodoRemoteDataSource {
  Future<List<TodoModel>> getTodos({
    required int page,
    required int limit,
  });

  Future<TodoModel> getTodoDetails(int id);
}

class TodoRemoteDataSourceImpl implements TodoRemoteDataSource {
  final http.Client client;

  TodoRemoteDataSourceImpl({required this.client});

  static const _baseUrl = 'https://jsonplaceholder.typicode.com';

  @override
  Future<List<TodoModel>> getTodos({
    required int page,
    required int limit,
  }) async {
    final start = (page - 1) * limit;

    final uri = Uri.parse('$_baseUrl/todos').replace(
      queryParameters: {
        '_start': '$start',
        '_limit': '$limit',
      },
    );

    final response = await client.get(uri);
    final data = jsonDecode(response.body) as List;

    return data.map((json) => TodoModel.fromJson(json)).toList();
  }

  @override
  Future<TodoModel> getTodoDetails(int id) async {
    final uri = Uri.parse('$_baseUrl/todos/$id');
    final response = await client.get(uri);
    final data = jsonDecode(response.body);
    return TodoModel.fromJson(data);
  }
}
