import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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

// AUTH FEATURE
import 'features/auth/data/datasources/auth_remote_datasource.dart';
import 'features/auth/data/datasources/auth_refresh_datasource.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/usecases/login_usecase.dart';
import 'features/auth/domain/usecases/refresh_token_usecase.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/bloc/auth_state.dart';
import 'features/auth/presentation/bloc/login_bloc.dart';
import 'features/auth/presentation/pages/login_page.dart';

// CORE
import 'core/secure_storage/token_storage.dart';
import 'core/network/auth_http_client.dart';
import 'core/network/jwt_utils.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1) COMMON DEPENDENCIES
  final client = http.Client();
  final secureStorage = const FlutterSecureStorage();
  final tokenStorage = TokenStorage(secureStorage: secureStorage);

  // 2) MESSAGE DI
  final messageRemoteDataSource = MessageRemoteDataSourceImpl(client: client);
  final messageRepository = MessageRepositoryImpl(
    remoteDataSource: messageRemoteDataSource,
  );
  final getMessageUsecase = GetMessageUseCase(messageRepository);

  // 4) AUTH DI
  final authRemote = AuthRemoteDataSourceImpl(client: client);
  final authRefreshRemote = AuthRefreshRemoteDataSourceImpl(client: client);
  final authRepository = AuthRepositoryImpl(
    remoteDataSource: authRemote,
    refreshRemoteDataSource: authRefreshRemote,
  );
  final loginUseCase = LoginUseCase(authRepository);
  final refreshUseCase = RefreshTokenUseCase(authRepository);

  // AuthBloc (global)
  final authBloc = AuthBloc(
    tokenStorage: tokenStorage,
    refreshUseCase: refreshUseCase,
  );
  // start auth restore
  authBloc.add(AuthStarted());

  // Provide an auth-aware HTTP client to other features
  final authHttpClient = AuthHttpClient(
    inner: client,
    tokenStorage: tokenStorage,
    authBloc: authBloc,
  );

  // 3) Todo DI with authHttpClient
  final todoRemoteDataSource = TodoRemoteDataSourceImpl(client: authHttpClient);
  final TodoRepository todoRepository = TodoRepositoryImpl(
    remoteDataSource: todoRemoteDataSource,
  );
  final getTodosUseCase = GetTodosUseCase(todoRepository);

  runApp(
    MultiRepositoryProvider(
      providers: [
        // Auth repo
        RepositoryProvider.value(value: authRepository),
        // Message repo
        RepositoryProvider.value(value: messageRepository),
        // Todo repo
        RepositoryProvider<TodoRepository>.value(value: todoRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),

          // MESSAGE BLoC
          BlocProvider<MessageBloc>(
            create: (_) => MessageBloc(getMessageUseCase: getMessageUsecase),
          ),

          // TODO LIST BLoC (global, used in TodoListPage)
          BlocProvider<TodoListBloc>(
            create: (_) => TodoListBloc(getTodosUseCase: getTodosUseCase),
          ),

          // LOGIN BLoC
          BlocProvider<LoginBloc>(
            create: (_) => LoginBloc(
              loginUseCase: loginUseCase,
              tokenStorage: tokenStorage,
              authBloc: authBloc,
            ),
          ),
        ],
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use BlocListener without passing a separate bloc instance.
    // It will automatically find the AuthBloc provided above in the tree.
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        final nav = navigatorKey.currentState;
        if (nav == null) {
          // Defensive log if something odd happens
          print('Navigator not ready yet.');
          return;
        }

        if (state.status == AuthStatus.unauthenticated) {
          // Replace the whole stack and go to LoginPage
          nav.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const LoginPage()),
            (route) => false,
          );
        } else if (state.status == AuthStatus.authenticated) {
          // Replace stack and go to TodoListPage
          nav.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const TodoListPage()),
            (route) => false,
          );
        }
      },
      child: MaterialApp(
        navigatorKey: navigatorKey, // attach the key here
        debugShowCheckedModeBanner: false,
        title: 'Clean Arch BLoC Demo',
        home: const LoginPage(),
      ),
    );
  }
}

