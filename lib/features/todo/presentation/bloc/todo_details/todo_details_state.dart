import 'package:equatable/equatable.dart';

import '../../../domain/entities/todo_entity.dart';

class TodoDetailsState extends Equatable {
  final bool isLoading;
  final TodoEntity? todo;
  final String? errorMessage;

  const TodoDetailsState({
    required this.isLoading,
    this.todo,
    this.errorMessage,
  });

  factory TodoDetailsState.initial() {
    return const TodoDetailsState(
      isLoading: true,
      todo: null,
      errorMessage: null,
    );
  }

  TodoDetailsState copyWith({
    bool? isLoading,
    TodoEntity? todo,
    String? errorMessage,
  }) {
    return TodoDetailsState(
      isLoading: isLoading ?? this.isLoading,
      todo: todo ?? this.todo,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [isLoading, todo, errorMessage];
}
