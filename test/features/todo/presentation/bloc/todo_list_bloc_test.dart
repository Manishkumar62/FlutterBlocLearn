import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:firstassignbloc/features/todo/domain/entities/todo_entity.dart';
import 'package:firstassignbloc/features/todo/domain/usecases/get_todos_usecase.dart';
import 'package:firstassignbloc/features/todo/presentation/bloc/todo_list/todo_list_bloc.dart';
import 'package:firstassignbloc/features/todo/presentation/bloc/todo_list/todo_list_event.dart';
import 'package:firstassignbloc/features/todo/presentation/bloc/todo_list/todo_list_state.dart';

class MockGetTodosUseCase extends Mock implements GetTodosUseCase {}

void main() {
  late MockGetTodosUseCase mockGetTodosUseCase;

  setUp(() {
    mockGetTodosUseCase = MockGetTodosUseCase();
  });

  final todos = [
    TodoEntity(
      id: 1,
      userId: 101,
      title: 'Learn Bloc Testing',
      completed: false,
    ),
  ];

  final moreTodos = [
    TodoEntity(id: 2, userId: 101, title: 'Second Todo', completed: false),
  ];

  final searchTodos = [
    TodoEntity(
      id: 1,
      userId: 101,
      title: 'Learn Bloc Testing',
      completed: false,
    ),
    TodoEntity(id: 2, userId: 101, title: 'Write unit tests', completed: false),
  ];

  blocTest<TodoListBloc, TodoListState>(
    'emits loading then loaded state when TodoListFetched succeeds',
    build: () {
      when(
        () => mockGetTodosUseCase(page: 1, limit: 20),
      ).thenAnswer((_) async => todos);

      return TodoListBloc(getTodosUseCase: mockGetTodosUseCase);
    },
    act: (bloc) => bloc.add(TodoListFetched()),
    expect:
        () => [
          // loading state
          TodoListState.initial().copyWith(
            isLoading: true,
            isRefreshing: false,
            errorMessage: null,
          ),
          // success state
          TodoListState.initial().copyWith(
            todos: todos,
            filteredTodos: todos,
            isLoading: false,
            isRefreshing: false,
            hasMore: false, // because todos.length != limit
          ),
        ],
    verify: (_) {
      verify(() => mockGetTodosUseCase(page: 1, limit: 20)).called(1);
    },
  );

  blocTest<TodoListBloc, TodoListState>(
    'emits loading then error state when TodoListFetched fails',
    build: () {
      when(
        () => mockGetTodosUseCase(page: 1, limit: 20),
      ).thenThrow(Exception('Server error'));

      return TodoListBloc(getTodosUseCase: mockGetTodosUseCase);
    },
    act: (bloc) => bloc.add(TodoListFetched()),
    expect:
        () => [
          // loading state
          TodoListState.initial().copyWith(
            isLoading: true,
            isRefreshing: false,
            errorMessage: null,
          ),

          // error state
          TodoListState.initial().copyWith(
            isLoading: false,
            isRefreshing: false,
            errorMessage: 'Exception: Server error',
          ),
        ],
    verify: (_) {
      verify(() => mockGetTodosUseCase(page: 1, limit: 20)).called(1);
    },
  );

  blocTest<TodoListBloc, TodoListState>(
    'appends todos when TodoListLoadMore succeeds',
    build: () {
      when(
        () => mockGetTodosUseCase(page: 2, limit: 20),
      ).thenAnswer((_) async => moreTodos);

      return TodoListBloc(getTodosUseCase: mockGetTodosUseCase);
    },
    seed:
        () => TodoListState.initial().copyWith(
          todos: todos,
          filteredTodos: todos,
          hasMore: true,
        ),
    act: (bloc) => bloc.add(TodoListLoadMore()),
    expect:
        () => [
          // loading more
          TodoListState.initial().copyWith(
            todos: todos,
            filteredTodos: todos,
            hasMore: true,
            isLoadingMore: true,
          ),

          // appended result
          TodoListState.initial().copyWith(
            todos: [...todos, ...moreTodos],
            filteredTodos: [...todos, ...moreTodos],
            isLoadingMore: false,
            hasMore: false, // because moreTodos.length != limit
          ),
        ],
    verify: (_) {
      verify(() => mockGetTodosUseCase(page: 2, limit: 20)).called(1);
    },
  );

  blocTest<TodoListBloc, TodoListState>(
    'filters todos when search query changes',
    build: () => TodoListBloc(getTodosUseCase: mockGetTodosUseCase),
    seed:
        () => TodoListState.initial().copyWith(
          todos: searchTodos,
          filteredTodos: searchTodos,
        ),
    act: (bloc) => bloc.add(const TodoListSearchQueryChanged('bloc')),
    wait: const Duration(milliseconds: 300),
    expect:
        () => [
          TodoListState.initial().copyWith(
            todos: searchTodos,
            filteredTodos: [
              searchTodos[0], // only matching item
            ],
            searchQuery: 'bloc',
          ),
        ],
  );
}
