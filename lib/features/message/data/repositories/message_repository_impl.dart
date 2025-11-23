import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/message_repository.dart';
import '../datasources/message_remote_datasource.dart';

class MessageRepositoryImpl implements MessageRepository {
  final MessageRemoteDataSource remoteDataSource;

  MessageRepositoryImpl({required this.remoteDataSource});

  @override
  Future<MessageEntity> fetchMessage() async {
    try {
      final model = await remoteDataSource.getMessage();
      return model;
    } catch (e) {
      // Optionally wrap exceptions to domain-specific ones
      rethrow;
    }
  }
}
