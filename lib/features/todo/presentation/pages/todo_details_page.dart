import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/todo_details/todo_details_bloc.dart';
import '../bloc/todo_details/todo_details_event.dart';
import '../bloc/todo_details/todo_details_state.dart';

class TodoDetailsPage extends StatefulWidget {
  final int todoId;

  const TodoDetailsPage({
    super.key,
    required this.todoId,
  });

  @override
  State<TodoDetailsPage> createState() => _TodoDetailsPageState();
}

class _TodoDetailsPageState extends State<TodoDetailsPage> {
  @override
  void initState() {
    super.initState();
    context.read<TodoDetailsBloc>().add(TodoDetailsRequested(widget.todoId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Todo #${widget.todoId}'),
      ),
      body: BlocBuilder<TodoDetailsBloc, TodoDetailsState>(
        builder: (context, state) {
          if (state.isLoading && state.todo == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state.errorMessage != null && state.todo == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Failed to load todo details'),
                    const SizedBox(height: 8),
                    Text(
                      state.errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        context
                            .read<TodoDetailsBloc>()
                            .add(TodoDetailsRequested(widget.todoId));
                      },
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final todo = state.todo!;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      todo.title,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('ID: '),
                        Text(todo.id.toString()),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('User ID: '),
                        Text(todo.userId.toString()),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Status: '),
                        Chip(
                          label: Text(
                            todo.completed ? 'Completed' : 'Pending',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
