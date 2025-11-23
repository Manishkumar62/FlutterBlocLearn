import 'package:equatable/equatable.dart';

class TodoDetailsEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class TodoDetailsRequested extends TodoDetailsEvent {
  final int id;

  TodoDetailsRequested(this.id);

  @override
  List<Object?> get props => [id];
}
