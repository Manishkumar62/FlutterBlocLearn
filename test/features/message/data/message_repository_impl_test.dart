import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firstassignbloc/features/message/data/datasources/message_remote_datasource.dart';
import 'package:firstassignbloc/features/message/data/repositories/message_repository_impl.dart';
import 'package:firstassignbloc/features/message/data/models/message_model.dart';

class MockRemoteDataSource extends Mock implements MessageRemoteDataSource {}

void main() {
  late MessageRepositoryImpl repository;
  late MockRemoteDataSource mockRemote;

  setUp(() {
    mockRemote = MockRemoteDataSource();
    repository = MessageRepositoryImpl(remoteDataSource: mockRemote);
  });

  test('should return MessageModel when remote datasource succeeds', () async {
    // arrange
    final tModel = MessageModel('delectus aut autem');
    when(() => mockRemote.getMessage()).thenAnswer((_) async => tModel);

    // act
    final result = await repository.fetchMessage();

    // assert
    expect(result, isA<MessageModel>());
    expect(result.text, 'delectus aut autem');
    verify(() => mockRemote.getMessage()).called(1);
  });
}
