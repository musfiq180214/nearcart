import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nearcart/presentation/app_shell.dart';
import 'package:nearcart/presentation/screens/login/login_screen.dart';
import '../../core/providers.dart';

/// Sits at the root of the widget tree and switches between
/// the authenticated shell and the login screen.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(firebaseAuthUserProvider);

    return authAsync.when(
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF121212),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🛒', style: TextStyle(fontSize: 56)),
              SizedBox(height: 16),
              CircularProgressIndicator(strokeWidth: 2),
            ],
          ),
        ),
      ),
      error: (_, __) => const LoginScreen(),
      data: (user) => user != null ? const AppShell() : const LoginScreen(),
    );
  }
}