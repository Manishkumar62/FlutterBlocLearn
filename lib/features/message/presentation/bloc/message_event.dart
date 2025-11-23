import 'package:equatable/equatable.dart';

abstract class MessageEvent extends Equatable {
  const MessageEvent();

  @override
  List<Object> get props => [];
}

// The specific event triggered when the button is clicked
class LoadMessageEvent extends MessageEvent {}