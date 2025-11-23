import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/todo_entity.dart';
import '../../../domain/usecases/get_todos_usecase.dart';
import 'todo_list_event.dart';
import 'todo_list_state.dart';

class TodoListBloc extends Bloc<TodoListEvent, TodoListState> {
  final GetTodosUseCase getTodosUseCase;

  int _currentPage = 1;
  final int _limit = 20;
  bool _isFetching = false;

  TodoListBloc({
    required this.getTodosUseCase,
  }) : super(TodoListState.initial()) {
    on<TodoListFetched>(_onFetched);
    on<TodoListLoadMore>(_onLoadMore);
  }

  Future<void> _onFetched(
    TodoListFetched event,
    Emitter<TodoListState> emit,
  ) async {
    if (_isFetching) return;
    _isFetching = true;

    // First time load vs pull-to-refresh
    final isInitialLoad = state.todos.isEmpty;

    emit(state.copyWith(
      isLoading: isInitialLoad,
      isRefreshing: !isInitialLoad,
      errorMessage: null,
    ));

    try {
      _currentPage = 1;
      final List<TodoEntity> todos = await getTodosUseCase(
        page: _currentPage,
        limit: _limit,
      );

      emit(state.copyWith(
        todos: todos,
        isLoading: false,
        isRefreshing: false,
        hasMore: todos.length == _limit,
        errorMessage: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        isRefreshing: false,
        errorMessage: e.toString(),
      ));
    } finally {
      _isFetching = false;
    }
  }

  Future<void> _onLoadMore(
    TodoListLoadMore event,
    Emitter<TodoListState> emit,
  ) async {
    if (_isFetching) return;
    if (!state.hasMore) return;
    if (state.isLoading || state.isRefreshing || state.isLoadingMore) return;

    _isFetching = true;
    emit(state.copyWith(isLoadingMore: true, errorMessage: null));

    try {
      _currentPage += 1;

      final List<TodoEntity> newTodos = await getTodosUseCase(
        page: _currentPage,
        limit: _limit,
      );

      final allTodos = List<TodoEntity>.from(state.todos)..addAll(newTodos);

      emit(state.copyWith(
        todos: allTodos,
        isLoadingMore: false,
        hasMore: newTodos.length == _limit,
      ));
    } catch (e) {
      // For load more, we don't want to wipe existing list
      emit(state.copyWith(
        isLoadingMore: false,
        errorMessage: e.toString(),
      ));
      _currentPage -= 1; // rollback page
    } finally {
      _isFetching = false;
    }
  }
}
