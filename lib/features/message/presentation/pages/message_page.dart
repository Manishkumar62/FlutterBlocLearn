import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/message_bloc.dart';
import '../bloc/message_event.dart';
import '../bloc/message_state.dart';

class MessagePage extends StatelessWidget {
  const MessagePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Clean Architecture - BLoC Demo")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // The Display Area
            BlocBuilder<MessageBloc, MessageState>(
              builder: (context, state) {
                if (state is MessageInitial) {
                  return const Text("Press the button below");
                } else if (state is MessageLoading) {
                  return const CircularProgressIndicator();
                } else if (state is MessageLoaded) {
                  return Text(
                    state.message,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  );
                } else if (state is MessageError) {
                  print('Error: ${state.error}');
                  return Text('Error: ${state.error}');
                }
                return const SizedBox();
              },
            ),
            
            const SizedBox(height: 50),

            // The Button
            ElevatedButton(
              onPressed: () {
                // Trigger the BLoC event
                context.read<MessageBloc>().add(LoadMessageEvent());
              },
              child: const Text("Load Message"),
            ),
          ],
        ),
      ),
    );
  }
}