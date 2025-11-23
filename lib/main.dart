import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;

// MESSAGE FEATURE
import 'features/message/data/datasources/message_remote_datasource.dart';
import 'features/message/data/repositories/message_repository_impl.dart';
import 'features/message/domain/usecases/get_message_usecase.dart';
import 'features/message/presentation/bloc/message_bloc.dart';

// TODO FEATURE
import 'features/todo/data/datasources/todo_remote_data_source.dart';
import 'features/todo/data/repositories/todo_repository_impl.dart';
import 'features/todo/domain/repositories/todo_repository.dart';
import 'features/todo/domain/usecases/get_todos_usecase.dart';
import 'features/todo/presentation/bloc/todo_list/todo_list_bloc.dart';
import 'features/todo/presentation/pages/todo_list_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 1) Common HTTP client
    final client = http.Client();
    
    // 2) MESSAGE DI
    final messageRemoteDataSource = MessageRemoteDataSourceImpl(client: client);
    final messageRepository =
        MessageRepositoryImpl(remoteDataSource: messageRemoteDataSource);
    final getMessageUsecase = GetMessageUseCase(messageRepository);

    // 3) TODO DI
    final todoRemoteDataSource = TodoRemoteDataSourceImpl(client: client);
    final TodoRepository todoRepository =
        TodoRepositoryImpl(remoteDataSource: todoRemoteDataSource);
    final getTodosUseCase = GetTodosUseCase(todoRepository);

    return MultiRepositoryProvider(
      providers: [
        // Message repo
        RepositoryProvider.value(value: messageRepository),

        // Todo repo (if you want to access it via context.read<TodoRepository>())
        RepositoryProvider<TodoRepository>.value(value: todoRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          // MESSAGE BLoC
          BlocProvider<MessageBloc>(
            create: (_) => MessageBloc(getMessageUseCase: getMessageUsecase),
          ),

          // TODO LIST BLoC (global, used in TodoListPage)
          BlocProvider<TodoListBloc>(
            create: (_) => TodoListBloc(getTodosUseCase: getTodosUseCase),
          ),
        ],
        child: MaterialApp(
          title: 'Clean Arch BLoC Demo',
          debugShowCheckedModeBanner: false,
          home: const TodoListPage(),
        ),
      ),
    );
  }
}
