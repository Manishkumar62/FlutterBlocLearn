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


// Search query changed
class TodoListSearchQueryChanged extends TodoListEvent {
  final String query;
  const TodoListSearchQueryChanged(this.query);

  @override
  List<Object?> get props => [query];
}