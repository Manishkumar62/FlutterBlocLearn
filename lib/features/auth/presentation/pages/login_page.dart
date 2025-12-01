import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/login_bloc.dart';
import '../bloc/login_event.dart';
import '../bloc/login_state.dart';
import '../../../todo/presentation/pages/todo_list_page.dart';
import '../../../todo/domain/usecases/get_todos_usecase.dart'; // if you need to recreate

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // email: john@mail.com
  // password: changeme
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onEmailChanged() {
    context.read<LoginBloc>().add(LoginEmailChanged(_emailController.text));
  }

  void _onPasswordChanged() {
    context.read<LoginBloc>().add(LoginPasswordChanged(_passwordController.text));
  }

  void _onSubmit() {
    context.read<LoginBloc>().add(LoginSubmitted());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: BlocListener<LoginBloc, LoginState>(
        listener: (context, state) {
          if (state.status == LoginStatus.success) {
            // Navigate to TodoListPage (replace)
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const TodoListPage()),
            );
          } else if (state.status == LoginStatus.failure) {
            final msg = state.errorMessage ?? 'Login failed';
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(msg)));
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _emailController,
                onChanged: (_) => _onEmailChanged(),
                decoration: InputDecoration(
                  labelText: 'Email',
                  errorText: context.select((LoginBloc bloc) => bloc.state.emailError),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _passwordController,
                onChanged: (_) => _onPasswordChanged(),
                decoration: InputDecoration(
                  labelText: 'Password',
                  errorText: context.select((LoginBloc bloc) => bloc.state.passwordError),
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                obscureText: _obscure,
              ),
              const SizedBox(height: 20),
              BlocBuilder<LoginBloc, LoginState>(
                builder: (context, state) {
                  final isSubmitting = state.status == LoginStatus.submitting;
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : _onSubmit,
                      child: isSubmitting ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Login'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
