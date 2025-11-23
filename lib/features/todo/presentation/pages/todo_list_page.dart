import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/todo_list/todo_list_bloc.dart';
import '../bloc/todo_list/todo_list_event.dart';
import '../bloc/todo_list/todo_list_state.dart';
import '../bloc/todo_details/todo_details_bloc.dart';
import '../pages/todo_details_page.dart';
import '../../domain/repositories/todo_repository.dart';
import '../../domain/usecases/get_todo_details_usecase.dart';
import '../../domain/entities/todo_entity.dart';

class TodoListPage extends StatefulWidget {
  const TodoListPage({super.key});

  @override
  State<TodoListPage> createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();

    // First load
    context.read<TodoListBloc>().add(const TodoListFetched());

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;

    // When close to bottom -> load more
    if (currentScroll >= maxScroll * 0.8) {
      context.read<TodoListBloc>().add(const TodoListLoadMore());
    }
  }

  Future<void> _onRefresh() async {
    context.read<TodoListBloc>().add(const TodoListFetched());
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _openDetails(TodoEntity todo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          // Get the usecase from the tree or recreate DI here
          // Simpler: pass it from main via a top-level BlocProvider?
          // But we already have repository in context.

          final todoRepository = context.read<TodoRepository>();
          final getTodoDetailsUseCase = GetTodoDetailsUseCase(todoRepository);

          return BlocProvider<TodoDetailsBloc>(
            create:
                (_) => TodoDetailsBloc(
                  getTodoDetailsUseCase: getTodoDetailsUseCase,
                ),
            child: TodoDetailsPage(todoId: todo.id),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Todos')),
      body: BlocBuilder<TodoListBloc, TodoListState>(
        builder: (context, state) {
          if (state.isLoading && state.todos.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.errorMessage != null && state.todos.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Failed to load todos',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      state.errorMessage!,
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context.read<TodoListBloc>().add(
                          const TodoListFetched(),
                        );
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _onRefresh,
            child: ListView.separated(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: state.todos.length + 1, // +1 for bottom loader
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                if (index == state.todos.length) {
                  // bottom loader / no-more label
                  if (state.isLoadingMore) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (!state.hasMore) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'No more todos',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }

                final todo = state.todos[index];
                return ListTile(
                  title: Text(todo.title),
                  subtitle: Text('ID: ${todo.id}  •  User: ${todo.userId}'),
                  trailing: Icon(
                    todo.completed ? Icons.check_circle : Icons.circle_outlined,
                  ),
                  onTap: () => _openDetails(todo),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
