import 'package:equatable/equatable.dart';

abstract class TodoListEvent extends Equatable {
  const TodoListEvent();

  @override
  List<Object?> get props => [];
}

// First load or refresh
class TodoListFetched extends TodoListEvent {
  const TodoListFetched();
}

// Pagination - load next page
class TodoListLoadMore extends TodoListEvent {
  const TodoListLoadMore();
}
