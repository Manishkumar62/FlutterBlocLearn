import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:firstassignbloc/features/todo/domain/usecases/get_todos_usecase.dart';
import 'package:firstassignbloc/features/todo/domain/repositories/todo_repository.dart';
import 'package:firstassignbloc/features/todo/domain/entities/todo_entity.dart';

class MockTodoRepository extends Mock implements TodoRepository {}

void main() {
  late GetTodosUseCase useCase;
  late MockTodoRepository mockRepository;

  setUp(() {
    mockRepository = MockTodoRepository();
    useCase = GetTodosUseCase(mockRepository);
  });

  const page = 1;
  const limit = 20;

  final todos = [
    TodoEntity(id: 1, userId: 101, title: 'Test Todo', completed: false),
  ];

  test('should return list of todos when repository call succeeds', () async {
    // arrange
    when(
      () => mockRepository.getTodos(page: page, limit: limit),
    ).thenAnswer((_) async => todos);

    // act
    final result = await useCase(page: page, limit: limit);

    // assert
    expect(result, todos);
    verify(() => mockRepository.getTodos(page: page, limit: limit)).called(1);
    verifyNoMoreInteractions(mockRepository);
  });

  test('should throw exception when repository call fails', () async {
    // arrange
    when(
      () => mockRepository.getTodos(page: page, limit: limit),
    ).thenThrow(Exception('Server error'));

    // act & assert
    await expectLater(() => useCase(page: page, limit: limit), throwsException);

    verify(() => mockRepository.getTodos(page: page, limit: limit)).called(1);
  });
}
