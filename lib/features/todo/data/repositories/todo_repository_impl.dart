import '../../domain/entities/todo_entity.dart';
import '../../domain/repositories/todo_repository.dart';
import '../datasources/todo_remote_data_source.dart';

class TodoRepositoryImpl implements TodoRepository {
  final TodoRemoteDataSource remoteDataSource;

  TodoRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<TodoEntity>> getTodos({
    required int page,
    required int limit,
  }) async {
    final models = await remoteDataSource.getTodos(page: page, limit: limit);
    return models; // already TodoEntity (extends)
  }

  @override
  Future<TodoEntity> getTodoDetails(int id) async {
    final model = await remoteDataSource.getTodoDetails(id);
    return model;
  }
}
