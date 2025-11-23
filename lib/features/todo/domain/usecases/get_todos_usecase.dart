import '../entities/todo_entity.dart';
import '../repositories/todo_repository.dart';

class GetTodosUseCase {
  final TodoRepository repository;

  GetTodosUseCase(this.repository);

  Future<List<TodoEntity>> call({
    required int page,
    required int limit,
  }) {
    return repository.getTodos(page: page, limit: limit);
  }
}
