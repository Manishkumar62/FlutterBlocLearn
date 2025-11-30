import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:rxdart/rxdart.dart';

import '../../../domain/entities/todo_entity.dart';
import '../../../domain/usecases/get_todos_usecase.dart';
import 'todo_list_event.dart';
import 'todo_list_state.dart';

EventTransformer<E> debounce<E>(Duration duration) {
  return (events, mapper) => events.debounceTime(duration).switchMap(mapper);
}

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
    on<TodoListSearchQueryChanged>(
      _onSearchChanged,
      transformer: debounce(const Duration(milliseconds: 300)),
    );
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

      final filtered = _applySearch(todos, state.searchQuery);

      emit(state.copyWith(
        todos: todos,
        filteredTodos: filtered,
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

      final filtered = _applySearch(allTodos, state.searchQuery);

      emit(state.copyWith(
        todos: allTodos,
        filteredTodos: filtered,
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

  List<TodoEntity> _applySearch(List<TodoEntity> todos, String query) {
    if (query.isEmpty) return todos;

    final lower = query.toLowerCase();
    return todos
        .where((t) => t.title.toLowerCase().contains(lower))
        .toList();
  }

  Future<void> _onSearchChanged(
    TodoListSearchQueryChanged event,
    Emitter<TodoListState> emit,
  ) async {
    final query = event.query;
    final filtered = _applySearch(state.todos, query);

    emit(
      state.copyWith(
        searchQuery: query,
        filteredTodos: filtered,
        // keep rest same
      ),
    );
  }

}
