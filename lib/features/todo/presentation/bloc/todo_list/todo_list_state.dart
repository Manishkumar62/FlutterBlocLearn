import 'package:equatable/equatable.dart';

import '../../../domain/entities/todo_entity.dart';

class TodoListState extends Equatable {
  final List<TodoEntity> todos;
  final List<TodoEntity> filteredTodos;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isRefreshing;
  final bool hasMore;
  final String searchQuery;
  final String? errorMessage;

  const TodoListState({
    required this.todos,
    required this.filteredTodos,
    required this.isLoading,
    required this.isLoadingMore,
    required this.isRefreshing,
    required this.hasMore,
    required this.searchQuery,
    this.errorMessage,
  });

  factory TodoListState.initial() {
    return const TodoListState(
      todos: [],
      filteredTodos: [],
      isLoading: false,
      isLoadingMore: false,
      isRefreshing: false,
      hasMore: true,
      searchQuery: '',
      errorMessage: null,
    );
  }

  TodoListState copyWith({
    List<TodoEntity>? todos,
    List<TodoEntity>? filteredTodos,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isRefreshing,
    bool? hasMore,
    String? searchQuery,
    String? errorMessage,
  }) {
    return TodoListState(
      todos: todos ?? this.todos,
      filteredTodos: filteredTodos ?? this.filteredTodos,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      hasMore: hasMore ?? this.hasMore,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    todos,
    filteredTodos,
    isLoading,
    isLoadingMore,
    isRefreshing,
    hasMore,
    searchQuery,
    errorMessage,
  ];
}
