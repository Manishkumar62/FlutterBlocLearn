import '../entities/message_entity.dart';
import '../repositories/message_repository.dart';

class GetMessageUseCase {
  final MessageRepository repository;

  GetMessageUseCase(this.repository);

  Future<MessageEntity> call() async {
    return await repository.fetchMessage();
  }
}
