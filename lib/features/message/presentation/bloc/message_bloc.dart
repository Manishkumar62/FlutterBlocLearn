import 'package:flutter_bloc/flutter_bloc.dart';
import 'message_event.dart';
import 'message_state.dart';
import '../../domain/usecases/get_message_usecase.dart';

class MessageBloc extends Bloc<MessageEvent, MessageState> {
  final GetMessageUseCase getMessageUseCase;

  MessageBloc({required this.getMessageUseCase}) : super(MessageInitial()) {
    on<LoadMessageEvent>(_onLoadMessage);
  }

  Future<void> _onLoadMessage(
    LoadMessageEvent event,
    Emitter<MessageState> emit,
  ) async {
    emit(MessageLoading());
    try {
      final messageEntity = await getMessageUseCase();
      emit(MessageLoaded(messageEntity.text));
    } catch (e) {
      emit(MessageError(e.toString()));
    }
  }
}
