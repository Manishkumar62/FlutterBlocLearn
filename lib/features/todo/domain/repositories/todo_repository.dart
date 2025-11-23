import '../entities/todo_entity.dart';

abstract class TodoRepository {
  Future<List<TodoEntity>> getTodos({
    required int page,
    required int limit,
  });

  Future<TodoEntity> getTodoDetails(int id);
}
