import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/usecases/get_todo_details_usecase.dart';
import 'todo_details_event.dart';
import 'todo_details_state.dart';

class TodoDetailsBloc extends Bloc<TodoDetailsEvent, TodoDetailsState> {
  final GetTodoDetailsUseCase getTodoDetailsUseCase;

  TodoDetailsBloc({required this.getTodoDetailsUseCase})
      : super(TodoDetailsState.initial()) {
    on<TodoDetailsRequested>(_onRequested);
  }

  Future<void> _onRequested(
    TodoDetailsRequested event,
    Emitter<TodoDetailsState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    try {
      final todo = await getTodoDetailsUseCase(event.id);
      emit(state.copyWith(isLoading: false, todo: todo));
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      ));
    }
  }
}
