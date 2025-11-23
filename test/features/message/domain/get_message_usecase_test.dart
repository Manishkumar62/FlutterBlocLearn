import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firstassignbloc/features/message/domain/usecases/get_message_usecase.dart';
import 'package:firstassignbloc/features/message/domain/entities/message_entity.dart';
import 'package:firstassignbloc/features/message/domain/repositories/message_repository.dart';

// Replace with your package name in imports above.

class MockMessageRepository extends Mock implements MessageRepository {}

void main() {
  late GetMessageUseCase usecase;
  late MockMessageRepository mockRepository;

  setUp(() {
    mockRepository = MockMessageRepository();
    usecase = GetMessageUseCase(mockRepository);
  });

  test('should return MessageEntity from repository', () async {
    // arrange
    final tMessage = MessageEntity('delectus aut autem');
    when(() => mockRepository.fetchMessage()).thenAnswer((_) async => tMessage);

    // act
    final result = await usecase();

    // assert
    expect(result, isA<MessageEntity>());
    expect(result.text, 'delectus aut autem');
    verify(() => mockRepository.fetchMessage()).called(1);
  });
}
