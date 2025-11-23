import '../entities/todo_entity.dart';
import '../repositories/todo_repository.dart';

class GetTodoDetailsUseCase {
  final TodoRepository repository;

  GetTodoDetailsUseCase(this.repository);

  Future<TodoEntity> call(int id) {
    return repository.getTodoDetails(id);
  }
}
