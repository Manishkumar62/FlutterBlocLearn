import 'package:equatable/equatable.dart';

import '../../../domain/entities/todo_entity.dart';

class TodoListState extends Equatable {
  final List<TodoEntity> todos;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isRefreshing;
  final bool hasMore;
  final String? errorMessage;

  const TodoListState({
    required this.todos,
    required this.isLoading,
    required this.isLoadingMore,
    required this.isRefreshing,
    required this.hasMore,
    this.errorMessage,
  });

  factory TodoListState.initial() {
    return const TodoListState(
      todos: [],
      isLoading: false,
      isLoadingMore: false,
      isRefreshing: false,
      hasMore: true,
      errorMessage: null,
    );
  }

  TodoListState copyWith({
    List<TodoEntity>? todos,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isRefreshing,
    bool? hasMore,
    String? errorMessage,
  }) {
    return TodoListState(
      todos: todos ?? this.todos,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [todos, isLoading, isLoadingMore, isRefreshing, hasMore, errorMessage];
}
