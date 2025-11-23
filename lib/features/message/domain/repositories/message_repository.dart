import '../entities/message_entity.dart';

abstract class MessageRepository {
  /// Returns a MessageEntity or throws on failure
  Future<MessageEntity> fetchMessage();
}
