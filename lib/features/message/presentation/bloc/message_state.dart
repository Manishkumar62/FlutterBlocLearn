import 'package:equatable/equatable.dart';

abstract class MessageState extends Equatable {
  const MessageState();
  
  @override
  List<Object> get props => [];
}

// 1. Initial state (before anything happens)
class MessageInitial extends MessageState {}

// 2. Loading state (during the 2-second wait)
class MessageLoading extends MessageState {}

// 3. Loaded state (holds the data)
class MessageLoaded extends MessageState {
  final String message;

  const MessageLoaded(this.message);

  @override
  List<Object> get props => [message];
}

class MessageError extends MessageState {
  final String error;
  const MessageError(this.error);

  @override
  List<Object> get props => [error];
}