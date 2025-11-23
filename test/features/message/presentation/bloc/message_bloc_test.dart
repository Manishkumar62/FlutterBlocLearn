import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firstassignbloc/features/message/presentation/bloc/message_bloc.dart';
import 'package:firstassignbloc/features/message/presentation/bloc/message_event.dart';
import 'package:firstassignbloc/features/message/presentation/bloc/message_state.dart';
import 'package:firstassignbloc/features/message/domain/usecases/get_message_usecase.dart';
import 'package:firstassignbloc/features/message/domain/entities/message_entity.dart';

class MockGetMessageUseCase extends Mock implements GetMessageUseCase {}

void main() {
  late MessageBloc bloc;
  late MockGetMessageUseCase mockGetMessageUseCase;

  setUp(() {
    mockGetMessageUseCase = MockGetMessageUseCase();
    bloc = MessageBloc(getMessageUseCase: mockGetMessageUseCase);
  });

  tearDown(() {
    bloc.close();
  });

  test('initial state should be MessageInitial', () {
    expect(bloc.state, equals(MessageInitial()));
  });

  blocTest<MessageBloc, MessageState>(
    'emits [MessageLoading, MessageLoaded] when usecase returns data',
    build: () {
      when(() => mockGetMessageUseCase()).thenAnswer(
          (_) async => MessageEntity('delectus aut autem'));
      return bloc;
    },
    act: (bloc) => bloc.add(LoadMessageEvent()),
    expect: () => [
      MessageLoading(),
      MessageLoaded('delectus aut autem'),
    ],
    verify: (_) {
      verify(() => mockGetMessageUseCase()).called(1);
    },
  );

  blocTest<MessageBloc, MessageState>(
    'emits [MessageLoading, MessageError] when usecase throws',
    build: () {
      when(() => mockGetMessageUseCase()).thenThrow(Exception('failed'));
      return bloc;
    },
    act: (bloc) => bloc.add(LoadMessageEvent()),
    expect: () => [
      MessageLoading(),
      isA<MessageError>(),
    ],
    verify: (_) {
      verify(() => mockGetMessageUseCase()).called(1);
    },
  );
}
